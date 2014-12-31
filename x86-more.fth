% ( Better x86 macros )
macros
: tocl #xc189 2c, ;
nrmacros
: ,rot 8 shl #xe0d3 +l 2c, ;
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
: find 2dup 4 + @ xor -8 and drop if nip testeax ; ] then
dup @ testeax if nip ; ] then - + find ;
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
: ,call #xE8 c, cfa raddr -4 + , ;
: doj cfa -if -2 + #xEB c, c, ; ] then -5 + #xE9 c,, ;
: call ;? if 4a+ doj ; ] then ,call ;
: known? [ 7 reg ] find ;
: cw imm? jne found drop known? jne call drop err ;
: ,lit [ a@+ dup ] cw #xb8 c,, ;
: ytog next [ 6 reg ] find if 2drop ,lit ; ] then 4a+ found ; 
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
cr h, ( yellow word ) ] [ 0 reg ] fexec next cnr ;
3 oreg !
: tagidx dup #x7 and 2 shl ;
: nop ;
: cword tagidx #x20060 +l vexec ;
: compile a@+ dup name flush @a 23 shl drop
  if @a #x200 +l a! then cword compile ;
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

;s
% ( comment block )
: compile ( w- ) compile word and advance
: load ( b- ) save address, load block, continue
: +blk ( -a ) Address of the next block ;
: ... load next block [
% 

