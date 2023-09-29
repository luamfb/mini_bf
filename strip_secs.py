#!/usr/bin/env python3

import sys

########################################################################
#                              CONSTANTS                               #
########################################################################

EI_CLASS = 0x4
ELF_32BIT = 1

#EI_DATA = 0x5
#ELF_LITTLE_ENDIAN = 1

# All offset and size values assume a little endian 32-bit ELF.
# Also, offsets are relative to the beginning of the header the fields belong to.

ELF_OFFSET_SIZE_ZERO_OUT = [
        (0x20, 4), # e_shoff
        (0x2e, 2), # e_shentsize
        (0x30, 2), # e_shnum
        (0x32, 2), # e_shstrndx
]

########################################################################
#                              FUNCTIONS                               #
########################################################################

def check_args():
    if len(sys.argv) <= 1 or sys.argv[1] == '-h' or sys.argv[1] == '--help':
        print('Strip section headers and section header table of 32-bit ELF files')
        print('usage: {} <path_to_32bit_ELF>'.format(sys.argv[0]))
        sys.exit(0)

def get_bin_file_contents(filename):
    with open(filename, 'rb') as f:
        return bytearray(f.read())

def elf_sanity_checks(elf):
    assert elf[0] == 0x7F
    assert elf[1] == ord('E')
    assert elf[2] == ord('L')
    assert elf[3] == ord('F')
    assert elf[EI_CLASS] == ELF_32BIT
    #assert elf[EI_DATA] == ELF_LITTLE_ENDIAN

def zero_out_sec_header_fields(elf):
    for (offset, size) in ELF_OFFSET_SIZE_ZERO_OUT:
        for i in range(size):
            elf[offset + i] = 0x0

# simply tries to find the string '.shstrtab' in the binary and remove everything after that.
# Ideally this should use the section header table to find the .text section offset and size,
# but that's too much work.
#
def crop_elf(elf):
    index = elf.index(b'.shstrtab')

    # also remove the previous byte if it was zero
    # (that's presumably the null section's name)
    if index > 1 and elf[index - 1] == 0x0:
        index -= 1

    return elf[:index]

def write_bin_file(contents, filename):
    with open(filename, 'wb') as f:
        f.write(contents)

########################################################################
#                              TOP-LEVEL                               #
########################################################################

check_args()
elf_filename = sys.argv[1]

elf = get_bin_file_contents(elf_filename)
elf_sanity_checks(elf)
elf = crop_elf(elf)
zero_out_sec_header_fields(elf)
write_bin_file(elf, elf_filename)
