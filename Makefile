all: yacf editor.blk

yacf: comp.o shannon.o
	ld -o $@ -T yacf.lnk comp.o

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

bulk.blk: compshare.blk compiler.blk future.blk
	cat $^ > $@

simple: code.bin data.bin simple.lnk simple.o
	ld -T simple.lnk

code.bin data.bin: yacf bulk.blk
	$(strace) ./yacf 4<bulk.blk 3> code.bin 5> data.bin
	objdump -D -m  i386 -b binary code.bin
	od -t x4 data.bin
