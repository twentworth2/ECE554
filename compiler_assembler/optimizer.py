from __future__ import print_function

#! /usr/bin/env python3.8

''' ECE 554 Project SP 2020
    Ilhan Bok
    Optimizer portion of FindTune compiler '''

###############################################
''' Find all documentation, including the language syntax specification
    (useful for making programs in FindTune) on the project GitHub. If
    something is unclear, try reading the relevant section on the spec,
    looking carefully at parser/compiler output, or contacting Ilhan
    on Slack '''
###############################################

import sys
import re

import scanner
import parser

# Ensure python is up to date (python3 is preferred)
try:
  assert sys.version_info >= (3, 0)
except:
  print('Please use Python 3.0 (`python3`) or above with this compiler')
  sys.exit(1)

# Do some command line parsing

if len(sys.argv) > 2:
    sys.exit('Only one command line arg allowed for now (input file). Sorry.')
elif len(sys.argv) == 1:
    sys.exit('Please provide input file to scan')
f = open(sys.argv[1], 'r')

AST = parser.createParse(f)

if AST == None:
  sys.exit(1)


