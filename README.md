yacf
====

Yet another color forth - like code for x86

Uses 512 bytes long blocks of pre-parsed words; shannon.o defines the preparsing rules.

Even blocks are used as code, odd as comments.

Words are compiled to x86 instructions.

The core is in x86.f and compile.f; the src.f is a wrapper to
test/show. Currently, it dumps code and shows some pages.

`make code` shows compiled code using objdump.
