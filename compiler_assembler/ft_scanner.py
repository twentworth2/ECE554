import sys
import re

''' ECE 554 Project SP 2020
    Ilhan Bok, Ben Holzem, Tristan Wentworth
    FindTune compiler scanner

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

#========#
# Tokens #
#========#

# Bookkeeping
START = r'^'

# Scanner tokens
AND = (r'&&', 'and')
OR = (r'\|\|', 'or')
NOT = (r'!', 'not')
IF = (r'if', 'if')
ELSE = (r'else', 'else')
FOR = (r'for', 'for')
IN = (r'in', 'in')
COMMA = (r',', 'comma')
LPAREN = (r'\(', 'lparen')
RPAREN = (r'\)', 'rparen')
LBRACE = (r'\{', 'lbrace')
RBRACE = (r'\}', 'rbrace')
DIR = (r'fpga\.', 'fpgadir')
EQUAL = (r'==', 'equality')
SEMI = (r';', 'semicolon')
WHITESPACE = (r'[ \t\n\r]+', 'whitespace')

# Variables and integers
INT = (r'[0-9]+', 'int')
BITS = (r'<[01]+>', 'bits')
VAR = (r'[a-zA-Z_][a-zA-Z0-9_]*', 'var')

# FPGA directive tokens
EN_SAMPLE = (r'enableSample', 'action')
DI_SAMPLE = (r'disableSample', 'action')
SH_STATE = (r'displayState', 'action')
EN_GRAPHICS = (r'enableGraphics', 'action')
DI_GRAPHICS = (r'disableGraphics', 'action')
FREEZE = (r'freeze', 'action')
UNFREEZE = (r'unfreeze', 'action')
EN_ATUNE = (r'enableAutotune', 'action')
DI_ATUNE = (r'disableAutotune', 'action')
SET_OCT = (r'setOctaves', 'octaves')
WAIT = (r'wait', 'wait')

# Single and multi-line comments
COMMENT = (r'#.*', 'comment')
MLSTART = (r':\(', 'mlstart')
MLEND = (r':\)', 'mlend')

tuple_arr = [AND, OR, NOT, IF, ELSE, FOR, IN, COMMA,
             LPAREN, RPAREN, LBRACE, RBRACE, DIR,
             EQUAL, SEMI, WHITESPACE, INT, BITS, EN_SAMPLE, DI_SAMPLE,
             SH_STATE, EN_GRAPHICS, DI_GRAPHICS, FREEZE, UNFREEZE,
             EN_ATUNE, DI_ATUNE, SET_OCT, WAIT, VAR, COMMENT, MLSTART, MLEND]

#=========#
# Scanner #
#=========#


def printError(msg, row, col, line):
    sys.exit('ScannerError (%s), line: %s col: %s \n %s \n ^'
             % (msg, row, col, line))


''' Scans through the input in the given file, token by token '''


def createScan(fname):
    # Create variable array
    tokens = []

    # Do line by line scanning
    row = 0

    # Pause recording if inside multiline comment
    paused = False

    f = open(fname)

    for line in f:
        # Increment line number in case of error
        row += 1
        col = 1
        while (not line == ''):
            # Assume no match (parse error)
            matched = False
            # Try every regexp in the list
            for tup in tuple_arr:
                reg_new = START + tup[0]
                match = re.match(reg_new, line)
                # On match, add to token list and remove from string
                if (match is not None):
                    hit = match.group(0)
                    # Start ignoring if multiline comment
                    if (tup[1] == 'mlstart'):
                        paused = True
                    if (hit == 'true' or hit == 'false'):
                        printError('boolean literals not allowed', str(row),
                                   str(col), line)
                    if (not tup[1] in ['whitespace', 'comment', 'semicolon']
                            and not paused):
                        tokens.append((hit, tup[1], row, col))
                    # Stop ignoring (end of multiline comment)
                    if (tup[1] == 'mlend'):
                        if paused:
                            paused = False
                        else:
                            printError('no multiline comment to end',
                                       str(row), str(col), line)
                    line = line[len(hit):]
                    col += len(hit)
                    matched = True
                    break
            if (not matched):
                printError('could not identify symbol',
                           str(row), str(col), line)

    f.close()

    return tokens


''' Generic test method for scanner, running the scanner on a file '''


def test(fname):
    print(createScan(fname))
