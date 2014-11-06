% ( compile word )
: voc! [ 4 reg ] ! ;
: pbase [ dhere dup ] ; 0 w,
: end [ dup ] @ - save 0 flush bye ;
: reladr [ nop ] @ + 1 ash ;

: pmacros [ dhere dup ] voc! ; 0 w,
: imm? [ nop ] find if ;
: pnrmacros [ dhere dup ] voc! ; 0 w,
: nrm? [ nop ] find if ;
: known? [ dhere dup ] find ; 0 w,
: pic [ nop ] voc! here - pbase ! ;
: call cfa reladr #x2000 +l ;? if 4a+ #x800 +l ] then 2c, ;
: macro 4a+ found ;
: next @a @ ;
: found cfa exec ;
: cw imm? jne found drop known? jne call drop err ;
: cnr ?compile if next nrm? jne macro 2drop c, #x30 c, then ;
...
% ( comment block xv )
: pbase negative start of compiled code 
: call do a call
: next ( -w ) ; ( next word to compile )
: name ( w- ) ; ( print name of word with space before )
: ?compile ( n- ) ; Is the word green?
: cnr if compile word follows, compile octet load ;
% ( compiler table )
dhere cr
h, here ( ignore word ) ] drop ; cr
h, here ( yellow nr ) ] 4 ash next cnr ; cr
h, ( compile word ) ] cw ;
cr h, ( define word ) ] 4 reg @ @ dhere 4 reg @ ! w, w, here w, ; cr
over dup w, w, ( ignore twice )
cr w, ( yellow nr ) drop
cr h, ( yellow word ) ] 0 reg fexec next cnr ;
: tagidx dup #x7 and 2 shl ;
: cword tagidx [ nop ] +l vexec ;
...
% ( Compile single word. cr
the table of functions is patched back after function is created. cr
all function expect the code on input cr )
( define ) load 
% ( compile block )
: do drop a@+ cword
: 1x @a 23 shl jne do drop ;
: wfrom - here + dup - here + ;
: save wfrom 3 write drop ;
: load buffer @a over a! dup do a! drop ;
: +blk @a [ 0 buffer - ] +l 9 lsr + ;
: sread 3 sys/3 ;
...
% ( comment block )
: do compile word and advance
: 1x compile word unless on page boundary
: wfrom ( a-ac ) push on stack distance between address and here
: save ( a- ) write TOP to here on stream 3
: load ( b- ) save address, load block, continue
: +blk ( -a ) Address of the next block ;
: ... load next block ; ( done )
% ( asm macros )
pmacros 
: nop 0 2c, ;
: ; ] 8 2c, ;
pnrmacros
: @and #x500 +l 2c, ;
: @+ #x700 +l 2c, ;
: ! #x80 +l 2c, ;
: 0! #x180 +l 2c, ;
: @ #x0800 +l 2c, ;
: ifbit #x1800 +l 2c, ; 
forth
: bit 7 shl + ;
: ... 2 +blk buffer a! 0 do ; ( this must be on end )
pic
... ( now we compile by new rules )
% ( macros )
% ( asm test )
: foo [ 64 3 bit ] ifbit ;
: bar foo bar ;
end
% ( comment )