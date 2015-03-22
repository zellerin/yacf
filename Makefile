all: future

clean:
	rm -f  *~

.PHONY: clean code

future: yacf yacf.blk compile.blk
	$(strace) ./yacf compile.blk yacf.blk 4> future
	chmod +x $@

future.asm: future
	objdump -D --start-address 0xb0 -m i386 -b binary future | tee future.asm

check: future
	./future compile.blk yacf.blk  4> future2
	diff future future2
