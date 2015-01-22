#define O_RDWR                02
	.global start
        .set    noreorder
start:	
#       write(1, "hello, world.\n", 14);
        li    $a0,1
        la      $a1,hello
        li      $a2,14
        li      $v0,4004 	# sys_write
        syscall

#       close(fd);
        move    $a0,$s0
        li      $v0,4001
        syscall

quit:
        li      $a0,0
        li      $v0,4001 	# sys_close
        syscall

        j       quit
        nop

        .data
tty:    .asciz  "/dev/tty1"
hello:  .ascii  "Hello, world.\n"


