% ( Better x86 macros )
: dropdup #x038b 2c, ;
macros
: tocl #xc189 2c, ;
nrmacros
: ,rot 8 shl #xe0d3 +l 2c, ;
: drop 4 ,+stack dropdup ;
: ! #xa3 c,, 4 ,+stack dropdup ;
: !! #xb9 c,, #x0d89 2c, , ;
forth
;s
% ( Better x86 macros )
% ( Heap )
: , [ 1 reg ] @ !
  [ 1 reg ] @ 4 + [ 1 reg ] ! ;
: dc,s [ #x358b 2c,
  1 reg , #x0688 2c,
  #x46 c, #x3589 2c, 1 reg ,
  ] 8 ash ;
: c, dc,s drop ;
: c,, c, , ;
: find testeax if ; ] then
: floop 2dup 4 + @ xor -8 and drop if nip testeax ; ] then
dup @ testeax if nip ; ] then - + floop ;
: cfa 8 +@ ;
: ffind voc find ;

: relcfa cfa raddr -126 cmp ;
: ,call #xe8 c, cfa raddr -4 + , ; 
: doj relcfa -if -2 + #xeb c, c, ; 
] then -5 + #xe9 c,, ; 

: vexec @ : exec [ eax ] push drop ;
;s
% ( foo )
% ( bar )
: doj relcfa -if -2 + #xEB c, c, ; ] then -5 + #xE9 c,, ;
: call ;? if 4a+ doj ; ] then ,call ;
: known? voc find ;
: imm? [ 2 reg ] @ find ;
: 2c, dc,s c, ;
: 3c, dc,s 2c, ;
: 2c,n 2c, c, ;
: c,, c, , ;
: ,put #x0389 2c, ;
: ,+stack #x5b8d 2c,n ;

: cw imm? if drop known?
  if drop err ; ] then call ;
   ] then cfa exec ; 
: ,lit ,put -4 ,+stack #xb8 c,, ;
: ytog next [ 6 reg ] @ find if 2drop ,lit ; ] then 4a+ found ; 
: cnr ?compile if ytog then ;
: dbg dup cr name bl here nrh bl dhere nrh flush ;

;s
% ( Heap )
% ( compiler table )
dhere #x20060 base @ - + dup . 3 oreg !
h, there ( ignore word ) ] drop ; cr
h, there ( yellow nr ) ] 4 ash next cnr ; cr
h, ( compile word ) ] cw ;
cr h, ( define word ) ] dbg
  dhere [ 4 reg ] @ @ - over +
  w, [ 4 reg ] @ ! w, here w, ; cr
over dup w, w, ( ignore twice )
cr w, ( yellow nr ) drop
cr h, ( yellow word ) ] [ 0 reg ] @ fexec next cnr ;
3 oreg !
: tagidx dup #x7 and 2 shl ;
: nop ;
: cword tagidx #x20060 +l vexec ;
: compile a@+ flush cword compi ;
;s
% ( Compile single word. cr
the table of functions is patched back after function is created. cr
all function expect the code on input cr
( define ) load 
% ( boot block )
: +blk @a [ 0 buffer - ] +l 9 lsr + ;
: sread 3 sys/3 ;
: load buffer @a over a! nip ;
: ;s a! ;
: openr 0 dup iobuf 5 sys/3 ;
: r. [ edx ] pop [ eax ] pop [ edx ] push ;
: x10  1 shl dup 2 shl + ;
: prnr @ dup 8 ash #xf and over #xf and x10 + ;
: nrmacros [ 4 reg 6 reg ] !! ;
: macros [ 4 reg 2 reg ] !! ;
: forth [ 4 reg 0 reg ] !! ; 
;s
% ( comment block )
: compile ( w- ) compile word and advance
: load ( b- ) save address, load block, continue
: +blk ( -a ) Address of the next block ;
: ... load next block [
% 

