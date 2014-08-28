yacf
====

Yet another color forth - like code for x86

Uses 512 bytes long blocks of pre-parsed words; shannon.o defines the preparsing rules.

Even blocks are used as code, odd as comments.

Words are compiled to x86 instructions.

The core is in x86.f and compile.f; the src.f is a wrapper to
test/show. Currently, it dumps code and shows some pages.

`make code` shows compiled code using objdump.

## Tags
| tag | meaning |
| --- | ------- |
| 0 | Continuation of word |
| 1 | Decimal number |
| 2 | Word to compile (green) |
| 3 | Word to define (red) |
| 4 | Editor word (blue) |
| 5 | Comment (white) |
| 6 | Hexa number |
| 7 | Interactive word (yellow) |

## System registers

Primarily, pass data between build time and run time.

As part of the init, `%ebx` is set up to point to them.

| Idx | words | comment |
| --- | ----- | ------- |
| 0 | `voc` | Vocabulary for new words | 
| 1 | `here` | Code heap first empty place |
| 2 | | Last macro |
| 3 | `dhere` | Data heap first empty space |
| 4 | | Last defined regular word |
| 5 | `hold`, `iobuf`, `!iobuf` | Output buffer |
| 6 | | Last numeric macro |
| 7 | | 
| 8 | | end of iobuffer (constant) |
| 9 | | First buffer byte |


## Flags and jumps
- Zero flag and negative flag are used
- `dump` does not affect flags
- `find` returns success/failure in ZF
- `if` executes following code when zero flag is set (match)
- `-if` executes following code if negative flags is not set
- `jne` jumps to word when zero flag is not set

## Tips and simplifications
- Using only one, long form number macro `+` would be safer
- File manipulations can be avoided using fd's
- `objdump` has -b and -m options
- `nip nip nip` is same as [ 12 ,+stack ]

## Issues
- Long names are probably not tail called - fix `next` with like of
  `dup -15 and drop if a@+ drop @a @ then ;` (but it did not help now)

