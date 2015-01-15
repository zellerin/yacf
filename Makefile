all: future

clean:
	rm -f  *~ *.blk *.o code.bin B

CFL=-fomit-frame-pointer -Os -g

shannon.o: CFLAGS=-mregparm=2 -fcall-saved-ebx -fcall-saved-edi $(CFL)

parse: shannon.o
parse: CFLAGS+=$(CFL)
parse: LDFLAGS=

.PHONY: clean code

# Compiled source
%.blk: %.fth parse
	./parse <$< >$@ 

B: test.blk conds.blk numbers.blk compshare.blk elf.blk compiler.blk future.blk editor.blk x86-more.blk
	cat $^ > $@

future future.asm future.lst: yacf B
	$(strace) ./yacf 4> future | tee future.lst
	objdump -D -m  i386 -b binary future | tee future.asm
	chmod +x $@

check: future
	./future 4> future2
	diff future future2
