from __future__ import print_function

import sys
import ft_scanner

''' ECE 554 Project SP 2020
    Ilhan Bok, Ben Holzem, Tristan Wentworth
    FindTune compiler parser

    Find all documentation on the project GitHub. If
    something is unclear, try reading the relevant section on the spec,
    looking carefully at parser/compiler output, or messaging #compiler
    on Slack '''

# Ensure python is up to date (python3 is preferred)
try:
    assert sys.version_info >= (3, 0)
except AssertionError:
    print('Please use `python3` with this compiler')
    sys.exit(1)

#==============#
# User Options #
#==============#

# Do we want parens after FPGA directives
haveParens = False

#===============#
# ASTNode Class #
#===============#

''' Parser Object '''


class ParseData:
    def __init__(self, ast, scanned):
        self.ast = ast
        self.scanned = scanned


''' n-ary AST Node '''


class ASTNode:
    def __init__(self, item, children):
        self.children = children
        self.item = item
        self.kind = item[1]
        self.value = item[0]


''' AST Parser '''


class TokenHelper:
    def __init__(self, scanned):
        if scanned == []:
            self.curr = None
            self.rest = []
            self.all = []
            self.kind = None
            self.value = None
        else:
            self.curr = scanned[0]
            self.rest = scanned[1:]
            self.all = scanned
            self.kind = self.curr[1]
            self.value = self.curr[0]


#========#
# Parser #
#========#

# Stack to store parser errors
errStack = []

''' Parser setup '''

# Function to pass to optimizer


def createParse(f):
    scanned = ft_scanner.createScan(f)
    if scanned == []:
        print('File is empty')
        return None
    parsedASTObj = parseExpr(scanned, [])
    if parsedASTObj is None or not parsedASTObj.scanned == []:
        print('Could not parse input file')
        return None
    return parsedASTObj.ast


''' Pretty print error messages '''


def printError(kind, problem, solution, cause):
    errStack.append(' ParserError: %s\n  :( %s\n  :) %s \n Token (%s, %s) (row: %s, col: %s)\n'
                    % (kind, problem, solution, cause[0], cause[1], cause[2], cause[3]))


''' Pretty print warning messages '''


def printWarn(msg):
    errStack.append('ParserWarning: %s\n' % msg)


''' Parser construction '''


def parseToken(token, scanned):
    item = TokenHelper(scanned)
    if item.kind == token:
        return item.rest
    else:
        return None


def parseSeq(t_list, scanned):
    res = scanned
    for token in t_list:
        res = parseToken(token, res)
        if res is None:
            return None
    return TokenHelper(res)


''' Parses high level expressions '''


def parseExpr(scanned, lvars):
    res_expr1 = parseIf(scanned, lvars)
    if res_expr1 is None:
        res_expr1 = parseFor(scanned, lvars)
        if res_expr1 is None:
            res_expr1 = parseOctaves(scanned, lvars)
            if res_expr1 is None:
                res_expr1 = parseWait(scanned, lvars)
                if res_expr1 is None:
                    res_expr1 = parseFPGA(scanned, lvars)
                    if res_expr1 is None:
                        return None
    # Ignoring syntax, simply try checking if next line is a valid
    # expression, given there is something to parse. If not, then rollback.
    if res_expr1.scanned == []:
        return res_expr1
    else:
        token_expr2 = TokenHelper(res_expr1.scanned)
        res_expr2 = parseExpr(token_expr2.all, lvars)
        if res_expr2 is None:
            return res_expr1
        else:
            return ParseData(ASTNode(('ASTexpr', 'ASTexpr'),
                             [res_expr1.ast, res_expr2.ast]),
                             res_expr2.scanned)


''' Parses if or if/else statements '''


def parseIf(scanned, lvars):
    # Parse if condition
    token_bool = parseSeq(['if', 'lparen'], scanned)
    if token_bool is None:
        return None
    res_bool = parseBool(token_bool.all, lvars)
    if res_bool is None:
        printError('parseIf', 'Could not evaluate guard to bool.',
                   'Check the guard type or formula.',
                   token_bool.curr)
        return None
    # Parse if expression
    token_expr1 = parseSeq(['rparen', 'lbrace'], res_bool.scanned)
    if token_expr1 is None:
        return None
    res_expr1 = parseExpr(token_expr1.all, lvars)
    if res_expr1 is None:
        printError('parseIf', 'Could not parse if-case expr.',
                   'Is it formatted properly?', token_expr1.curr)
        return None
    # Decide type (if or ifelse)
    token_else = parseSeq(['rbrace'], res_expr1.scanned)
    if token_else is None:
        return None
    if token_else.kind == 'else':
        # Parse else expression
        token_expr2 = parseSeq(['lbrace'], token_else.rest)
        if token_expr2 is None:
            return None
        res_expr2 = parseExpr(token_expr2.all, lvars)
        if res_expr2 is None:
            printError('parseIf', 'Could not parse else-case expr.',
                       'Is it formatted properly?',
                       token_expr2.curr)
            return None
        token_rbrace = parseSeq(['rbrace'], res_expr2.scanned)
        if token_rbrace is None:
            return None
        return ParseData(ASTNode(('ASTifelse', 'ASTifelse'),
                         [res_bool.ast, res_expr1.ast, res_expr2.ast]),
                         token_rbrace.all)
    else:
        return ParseData(ASTNode(('ASTif', 'ASTif'),
                         [res_bool.ast, res_expr1.ast]),
                         token_else.all)


''' Parses for loops '''


def parseFor(scanned, lvars):
    token_var = parseSeq(['for'], scanned)
    if token_var is None:
        return None
    if token_var.kind == 'var':
        # It is possible the variable is already defined
        # If so, it will be shadowed
        if token_var.value in lvars:
            printWarn('Variable ' + token_var.value +
                      ' is already defined in an outer scope [info: '
                      + str(token_var.curr) + ']')
        lvars.append(token_var.value)
        # Parse first element of range
        token_math1 = parseSeq(['in', 'lparen'], token_var.rest)
        if token_math1 is None:
            return None
        res_math1 = parseMath(token_math1.all, lvars)
        if res_math1 is None:
            printError('parseFor', 'Could not parse lower for-loop bound.',
                       'Try double checking the number.', token_math1.curr)
            return None
        # Parse second element of range
        token_math2 = parseSeq(['comma'], res_math1.scanned)
        if token_math2 is None:
            return None
        res_math2 = parseMath(token_math2.all, lvars)
        if res_math2 is None:
            printError('parseFor', 'Could not parse upper for-loop bound.',
                       'Try double checking the number.',
                       token_math2.curr)
            return None
        # Parse main expressions
        token_expr = parseSeq(['rparen', 'lbrace'], res_math2.scanned)
        if token_expr is None:
            return None
        res_expr = parseExpr(token_expr.all, lvars)
        if res_expr is None:
            printError('parseFor', 'Could not parse for loop body.',
                       'Is it formatted properly?', token_expr.curr)
            return None
        token_rbrace = parseSeq(['rbrace'], res_expr.scanned)
        if token_rbrace is None:
            return None
        # Remove local var from scope
        lvars.pop()
        return ParseData(ASTNode(('ASTfor', 'ASTfor'),
                         [ASTNode(token_var.curr, []), res_math1.ast,
                          res_math2.ast, res_expr.ast]), token_rbrace.all)
    else:
        printError('parseFor', 'Could not parse for loop counter variable.',
                   'Is the variable name correct?', token_var.curr)


''' Parses FPGA directives '''


def parseFPGA(scanned, lvars):
    token_action = parseSeq(['fpgadir'], scanned)
    if token_action is None or (not token_action.kind == 'action'):
        return None
    # Also require parentheses at end if directed
    if haveParens:
        token_action = parseSeq(['lparen', 'rparen'], token_action.rest)
        if token_action is None:
            return None
        unparsed = token_action.all
    else:
        unparsed = token_action.rest
    return ParseData(ASTNode(token_action.curr, []), unparsed)


''' Parse the setOctaves FPGA directive '''


def parseOctaves(scanned, lvars):
    token_bits = parseSeq(['fpgadir', 'octaves', 'lparen'], scanned)
    if token_bits is None:
        return None
    if token_bits.kind == 'bits':
        token_rparen = parseSeq(['rparen'], token_bits.rest)
        if token_rparen is None:
            return None
        return ParseData(ASTNode(('ASToctaves', 'ASToctaves'),
                                 [ASTNode(token_bits.curr, [])]),
                         token_rparen.all)
    else:
        printError('parseOctaves', 'Could not parse setOctave bits.',
                   'Bitstrings must be surrounded by "<" and ">"',
                   token_bits.curr)


''' Parse the wait FPGA directive '''


def parseWait(scanned, lvars):
    token_wait = parseSeq(['fpgadir', 'wait', 'lparen'], scanned)
    if token_wait is None:
        return None
    res_wait = parseMath(token_wait.all, lvars)
    if res_wait is None:
        printError('parseWait', 'Could not parse fpga.wait parameter.',
                   'Try double checking the number.', token_wait.curr)
        return None
    token_rparen = parseSeq(['rparen'], res_wait.scanned)
    if token_rparen is None:
        return None
    return ParseData(ASTNode(('ASTwait', 'ASTwait'),
                     [res_wait.ast]), token_rparen.all)


''' Parse numbers and bitstrings '''


def parseMath(scanned, lvars):
    token_math = TokenHelper(scanned)
    if token_math.kind == 'int' or token_math.kind == 'bits':
        return ParseData(ASTNode(token_math.curr, []), token_math.rest)
    if token_math.kind == 'var' and token_math.value in lvars:
        return ParseData(ASTNode(token_math.curr, []), token_math.rest)
    else:
        printError('parseMath', 'Variable not in scope.',
                   'Are you outside the for loop it was declared in?',
                   token_math.curr)


def parseBool(scanned, lvars):
    token_stmt = TokenHelper(scanned)
    equalType = None
    # Parse "not" statement
    if token_stmt.kind == 'not':
        res_bool1 = parseBool(token_stmt.rest, lvars)
        if res_bool1 is None:
            printError('parseBool', 'Could not apply "not" to statement.',
                       'Are you taking the "not" of a non-boolean?',
                       token_stmt.curr)
            return None
        res_bool1.ast = ASTNode(('ASTnot', 'ASTnot'), [res_bool1.ast])
        return ParseData(res_bool1.ast, res_bool1.scanned)
    # Parse parenthesized statement
    elif token_stmt.kind == 'lparen':
        scanned = token_stmt.rest
        token_stmt = TokenHelper(token_stmt.rest)
        res_bool1 = parseBool(token_stmt.all, lvars)
        check_rparen = TokenHelper(res_bool1.scanned)
        if not check_rparen.kind == 'rparen':
            printError('parseBool', 'No matching right paren found.',
                       'Check for mismatched parens.', check_rparen.curr)
            return None
        equalType = "bool"
        token_stmt = TokenHelper(check_rparen.rest)
    # Parse first argument as int or var
    else:
        res_bool1 = parseMath(token_stmt.all, lvars)
        equalType = "math"
        token_stmt = TokenHelper(res_bool1.scanned)
    # Check that the first argument was parsed
    if res_bool1 is None or equalType is None:
        printError('parseBool', 'Could not parse statement to a boolean.',
                   'Is the final type of the statement a boolean?',
                   token_stmt.curr)
        return None
    # Parse the second argument. If the end is reached, return what
    # we have
    token_bool2 = parseSeq(['equality'], token_stmt.all)
    if token_bool2 is None:
        if equalType == "math":
            printError('parseBool', '"==" not found for math expression.',
                       'Is the operator present?', token_stmt.curr)
            return None
        token_bool2 = parseSeq(['and'], token_stmt.all)
        if token_bool2 is None:
            token_bool2 = parseSeq(['or'], token_stmt.all)
            if token_bool2 is None:
                return ParseData(res_bool1.ast, check_rparen.rest)
            bool_type = 'ASTor'
        else:
            bool_type = 'ASTand'
        res_bool2 = parseBool(token_bool2.all, lvars)
    else:
        if equalType == "bool":
            bool_type = 'ASTequalbool'
            res_bool2 = parseBool(token_bool2.all, lvars)
        elif equalType == "math":
            bool_type = 'ASTequalmath'
            res_bool2 = parseMath(token_bool2.all, lvars)
    if res_bool2 is None:
        printError('parseBool', 'Could not parse second bool.',
                   'Are types correct for the second bool?', token_bool2.curr)
        return None
    return ParseData(ASTNode((bool_type, bool_type),
                             [res_bool1.ast, res_bool2.ast]),
                     res_bool2.scanned)


# Print method for debugging
# Feel free to use this throughout the code for testing
# aol = AST Object List
def printAST(aol, level, h):
    for i in range(level, 0, -1):
        if i == 1:
            curr = '|---'
            h.write(curr)
            print(curr, end='')
        else:
            curr = '|   '
            h.write(curr)
            print(curr, end='')
    curr = aol[-1].item
    h.write(str(curr) + '\n')
    print(curr)
    for child in aol[-1].children:
        aol.append(child)
        printAST(aol, level + 1, h)


def printFailed():
    print()
    print(':: Errors and Warnings ::')
    print()
    print(' Work your way down. The first message is usually most helpful')
    print()
    for msg in errStack:
        print(msg)
    print(' Still need help? Message #compiler on Slack')
    print()


def test(fname):
    printRes(fname, '', ['tok.txt', 'ast.txt'])


def printRes(fname, prefix, fnames):

    failed = False

    print(':: Scanning tokens... ::')

    scanned = ft_scanner.createScan(fname)

    print(':: Scan successful! ::')
    print()

    t = open(prefix + fnames[0], 'w')
    for token in scanned:
        print(token)
        t.write(str(token) + '\n')
    t.close()

    if scanned == []:
        print(':: No code to parse ::')
        sys.exit(0)

    print()
    print(':: Tokenized output written to ./' + prefix + fnames[0] + ' ::')
    print()

    print(':: Parsing AST... ::')

    parsedASTObj = parseExpr(scanned, [])

    if parsedASTObj is None:
        printFailed()
    else:
        if parsedASTObj.scanned == []:
            print(':: Parse Successful! ::')
        else:
            failed = True
            print(':: Parse Failed Midway... ::')
            printFailed()
            print(' This is what was left unparsed:')
            print()
            print(parsedASTObj.scanned)
            print()
            print(' This is what I did parse:')
        print()
        h = open(prefix + fnames[1], 'w')
        printAST([parsedASTObj.ast], 0, h)
        h.close()
        print()
        print(':: AST written to ./' + prefix + fnames[1] + ' ::')
        print()
        # Stop the compiler if the parse failed midway
        if failed:
            sys.exit(1)
