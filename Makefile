yacf: comp.o shannon.o
	ld -o $@ -T yacf.lnk comp.o shannon.o

yacf: raw

clean:
	rm -f *.o raw yacf parse

raw: parse x86.fth compiler.fth src.fth
	cat x86.fth compiler.fth src.fth |./parse > raw

recompile: x86.fth c/parse recompile.f
	cat x86.f recompile.f | ./c/parse  > recompile	

CFL=-fomit-frame-pointer -Os -g

shannon.o: CFLAGS=-mregparm=2 -fcall-saved-ebx -fcall-saved-edi $(CFL)

parse: shannon.o
parse: CFLAGS+=$(CFL)
parse: LDFLAGS=

.PHONY: clean code
code: code.bin
	objdump -D -m  i386 -b binary code.bin

code.bin: yacf
	./yacf 3> code.bin
