import sys
import os
import getopt

import ft_parser
import ft_generator

''' ECE 554 Project SP 2020
    Ilhan Bok, Ben Holzem, Tristan Wentworth
    FindTune compiler

    Find all documentation on the project GitHub. If
    something is unclear, try reading the relevant section on the spec,
    looking carefully at compiler output logs, or messaging #compiler
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

# Change the desired file name suffixes here
fnames = ['tok.txt', 'ast.txt', 'assembly_code.txt']


def printHelp():
    print('python3 compiler.py -h -p <prefix [default=none]> filename')
    print('    -h --help      (print this help message)')
    print('    -p --prefix    (prefix of process files, no prefix by default or if prefix=none)')
    print('    filename       (input FindTune (.ft) file to convert to assembly)')


def printNote():
    print()
    print('       ; ')
    print('       ;;')
    print('       ;\';.')
    print('       ;  ;;')
    print('       ;   ;;')
    print('       ;    ;;')
    print('       ;    ;;')
    print('       ;   ;\'')
    print('       ;  \'')
    print('  ,;;;,;')
    print('  ;;;;;;')
    print('  `;;;;\'')
    print()
    print(' ***** FindTune Compiler ***** ')
    print(' ::   ECE 554 Spring 2020   :: ')
    print(' ::   v3.0                  :: ')
    print(' ***************************** ')
    print()


try:
    opts, args = getopt.getopt(sys.argv[1:], 'hp:', ['help=', 'prefix='])
except getopt.GetoptError:
    printHelp()
    sys.exit(2)

prefix = 'none'

for opt, arg in opts:
    if opt in ('-h', '--help'):
        printHelp()
        sys.exit()
    elif opt in ('-p', '--prefix'):
        prefix = arg

# Ensure that the last argument is the input file
if len(args):
    inputFile = args[0]
else:
    print(':: No input file provided ::')
    printHelp()
    sys.exit(2)

# Forward slash for mac and linux, backwards slash for windows
sep = '/'
if os.name == 'nt':
    sep = '\\'
# Create file prefix for future use
preamble = prefix + sep + prefix + '_'

printNote()

# Create directory for output file storage
if os.path.exists(prefix):
    print(':: Directory with prefix already exists ::')
    sys.exit(1)

os.makedirs(prefix)

ft_parser.printRes(inputFile, preamble, fnames)

# Prevent accidental overwrite of old assembly file
if os.path.isfile(fnames[2]):
    resp = input(' ' + fnames[2] + ' already exists! Overwrite it (y/n)? ')
    if resp == 'y' or resp == 'yes':
        print(':: Overwriting... ::')
        print()
    else:
        print(':: Aborting. ::')
        print()
        sys.exit(0)

pass_one = preamble + 'pass1_' + fnames[2]
ft_generator.printRes(pass_one, fnames[2], preamble + fnames[1])

print(':: Compiler finished successfully ::')
print(':: Check the directory .' + sep + prefix + ' for extra data ::')
print()
