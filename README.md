yacf
====

Pic/microchip 13bit assembler compiler in something like color forth

New vocabularies are introduced:
- pmacros contains macros that generate pic code
- pnrmacros contains number macros that generate pic code
- pic vocabulary (set by pic word as one of effects) contains pic binary code.

When compiling pic words:
- Yellow words are searched in the forth vocabulary,
- Green words are either executed (pmacros) or compiled as calls to pic vocabulary words,
- Green pnrmacros after number or yellow word are executed
- Other green words after yellow word cause the top to be stored to W register

As opposed to forth code, dups/drops are not automatical for most macros/words.