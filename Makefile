all: yacf editor.blk

yacf: comp.o shannon.o
	ld -o $@ -T yacf.lnk comp.o shannon.o

yacf: raw

clean:
	rm -f *.o raw yacf parse *.blk

raw: x86.blk numbers.blk
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

compile: yacf compiler.blk
	cat compshare.blk compiler.blk > c
	$(strace) ./yacf 4< c 3> code.bin 5> data.bin
	objdump -D -m  i386 -b binary code.bin
	od -t x4 data.bin
