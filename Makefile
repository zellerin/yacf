all: yacf editor.blk

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

bulk.blk: conditionals.blk numbers.blk compshare.blk elf.blk compiler.blk future.blk
	cat $^ > $@

simple: code.bin data.bin simple.lnk simple.o
	ld -T simple.lnk

future: yacf bulk.blk
	$(strace) ./yacf 4<bulk.blk 3> future | tee future.lst
	objdump -D -m  i386 -b binary future
	chmod +x $@

dump: conditionals.blk numbers.blk compshare.blk editor.blk dump.blk
	cat $^ > $@
