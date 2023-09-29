#include <stdio.h>
static unsigned char memory[32768] = {0};

static char *data_ptr = memory;
static char *instr_ptr = NULL;

int main(int argc, char **argv) {

    if (argc != 2) return -1;

    instr_ptr = argv[1];
    while (*instr_ptr) {
        int should_update_instr = 1;
        switch (*instr_ptr) {
        case '>':
            data_ptr++;
            break;
        case '<':
            data_ptr--;
            break;
        case '+':
            (*data_ptr)++;
            break;
        case '-':
            (*data_ptr)--;
            break;
        case '.':
            putchar(*data_ptr);
            break;
        case ',':
            *data_ptr = (unsigned char) getchar();
            break;
        case '[':
            if (!*data_ptr) {
                int brace_count = 1;
                while (brace_count) {
                    instr_ptr++;
                    switch (*instr_ptr) {
                    case '[':
                        brace_count++;
                        break;
                    case ']':
                        brace_count--;
                        break;
                    }
                }
                should_update_instr = 0;
            }
            break;
        case ']':
            if (*data_ptr) {
                int brace_count = 1;
                while (brace_count) {
                    instr_ptr--;
                    switch (*instr_ptr) {
                    case ']':
                        brace_count++;
                        break;
                    case '[':
                        brace_count--;
                        break;
                    }
                }
                should_update_instr = 0;
            }
            break;
        /* other characters: ignore. */
        }
        if (should_update_instr) {
            instr_ptr++;
        }
    }

    return 0;
}
