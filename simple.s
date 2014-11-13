	.text
	.global _start
_start:
	movl $_binary_data_bin_start, %eax
	movl $_binary_code_bin_start, %ecx
	addl %eax, 4(%ecx)    # reg word
	movl (%eax), %esi
	addl %ecx, %esi
	movl $stack_end, %ebx
	jmp *%esi
	.bss
stack:	.space 0x100
stack_end:
	
