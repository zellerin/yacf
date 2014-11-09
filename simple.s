	.text
	.global _start
_start:
	movl $stack_end, %ebx
	movl $_binary_data_bin_start, %esi
	movl (%esi), %eax
	addl $_binary_code_bin_start, %eax
	jmp *%eax
	.bss
stack:	.space 0x100
stack_end:
	
