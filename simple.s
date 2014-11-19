/*
 * Memory layout:

| passed as | Address                |                        |
|-----------+------------------------+------------------------|
| %ecx      | _binary_code_bin_start | Start of code.bin      |
| TOP (eax) | _binary_data_bin_start | Start of data.bin      |
| reg word  | pseudoregisters (r/o)  | last words of data.bin |
|           | 0x100000               | heap                   |
| ebx       | stack_end              | end of stack           |

*/

	.text
	.global _start
_start:
	movl $_binary_data_bin_start, %eax
	movl $_binary_code_bin_start, %ecx
	addl %eax, 4(%ecx)    # reg word
	movl (%eax), %esi
	addl %ecx, %esi
	movl $stack_end-4, %ebx
	jmp *%esi

	.bss
heap:	.space 0x100000
stack_end:
	
