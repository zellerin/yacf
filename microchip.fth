% ( compile word )
: prev here -4 + ;
0 , : pbase [ prev ] ;
0 ,
: pmacros [ prev dup ] nop [ 4 reg ] ! ;
: imm? [ nop ] find if ;
0 ,
: pnrmacros [ prev dup ] nop [ 4 reg ] ! ;
: nrm? [ nop ] find if ;
0 ,
: known? [ prev dup ] find ;
: pic [ nop ] nop [ 4 reg ] ! ;
: call cfa pbase @ + dup c, 8 ash #x20 + ;? if 4a+ 8 + ] then c, ;
: macro 4a+ found ;
: next @a @ ;
: found cfa exec ;
: cw imm? jne found drop known? jne call drop err ;
...
% ( comment block xv )
: pbase negative start of compiled code 
: call do a call
: next ( -w ) ; ( next word to compile )
: name ( w- ) ; ( print name of word with space before )
: ?compile ( n- ) ; Is the word green?
: cnr if compile word follows, compile octet load ;
% ( compiler table )
: cnr ?compile if next nrm? jne macro 2drop c, #x30 c, then ;
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
: movwf #x80 +l 2c, ;
forth
: ... 2 +blk buffer a! 0 do ; ( this must be on end )
pic
... ( now we compile by new rules )
% ( macros )
% ( asm test )
here - pbase !
: foo foo 1 nop 23 movwf ;
pbase @ - save 0 flush bye
% ( comment )