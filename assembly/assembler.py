import sys
import re
#import mif

def to_binary(num, digits):
    try:
        num = int(num)
    except ValueError:
        return 'NaN'
    val = bin(num)[2:].zfill(digits)
    if (len(val) > 8):
        return 'NaN'
    else:
        return val


def find_opcode(instruction):
    switcher = {
        # R instructions:
        'AND': '11000',
        'ADDR': '11001',
        'SUBR': '11010',
        'OR': '11011',
        'XOR': '11100',

        # M instructions:
        'LD': '10000',
        'LDR': '10001',
        'ST': '10010',
        'NOT': '10011',
        'CMPR': '10100',

        # I instructions:
        'LL': '01000',
        'LH': '01001',
        'CMP': '01010',
        'ADD': '01011',
        'SUB': '01100',
        'SHL': '01101',
        'SHR': '01110',

        # J instructions:
        'BRE': '00001',
        'BRG': '00010',

        # Other:
        'HLT': '11111',
        'NOOP': '00000'
    }
    return switcher.get(instruction, 'Instruction not found')


def find_register_bits(register, d_reg=False):
    if d_reg:
        if register == 'R0':
            return 'R0 set as Destination Reg'
    if (((register[0] == 'R') & (len(register) == 2))
            & ((register[1] != '8') & (register[1] != '9'))):
        return to_binary(register[1], 3)
    elif (((register[0] == '[') & (len(register) == 4))
            & ((register[1] != '8') & (register[1] != '9'))):
        return to_binary(register[2], 3)
    else:
        return 'Incorrect register entry'


def find_immediate(imm):

    if imm[1] == '-':
        return 'Incorrect immediate entry'
    elif imm[0] == '#':
        return to_binary(imm[1:], 8)
    else:
        return 'Incorrect immediate entry'


def assembler(file_1, file_o, file_e):
    instruction_list = list()
    line_num = 1
    # file_1 = 'C:/Users/Brandon/Desktop/School/ECE554/music-group-master/assembly/asm_test4.txt'
    # file_o = 'C:/Users/Brandon/Desktop/School/ECE554/music-group-master/assembly/output4.txt'
    # file_e = 'C:/Users/Brandon/Desktop\School/ECE554/music-group-master/assembly/error4.txt'

    f = open(file_1, 'r')
    e = open(file_e, 'w')
    for line in f:
        instruction = ''
        assembly = (re.split(r'[,\s]\s*',line))
        opcode = find_opcode(assembly[0])
        if opcode == 'Instruction not found':
            msg = ('error on line ' + str(line_num) + ', error located in opcode\n')
            e.write(msg)
            instruction_list.append('0000000000000000')
            line_num += 1
            continue
        instruction += opcode
        # R instructions
        if (opcode[0] == '1') & (opcode[1] == '1'):
            if opcode == '11111':
                instruction_list.append('1111111111111111')
                line_num += 1
                continue
            reg_1 = find_register_bits(assembly[1], d_reg=True)
            reg_2 = find_register_bits(assembly[2])
            reg_3 = find_register_bits(assembly[3])
            if (reg_1 == 'NaN') | (reg_1 == 'Incorrect register entry'):
                e.write('error on line ' + str(line_num) + ', error located in D_reg\n')
                instruction_list.append('0000000000000000')
                line_num += 1
                continue
            if reg_1 == 'R0 set as Destination Reg':
                e.write('error on line ' + str(line_num) + ', ' + reg_1)
                instruction_list.append('0000000000000000')
                line_num += 1
                continue
            if (reg_2 == 'NaN') | (reg_2 == 'Incorrect register entry'):
                e.write('error on line ' + str(line_num) + ', error located in S_reg\n')
                instruction_list.append('0000000000000000')
                line_num += 1
                continue
            if (reg_3 == 'NaN') | (reg_3 == 'Incorrect register entry'):
                e.write('error on line ' + str(line_num) + ', error located in T_reg\n')
                instruction_list.append('0000000000000000')
                line_num += 1
                continue
            instruction += reg_1
            instruction += reg_2
            instruction += reg_3
            while len(instruction) < 16:
                instruction += '0'
            instruction_list.append(instruction)
            line_num += 1
            continue
        # M instructions
        elif opcode[0] == '1':
            if opcode == '10100':
                reg_1 = find_register_bits(assembly[1])
            else :
                reg_1 = find_register_bits(assembly[1], d_reg=True)
            if ((opcode[4] == '1') & (opcode[3] == '1')):
                reg_2 = find_register_bits(assembly[1])
            else:
                reg_2 = find_register_bits(assembly[2])
            if (reg_1 == 'NaN') | (reg_1 == 'Incorrect register entry'):
                e.write('error on line ' + str(line_num) + ', error located in D_reg\n')
                instruction_list.append('0000000000000000')
                line_num += 1
                continue
            if reg_1 == 'R0 set as Destination Reg':
                e.write('error on line ' + str(line_num) + ', ' + reg_1)
                instruction_list.append('0000000000000000')
                line_num += 1
                continue
            if (reg_2 == 'NaN') | (reg_2 == 'Incorrect register entry'):
                e.write('error on line ' + str(line_num) + ', error located in S_reg\n')
                instruction_list.append('0000000000000000')
                line_num += 1
                continue
            instruction += reg_1
            instruction += reg_2
            while len(instruction) < 16:
                instruction += '0'
            instruction_list.append(instruction)
            line_num += 1
            continue
        # I instructions
        elif opcode[1] == '1':
            if opcode == '01010' | opcode == '01000':
                reg_1 = find_register_bits(assembly[1])
            else :
                reg_1 = find_register_bits(assembly[1], d_reg=True)
            imm = find_immediate(assembly[2])
            if (reg_1 == 'NaN') | (reg_1 == 'Incorrect register entry'):
                e.write('error on line ' + str(line_num) + ', error located in D_reg\n')
                instruction_list.append('0000000000000000')
                line_num += 1
                continue
            if reg_1 == 'R0 set as Destination Reg':
                e.write('error on line ' + str(line_num) + ', ' + reg_1)
                instruction_list.append('0000000000000000')
                line_num += 1
                continue
            if (imm == 'NaN') | (imm == 'Incorrect immediate entry'):
                e.write('error on line ' + str(line_num) + ', error located in Imm\n')
                instruction_list.append('0000000000000000')
                line_num += 1
                continue
            instruction += reg_1
            instruction += imm
            if len(instruction) != 16:
                e.write('error on line ' + line_num + ', instruction not 16 bits\n')
                instruction_list.append('0000000000000000')
                line_num += 1
                continue
            instruction_list.append(instruction)
            line_num += 1
            continue
        # J and other instructions
        else:
            if opcode == '00000':
                instruction_list.append('0000000000000000')
                line_num += 1
                continue
            else:
                while len(instruction) < 16:
                    instruction += '0'
                instruction_list.append(instruction)
                line_num += 1
    o = open(file_o, 'w')
    first_line = 'DEPTH='
    first_line += str(line_num - 1)
    first_line += ';\n'
    o.write(first_line)
    o.write('WIDTH=16;\n')
    o.write('ADDRESS_RADIX=UNS;\n')
    o.write('DATA_RADIX=BIN;\n')
    o.write('CONTENT\n')
    o.write('BEGIN\n')
    i = 0
    for entry in instruction_list:
        entry += ';\n'
        line = str(i) + ' : ' + entry
        o.write(line)
        i += 1
    o.write('END;')
    f.close()
    e.close()
    o.close()
    print("SUCCESS")



if __name__ == "__main__":
    if len(sys.argv) == 6:
        if sys.argv[2] == '-e':
            assembler(sys.argv[1], sys.argv[5], sys.argv[3])
        else :
            assembler(sys.argv[1], sys.argv[3], sys.argv[5])
    elif len(sys.argv) == 4:
        if sys.argv[2] == '-e':
            assembler(sys.argv[1], './output_file.mif', sys.argv[3])
        else :
            assembler(sys.argv[1], sys.argv[3], './error_file.txt')
    else :
        if len(sys.argv) < 2:
            print('Usage: Python assembler.py <input.txt>')
            quit()
        assembler(sys.argv[1], './output_file.mif', './error_file.txt')