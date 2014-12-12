% ( compile word )
: voc! [ 4 reg ] ! ;
: 0var dhere 0 w, ;
: pbase [ 0var ] ;
: end [ pbase ] @ - save 0 flush bye ;
: reladr [ pbase ] @ + 1 ash ;

: pmacros [ 0var dup ] voc! ;
: imm? [ nop ] find if ;
: pnrmacros [ 0var dup ] voc! ;
: nrm? [ nop ] find if ;
: known? [ 0var dup ] find ;
: pic [ nop ] voc! here - pbase ! ;
: call cfa reladr #x2000 +l ;? if 4a+ #x800 +l ] then 2c, ;
: macro 4a+ found ;
: next @a @ ;
: found cfa exec ;
: cw imm? jne found drop known? jne call drop err ;
: cnr ?compile if next nrm? jne macro 2drop c, #x30 c, then ;
: tagidx dup #x7 and 2 shl ;

% ( comment block xv )
: pbase negative start of compiled code 
: call do a call
: next ( -w ) ; ( next word to compile )
: name ( w- ) ; ( print name of word with space before )
: ?compile ( n- ) ; Is the word green?
: cnr if compile word follows, compile octet load ;
% ( compiler table )
: dbg dup cr name bl pbase @ here + 1 ash hdigit hdigit hdigit drop flush ;
dhere cr
h, here ( ignore word ) ] drop ; cr
h, here ( yellow nr ) ] 4 ash next cnr ; cr
h, ( compile word ) ] cw ;
cr h, ( define word ) ] dbg 4 reg @ @ dhere 4 reg @ ! w, w, here w, ; cr
over dup w, w, ( ignore twice )
cr w, ( yellow nr ) drop
cr h, ( yellow word ) ]  0 reg fexec next cnr ;
: cword tagidx [ nop ] +l vexec ;
% ( Compile single word. cr
the table of functions is patched back after function is created. cr
all function expect the code on input cr )
% ( compile block )
: dbg 10 hold @a dup @ dname bl dup @ nrh bl nrh flush ; 
: do ( dbg ) drop a@+ cword do ;
% ( comment block )
: do compile word and advance ;
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
: @1+! #x0a80 +l 2c, ;
: @1-! #x0380 +l 2c, ;
: @1+ #x0a00 +l 2c, ;
forth
: bit 7 shl + ;
0 do pic
: dup 0 ! 4 @1+! ;
: drop 4 @1-! 0 @ ;
: init
  #xf 0! ( tmr1h )
  #xe 0! ( tmr1l )
  #05 0! ( gpinit )
;
end 
% ( comment )