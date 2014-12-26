all: yacf editor.blk A

yacf: comp.o
	ld -o $@ -T yacf.lnk comp.o shannon.o

yacf: raw

clean:
	rm -f *.o raw yacf parse *.blk

raw: x86.blk boot.blk
	cat $^ > raw

CFL=-fomit-frame-pointer -Os -g

shannon.o: CFLAGS=-mregparm=2 -fcall-saved-ebx -fcall-saved-edi $(CFL)

parse: shannon.o
parse: CFLAGS+=$(CFL)
parse: LDFLAGS=

.PHONY: clean code

# Compiled source
%.blk: %.fth parse
	./parse <$< >$@ 

A: conditionals.blk numbers.blk compshare.blk elf.blk compiler.blk future.blk editor.blk
	cat $^ > $@

simple: code.bin data.bin simple.lnk simple.o
	ld -T simple.lnk

future future.asm future.lst: yacf A
	$(strace) ./yacf 32 4> future | tee future.lst
	objdump -D -m  i386 -b binary future | tee future.asm
	chmod +x $@

dump: conditionals.blk numbers.blk compshare.blk editor.blk dump.blk
	cat $^ > $@
