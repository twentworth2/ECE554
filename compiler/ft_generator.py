
import re
import sys

''' ECE 554 Project SP 2020
    Ilhan Bok, Ben Holzem, Tristan Wentworth
    FindTune compiler generator
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


def checkInst(inst):
    instDict = {
        'ASTfor': 'for',
        'ASTif': 'if',
        'ASTifelse': 'ifelse',
        'ASToctaves': 'octaves',
        'ASTexpr': 'expr',
        'ASTequalmath': 'eqmath',
        'ASTequalbool': 'eqbool',
        'ASTnot': 'not',
        'ASTor': 'or',
        'ASTand': 'and',
        'ASTwait': 'wait'
    }
    return instDict[inst]


def checkPart(part):
    a = ''
    a = re.findall("[a-zA-Z0-9,<>]", part)
    a = ''.join(a)
    a = a.split(",")
    info = []

    if (len(a) == 2):
        info.append('inst')
        info.append(a[0])
    else:
        info.append('other')
        info.append(a[0])
        info.append(a[1])
    return info


pc = -1  # Track current instruction
pcFile = None  # File to write first pass assembly to

#==============#
# User Options #
#==============#

comments = True  # Whether to display comments or not


# Uncomment a line to enable/disable comments
def printComment(msg):
    global pc, comments

    if comments:
        long_msg = '# PC: ' + str(pc+1) + ' :: ' + msg
        print(long_msg)
        pcFile.write(long_msg + '\n')


# Prints instruction and increments the PC
def printInc(instr):
    global pc, pcFile

    print(instr)
    pcFile.write(instr + '\n')
    pc += 1


def generate(astfname):
    printRes('pass1_assembly_code.txt', 'assembly_code.txt', astfname)


def printRes(pass1_fname, pass2_fname, astfname):

    global pcFile
    global pc

    pcFile = open(pass1_fname, 'w')
    outputFile = open(pass2_fname, 'w')
    astFile = open(astfname)

    print(':: Generating assembly... ::')
    if comments:
        print(':: Comments turned on in ft_generator.py ::')

    print()

    vardict = {}  # Var to mem dictionary
    varaddr = -1  # Track new address for var storage

    currvar = []  # Current for loop variable to manage

    branchfor = []  # For loop address to branch to, holding an old pc value
    branchif = []  # Address of if clauses
    branchelse = []  # Address of else clauses

    inst = []  # Holds instructions for nesting
    indent = [-1]  # Indent level
    data = []  # Data for closing instructions

    count = 0  # Count where in for loop
    elsecount = 0  # Count where in if/else

    startGuard = False  # Descend into guard expression
    guardStack = []  # List of guard operators
    eqstack = []  # List of eqmath parameters
    prevIndent = -1  # Track whether we are exiting boolean AST nodes
    currIf = 0  # Track if substitution number
    currElse = 0  # Track else substitution number
    boolEval = -1  # Track stored evaluated expr number
    lastBefore = None  # Record last outer instruction type
    # Detect when both AST node children are boolean ops
    doubleAnd = False
    prevDoubleAnd = False
    # Keep count of if/else branches
    ifelseIndent = -2

    for line in astFile:
        split = [x.strip() for x in line.split("|")]
        currIndent = 0
        for part in split:
            if (part == ''):
                currIndent += 1
            else:
                info = checkPart(part)
                if (info[0] == 'inst'):
                    inst.append(checkInst(info[1]))
                    indent.append(currIndent)
                    if (currIndent == ifelseIndent + 1):
                        elsecount += 1
                        if (elsecount == 3):
                            printComment('Addr to skip the else (computed on second pass) after finishing if')
                            printInc('LL R7, <%s>' % (str(currElse)))
                            currElse += 1
                            printComment('Skip the else')
                            printInc('BRE')
                            elsecount = 0
                            branchif.append(pc+1)
                    # "Recursively" handle if statement guards
                    if (inst[-1] == 'if' or inst[-1] == 'ifelse'):
                        startGuard = True
                        lastBefore = None
                        guardStack.append((inst[-1], currIndent))
                        if (inst[-1] == 'ifelse'):
                            ifelseIndent = currIndent
                    elif startGuard:
                        if currIndent < prevIndent or (len(guardStack) == 2 and guardStack[-1][0] == 'eqmath'):
                            if lastBefore is None or prevDoubleAnd:
                                ''' Sets the result of the baseline
                                register to 1's (TRUE) or 0's (FALSE) '''
                                # Do the first comparison of a clause
                                printComment('Load variable address (' + eqstack[-2][1] + ') to compare')
                                printInc('LL R5, %s' % (vardict[eqstack[-2][1]]))
                                printComment('Load value of variable')
                                printInc('LDR R2, [R5]')
                                printComment('Compare variable to clause')
                                printInc('CMP R2, %s' % (eqstack[-1][1]))
                                printComment('Set to FALSE but negate next')
                                printInc('AND R2, R0, R0')
                                printComment('Now negate to set to TRUE')
                                printInc('NOT R2')
                                printComment('Branch past negation if TRUE')
                                printInc('LL R7, %s' % (str(pc+4)))
                                printComment('Do the branch')
                                printInc('BRE')
                                printComment('Make FALSE if not skipped')
                                printInc('NOT R2')

                                eqstack.pop()
                                eqstack.pop()
                                guardStack.pop()
                                lastBefore = inst[-1]
                            if not (lastBefore == 'eqmath' or inst[-1] == 'eqmath' or inst[-1] == 'not'):
                                doubleAnd = True
                            ''' Now keep pushing new results to
                                the regs and applying the operation '''
                            for instTuple in reversed(guardStack):
                                # Evaluation finished
                                if instTuple[0] == 'if' or instTuple[0] == 'ifelse':
                                    startGuard = False
                                    # Actual if guard comparison
                                    printComment('Check if guard is false')
                                    printInc('CMP R2, 0')
                                    printComment('Addr to skip the if body (computed on second pass)')
                                    printInc('LL R7, (%s)' % (str(currIf)))
                                    currIf += 1
                                    printComment('Skip the body if guard false')
                                    printInc('BRE')

                                    guardStack.pop()
                                    break
                                # Getting out of range of evaluated booleans, so exit
                                elif instTuple[1] < currIndent:
                                    break
                                else:
                                    lastBefore = instTuple[0]
                                    if instTuple[0] == 'not':
                                        printComment('Perform NOT on current value')
                                        printInc('NOT R2')
                                    elif instTuple[0] == 'eqmath':
                                        # Accumulate the next operation
                                        printComment('Load variable address (' + eqstack[-2][1] + ') to accumulate')
                                        printInc('LL R5, %s' % (vardict[eqstack[-2][1]]))
                                        printComment('Load value of variable')
                                        printInc('LDR R4, [R5]')
                                        printComment('Compare the variable (' + eqstack[-2][1] + ') to the clause')
                                        printInc('CMP R4, %s' % (eqstack[-1][1]))
                                        printComment('Set to FALSE...')
                                        printInc('AND R3, R0, R0')
                                        printComment('...Now negate to set to TRUE')
                                        printInc('NOT R3')
                                        printComment('Branch past negation if result TRUE')
                                        printInc('LL R7, %s' % (str(pc+4)))
                                        printComment('Do the branch')
                                        printInc('BRE')
                                        printComment('Make FALSE if not skipped')
                                        printInc('NOT R3')

                                        eqstack.pop()
                                        eqstack.pop()
                                    else:
                                        if instTuple[0] == 'and':
                                            printComment('Apply the AND')
                                            printInc('AND R2, R2, R3')
                                        elif instTuple[0] == 'or':
                                            printComment('Apply the OR')
                                            printInc('OR R2, R2, R3')
                                        elif instTuple[0] == 'eqbool':
                                            printComment('XOR checks if values are different')
                                            printInc('XOR R2, R2, R3')
                                            printComment('Negate the result to check equality')
                                            printInc('NOT R2')
                                        if prevDoubleAnd:
                                            # Load the first result
                                            printComment('Load addr of result')
                                            printInc('LL R5, %s' % (vardict[str(boolEval) + '*']))
                                            # "Pop" the finished boolean off the "stack"
                                            boolEval -= 1
                                            printComment('Load previously accumulated boolean result')
                                            printInc('LDR R3, [R5]')
                                            # Load the second result
                                            '''printComment('Load addr of result')
                                            print('LL R5,', vardict[str(boolEval - 1) + '*'])
                                            pc += 1
                                            printComment('Load previously accumulated boolean result')
                                            print('LDR R3, [R5]')
                                            pc += 1'''
                                            prevDoubleAnd = False
                                    # Discard the used value
                                    guardStack.pop()
                            # We anticipate a fresh boolean evaluation in the future, so hide away the value
                            if doubleAnd and startGuard:
                                boolEval += 1
                                varaddr += 1
                                vardict[str(boolEval) + '*'] = varaddr
                                # Store the result for the clause
                                printComment('Address to store temp boolean')
                                printInc('LL R5 %s' % (str(varaddr)))
                                printComment('Store it now for future use')
                                printInc('ST R2 [R5]')

                                doubleAnd = False
                                prevDoubleAnd = True
                        guardStack.append((inst[-1], currIndent))
                        prevIndent = currIndent
                else:
                    if (inst[-1] == 'for'):
                        count += 1
                        if (count == 1):
                            # Keep track of vars in memory
                            if not info[1] in vardict:
                                varaddr += 1
                                vardict[info[1]] = varaddr
                            currvar.append(info[1])
                        elif (count == 2):
                            '''set register '''
                            printComment('For loop starting value')
                            printInc('LL R2, %s' % (str(int(info[1]))))
                            printComment('Address to keep counter for (' + currvar[-1] + ')')
                            printInc('LL R5, %s' % (vardict[currvar[-1]]))
                            printComment('Store current value in memory')
                            printInc('ST R2, [R5]')
                            branchfor.append(pc)
                        elif (count == 3):
                            count = 0
                            '''push data for later'''
                            data.append(str(int(info[1])))
                    if (inst[-1] == 'octaves'):
                        '''set octaves'''
                        # Use base 10 for the instruction since
                        # it will be converted back to binary
                        printComment('Set octaves')
                        printInc('LL R4, ' + str(int(info[1][1:-1], 2)))
                    if (inst[-1] == 'wait'):
                        printComment('Wait')
                        printInc('LL R6, ' + str(info[1]))
                    if (info[2] == 'action'):
                        if (info[1] == 'enableSample'):
                            printInc('LL R3, 1')
                        elif (info[1] == 'disableSample'):
                            printInc('LL R3, 2')
                        elif (info[1] == 'displayState'): 
                            printInc('LL R3, 3')
                        elif (info[1] == 'enableGraphics'):
                            printInc('LL R3, 4')
                        elif (info[1] == 'disableGraphics'):
                            printInc('LL R3, 5')
                        elif (info[1] == 'freeze'):
                            printInc('LL R3, 6')
                        elif (info[1] == 'unfreeze'):    
                            printInc('LL R3, 7')
                        elif (info[1] == 'enableAutotune'):
                            printInc('LL R3, 8')
                        elif (info[1] == 'disableAutotune'):
                            printInc('LL R3, 9')
                    if (inst[-1] == 'eqmath'):
                        eqstack.append(info)

    for instr in reversed(inst):
        if (inst[-1] == 'for'):
            printComment('Load address of innermost variable (' + currvar[-1] + ')')
            printInc('LL R5, %s' % (vardict[currvar[-1]]))
            currvar.pop()  # get rid of stale innermost value
            printComment('Load value of innermost variable')
            printInc('LDR R2, [R5]')
            printComment('Increment the counter')
            printInc('ADD R2, 1')
            printComment('Check if bounds are exceeded')
            printInc('CMP R2, %s' % (str(int(data.pop()) + 1)))
            printComment('Load possible branch address')
            printInc('LL R7, %s' % (branchfor.pop()))
            printComment('Branch to start of loop if necessary')
            printInc('BRE')
        if (inst[-1] == 'if'):
            branchif.append(pc+1)
        if (inst[-1] == 'ifelse'):
            branchelse.append(pc+1)
        inst.pop()

    printComment('Halt processor')
    printInc('HLT')

    astFile.close()

    pcFile.write('# branchif: %s\n' % (str(branchif)))
    pcFile.write('# branchelse: %s' % (str(branchelse)))

    print()
    print(':: Generation (Pass 1) successful! ::')
    print(':: Unfinished assembly written to ./' + pass1_fname + ' ::')

    ''' Now do a second pass and replace all unknowns with actual addresses '''
    pcFile.close()
    pcFile = open(pass1_fname)

    # Reverse lists for proper numbering

    branchif.reverse()
    branchelse.reverse()

    for line in pcFile:
        # Ignore comments
        if (line[0] == '#'):
            continue
        # Replace all if statement pc addresses
        subst_parens = re.search(r'\([\d]+\)', line)
        if subst_parens is not None:
            line = line.replace(subst_parens.group(0), str(branchif.pop()))
        # Replace all else statement pc addresses
        subst_angled = re.search(r'<[\d]+>', line)
        if subst_angled is not None:
            line = line.replace(subst_angled.group(0), str(branchelse.pop()))
        outputFile.write(line)

    outputFile.close()

    print()
    print(':: Generation (Pass 2) successful! ::')
    print(':: Final assembly written to ./' + pass2_fname + ' ::')
    print()
