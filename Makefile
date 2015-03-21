all: future

clean:
	rm -f  *~

.PHONY: clean code

future future.lst: yacf yacf.blk
	$(strace) ./yacf yacf.blk 4> future | tee future.lst
	chmod +x $@

future.asm: future
	objdump -D --start-address 0xb0 -m i386 -b binary future | tee future.asm

check: future
	./future yacf.blk  4> future2
	diff future future2
