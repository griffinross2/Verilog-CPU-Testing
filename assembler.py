import os
import re

cwd = os.path.dirname(os.path.realpath(__file__))

instruction_set = { #   Opcode    Allow direct?  Allow indirect?    Description
    'nop' :             (0x00,          0,              0),         # No operation
    'lda' :             (0x01,          1,              1),         # Load A with value
    'sta' :             (0x03,          0,              1),         # Store A in memory
    'ldx' :             (0x11,          1,              1),         # Load X with value
    'stx' :             (0x13,          0,              1),         # Store X in memory
    'ldy' :             (0x21,          1,              1),         # Load Y with value
    'sty' :             (0x23,          0,              1),         # Store Y in memory
    'adc' :             (0x08,          1,              1),         # Add with carry A with value
    'sbc' :             (0x09,          1,              1),         # Subtract with carry A with value
    'mul' :             (0x0A,          1,              1),         # Multiply A with value
    'jmp' :             (0x10,          0,              1),         # Jump to address
    'jsr' :             (0x15,          0,              1),         # Jump to subroutine
    'rts' :             (0x17,          0,              0),         # Return from subroutine
    'biz' :             (0x36,          0,              1),         # Branch if zero (z flag is set)
    'bnz' :             (0x37,          0,              1),         # Branch if not zero (z flag is not set)
    'pha' :             (0x0C,          0,              0),         # Push A to stack
    'pla' :             (0x0E,          0,              0),         # Pull A from stack
    'phx' :             (0x1C,          0,              0),         # Push X to stack
    'plx' :             (0x1E,          0,              0),         # Pull X from stack
    'phy' :             (0x2C,          0,              0),         # Push Y to stack
    'ply' :             (0x2E,          0,              0),         # Pull Y from stack
    'bic' :             (0x38,          0,              1),         # Branch if carry (c flag is set)
    'bnc' :             (0x39,          0,              1),         # Branch if not carry (c flag is not set)
    'ora' :             (0x30,          1,              1),         # OR with A
    'and' :             (0x31,          1,              1),         # AND with A
    'xor' :             (0x32,          1,              1),         # XOR with A
    'not' :             (0x33,          0,              0),         # NOT A
    'shl' :             (0x34,          0,              0),         # Shift A left 1-bit
    'shr' :             (0x35,          0,              0),         # Shift A right 1-bit
    'tax' :             (0x40,          0,              0),         # Transfer A to X
    'tay' :             (0x41,          0,              0),         # Transfer A to Y
    'txa' :             (0x50,          0,              0),         # Transfer X to A
    'tya' :             (0x51,          0,              0),         # Transfer Y to A
    'ina' :             (0x48,          0,              0),         # Increment A
    'dea' :             (0x49,          0,              0),         # Decrement A
    'inx' :             (0x58,          0,              0),         # Increment X
    'dex' :             (0x59,          0,              0),         # Decrement X
    'iny' :             (0x68,          0,              0),         # Increment Y
    'dey' :             (0x69,          0,              0),         # Decrement Y
}

def assemble():

    labels = {'default' : [0, []]} # {'label': [address, list of instruction]}
    defines = dict() # {'define': value}
    assembly_words = [0]*32768 # instruction[address]

    with open(cwd + '/rom.asm', 'r') as file:
        lines = file.readlines()
        file.close()

    # Organize everything undeer labels
    for i in range(len(lines)):
        # Match blank line
        result = re.match(r'^\s*$', lines[i])
        if(result):
            continue

        # Match comment line
        result = re.match(r'^\s*;.*$', lines[i])
        if(result):
            continue

        # Match org directive
        result = re.match(r'^\.org\(([0-9]+)\)(?:\s*)$', lines[i])
        if(result):
            org_addr = int(result.group(1))
            i += 1
            result = re.match(r'^([a-zA-Z_][a-zA-Z0-9_]*)(?::\s*)$', lines[i])  # Match label
            if not result:
                print('.org directive missing label at line ' + str(i+1))
                break
            labels[result.group(1)] = [org_addr, []]
            continue

        # Match label
        result = re.match(r'^([a-zA-Z_][a-zA-Z0-9_]*)(?::\s*)$', lines[i])
        if(result):
            curr_label = list(labels.keys())[-1]
            label_addr = labels[curr_label][0]
            this_addr = label_addr + len(labels[curr_label][1])
            labels[result.group(1)] = [this_addr, []]
            continue

        # Match define label
        result = re.match(r'^([a-zA-Z_][a-zA-Z0-9_]*)(?::\s*)((\$|#)[0-9]+)(?:\s*)$', lines[i])
        if(result):
            defines[result.group(1)] = result.group(2)
            continue

        # Match instruction
        result = re.match(r'^(?:\s{4})([a-zA-Z]{3})(?:\s+)((?:(\$|#)([0-9]+))|([a-zA-Z]+))?(?:\s*)(?:;.*)*$', lines[i])
        if(result):
            # Check if instruction exists
            if not result.group(1) in instruction_set.keys():
                print('Invalid instruction ' + result.group(1) + ' at line ' + str(i+1))
                break
            # Check if value comes from define (retrieve value if it does)
            value_from_define = None
            if result.group(5) in defines:
                value_from_define = defines[result.group(5)]
            direct = result.group(3) == '#' or (value_from_define and value_from_define[0] == '#')
            indirect = result.group(3) == '$' or (value_from_define and value_from_define[0] == '$')
            value = value_from_define[1:] if value_from_define else result.group(4)
            # Check if instruction allows indirect addressing
            if (indirect or (result.group(5) and not value_from_define)) and instruction_set[result.group(1)][2] == 0:
                print('Invalid indirect addressing for ' + result.group(1) + ' at line ' + str(i+1))
                break
            # Check if instruction allows direct addressing
            if direct and instruction_set[result.group(1)][1] == 0:
                print('Invalid direct addressing for ' + result.group(1) + ' at line ' + str(i+1))
                break
            # Check if value is provided for instruction that requires it
            if not result.group(2) and (instruction_set[result.group(1)][1] == 1 or instruction_set[result.group(1)][2] == 1):
                print('No value provided for ' + result.group(1) + ' at line ' + str(i+1))
                break
            # modify the instruction opcode if indirect addressing is used and direct is also supported
            if (indirect or (result.group(5) and not value_from_define)) and instruction_set[result.group(1)][1] == 1:
                instruction = instruction_set[result.group(1)][0] + 0x80
            else:
                instruction = instruction_set[result.group(1)][0]
            # add the instruction under its label
            curr_label = list(labels.keys())[-1]
            labels[curr_label][1].append(instruction)
            # add the value if applicable
            if direct or indirect:
                labels[curr_label][1].append(int(value, 16))
            elif result.group(5):
                value = result.group(5) # Will resolve later
                labels[curr_label][1].append(value)
        else:
            print('No match at line ' + str(i))

    # Resolve labels
    for label in labels:
        if label == 'default':
            continue
        for i in range(len(labels[label][1])):
            if type(labels[label][1][i]) == str:
                if labels[label][1][i] in labels:
                    labels[label][1][i] = labels[labels[label][1][i]][0]
                else:
                    print('Undefined label ' + labels[label][1][i])
                    break

    # Assemble
    for label in labels:
        if label == 'default':
            continue
        for i in range(len(labels[label][1])):
            assembly_words[labels[label][0] + i] = labels[label][1][i]

    with open(cwd + '/rom.bin', 'wb') as file:
        for i in range(0, 32768):
            file.write(assembly_words[i].to_bytes(4, byteorder='little'))
        file.close()

def convert_to_readmemh():
    with open(cwd + '/rom.bin', 'rb') as file:
        with open(cwd + '/rom.mem', 'w') as mem_file:
            for i in range(0, 32768):
                bytes = file.read(4)
                val = int.from_bytes(bytes, byteorder='little')
                mem_file.write(f'{val:0{8}x}' + '\n')
            mem_file.close()
        file.close()

if __name__ == '__main__':
    assemble()
    convert_to_readmemh()