
#define TOP %eax
#define Areg %edi
#define stack_reg %ebx

.macro drop_a_at_plus
mov (Areg), %eax
lea 4(Areg), Areg
.endm

.macro push_stack
mov %eax,(%ebx)
lea -4(%ebx), %ebx
.endm

/* Simple evaluator/compiler */
        .global _start,iobuff
        .text

a_at_plus:
        push_stack
        drop_a_at_plus
        ret

a_store:
	mov TOP, Areg
	jmp pop

do_store:
	mov 4(%ebx), %esi
	mov %esi, (%eax)
	mov 8(%ebx), %eax
	lea 8(%ebx), %ebx
	ret
	
pop:    mov 4(%ebx), %eax
        lea 4(%ebx), %ebx
        ret

find_loop:      /* top of stack - word; stack - address */
        call over
        call over
        movl 4(TOP), TOP
        xor 4(%ebx), %eax
        lea 4(%ebx), %ebx
        andl $-0x8, TOP
        je found                # (0 ptr-to-word word)
        call pop
find:                           # (vocabulary word)
        movl (TOP), TOP
        test TOP, TOP
        jne find_loop
        ret                     # 0

found:                          # (a b c)
        call pop
        add $4, %ebx                    # call drop_2nd
        ret                     # (b)

find_in_forth:                  # (code)
        push_stack
        mov regs, TOP           # forth vocabulary
        jmp find

find_in_forth2:                  # (code)
        push_stack
        mov regs+28, TOP           # forth vocabulary
        jmp find

	
do_words_comma:                 # (word)
        movl regs+12, %esi
        movl TOP, (%esi)
        addl $4, %esi
        movl %esi, regs+12
        jmp pop

do_comma:                       # (word)
        movl regs+4, %esi
        movl TOP, (%esi)
        addl $4, %esi
        movl %esi, regs+4
        jmp pop                 # ()

do_comma_char_shift:                  # (char)
        movl regs+4, %esi
        movb %al, (%esi)
        addl $1, %esi
        movl %esi, regs+4
        shr $8, %eax
        ret

do_comma_char:
        call do_comma_char_shift
        jmp pop                 # ()

iobuffer_word_sp:
        push_stack
        movl $0x20, TOP
        call do_hold
        # call sh_decode
        jmp pop

underflow:
        mov -4(Areg), TOP
        push_stack
        mov $0x14c0d980, TOP
something_failed:
        call iobuffer_word_sp
        call print_iobuff
        mov $2, TOP
do_exit:
        mov TOP, stack_reg
        mov $1, TOP
        int $0x80

overflow:
        mov -4(Areg), TOP
        push_stack
        mov $0xb0a61300,TOP
        jmp something_failed

_start:
        mov $regs, %ebp
        mov $stack_end-4, stack_reg
        mov $_binary_raw_start, Areg

main_loop:
        cmpl $stack_end-0x40, stack_reg
        jbe overflow
        cmpl $stack_end-4, stack_reg
        ja underflow

main_loop_nocheck:                      # (thrash top ...)
        drop_a_at_plus                  # Read opcode
	## Skip odd pages
	test $511, Areg
	jne 1f
	add $512, Areg
1:	
        push_stack                      # Get its type
        and $0x7, TOP
        jmp *call_types(,TOP, 4)        # (thrash opcode top ...)

.section .rodata
call_types:
        .int ignore_word
        .int yellow_nr
        .int compile_word
        .int define_word
        .int ignore_word        # Blue: edit time only
        .int ignore_word        # White: comment only
        .int yellow_nr          # Hex number
        .int yellow_word

.text
ignore_word:
        add $4,  stack_reg
        jmp main_loop_nocheck

define_word:
        mov regs+16, %edx       # address of vocabulary
        mov regs+12, %esi       # address of where to compile
        mov (%edx), TOP # former latest word
        mov %esi, (%edx)        # update vocabulary
        call do_words_comma
        # word to define
        and $-0x8, TOP
        call do_words_comma
        push_stack
        mov regs+4, TOP # where to store
        call do_words_comma
        push_stack
        call do_words_comma
        push_stack
        jmp main_loop

compile_word:                   # (thrash opcode)
        mov regs+8, TOP         # (macros opcode)
        call find               # (macro? opcode)
        jne macro_found
        call pop                # (opcode)
        call find_in_forth2      # (word? opcode)
        test TOP, TOP
        je green_find_failed
check_next_ret:
        movl (Areg), %esi
        mov $0xe8, %edx
        mov 8(TOP), TOP # target address
        sub $0xf0000002, %esi
        jne 1f
        inc %edx
        add $4, Areg
1:
        call compile_call_or_jump
        push_stack
        jmp main_loop


green_find_failed:
        movl $0x6441a800, TOP
some_find_failed:
        call iobuffer_word_sp
        push_stack
        movl $0xb2606cc0, TOP
        call iobuffer_word_sp
        jmp something_failed

compile_call:                   # (word-ptr)
        mov 8(TOP), TOP # target address
        # Address is relative, adjust
compile_call_address:
        mov $0xe8, %edx
compile_call_or_jump:
        movl regs+4, %esi
        sub %esi, TOP
        sub $5, TOP
        push_stack
        movl %edx, TOP
        call do_comma_char
        jmp do_comma

macro_after_yellow:             # (macro-word)
        add $4, Areg            # Skip the input pointer
macro_found:                    # (macro-word thrash )
        # We have still in second slot the code. We pass that to
        # macro to destroy that.
        mov 8(TOP), %esi        # (macro-code thrash)
        call pop                # changing ecx would do as well...
        call *%esi
        push_stack
        jmp main_loop           # (thrash)

yellow_nr:
        call pop
        sar $4, TOP
        jmp maybe_compile_stack

yellow_find_failed:             # (0 opcode)
        movl $0xb9d28930, TOP
        jmp some_find_failed

yellow_word:                    # (thrash code)
        call pop
        call find_in_forth      # word?
        test TOP, TOP
        je yellow_find_failed
        mov 8(TOP), %esi # asm-code
        call pop
        call *%esi              # ()
maybe_compile_stack:
        /* If there is green word after yellow one/nr, compile loading
        of the number. */
        push_stack
        mov (Areg), TOP # next-code
        and  $0xf, TOP
        xor $2, TOP
        jne main_loop
        # Green word follows. Is it nr eating macro?
green_after_yellow:
        mov (Areg), TOP # next-code
        push_stack
        movl regs+24, TOP
        call find               # (macro?)
        test TOP, TOP
        jne macro_after_yellow  # (opcode)
        call pop
        call pop
        call compile_push_code
        push_stack
        movl $0xb8, TOP
compile_int_op:                 # (opcode int)
        call do_comma_char
        call do_comma
        push_stack
        jmp main_loop           # (trash)

##   : ,push #x89 c, #x03 c, #x8d c, #x5b c, #xfc c, ; ( compile push code )
compile_push_code:
        push_stack
        movl $0x5b8d0389,%eax
        call do_comma
        push_stack
        movl $0xfc, %eax
        jmp do_comma_char

over:                           # (a b -- b a b)
        push_stack
        mov 8(%ebx), %eax
        ret

macros_now:      # Start compiling macros
        mov (regs+8), %esi
        mov %esi, (regs+16)
        ret

forth_now:
        mov (regs), %esi
        mov %esi, (regs+16)
        ret

nrmacros_now:
        mov (regs+24), %esi
        mov %esi, (regs+16)
        ret

print_iobuff:
        push_stack
        movl $iobuffer_end, TOP
        movl iobuff, %esi
        subl %esi, TOP
        push_stack
        movl %esi, TOP
        push_stack
        movl $1, TOP
        push_stack
        movl $4, TOP
        call syscall_3
        movl $iobuffer_end, %esi
        movl %esi, iobuff
        jmp pop

do_hold:
        movl iobuff, %esi
        dec %esi
        movl %esi, iobuff
        movb %al, (%esi)
        jmp pop

syscall_3:
        push %ebx
        mov 12(%ebx), %edx
        mov 8(%ebx), %ecx
        mov 4(%ebx), %ebx
        int $0x80
        pop %ebx
        add $12, %ebx
        ret

	.section .data.registers
regs:
        .int forth /* 0: forth dictionary */
        .int heap /* 1: */
        .int macros /* 2 */
        .int words_area /* 3 */
        .int forth /* New words dict - 4 */
	
iobuff:
        .int iobuffer_end
        .int nrmacros /* 6 */
        .int forth /* 7: forth dictionary for compiling */
	.int iobuffer_end /* 8: iobuffer end, constant */
	.int _binary_raw_start /* 9: where source is */
	.int letter_queue /* 10: parsing letters */

letter_queue:	.ascii   " rtoeani" "smcylgfw" "dvpbhxuqkzj34567891-0.2/;:!+@*,?"
	.data

forth: .int .+4
	.int .+16, 0xfc000000, (do_comma), 0
	.int .+16, 0xfd200000, (do_comma_char), 0
	.int .+16, 0x87e96000, (do_comma_char_shift), 0
	.int .+16, 0x818c9620, (macros_now), 0
	.int .+16, 0x192c4580, (nrmacros_now), 0
	.int .+16, 0xc8427600, (forth_now), 0
	.int .+16, 0x14c26000, (over), 0
	.int 0,0,0,0

	.section .sources, "a"
code:

        .data
macros: .int 0
nrmacros: .int 0

	.section .bss.pages
pages:		
	.space 0x10000

	.section .bss.heap
heap:
        .space 0x0f000
iobuffer_end:

	.bss
	.section .bss.words
words_area:
        .space 0x10000
stack_end:

