% ( redo calls def , with offset )
: 0var dhere 0 w, ;
: base [ 0var ] ;
: dbase [ 0var ] ;
: dthere [ dbase ] @ dhere + ;
: cfa 8 +@ [ base ] @ - + ;
: relcfa cfa raddr -126 cmp ;
: ,call #xE8 c, cfa raddr -4 + , ;
: doj relcfa -if -2 + #xEB c, c, ; ] then -5 + #xE9 c,, ;
% see below 
%
: voc! 4 reg ! ;
: target [ 0var dup ] voc! ;
: known? [ nop ] find ;
: there [ base ] @ here + ;
: call dup . flush ;? if 4a+ doj ; ] then ,call ;
: imm? 2 reg find if ;
: cw imm? jne found drop known? jne call drop err ;
: macro 4a+ found ;
: ?compile #x7 and 2 cmp drop ;
: cnr ?compile if next 6 reg find jne macro 2drop [ a@+ dup ] cw #xb8 c,, then ;
% ( comment block xv )
: cw 
: next ( -w ) ; ( next word to compile )
: name ( w- ) ; ( print name of word with space before )
: err ( w- ) ; ( print error message on word )
: h, ( - ) ; ( store value of here on dstack )
: c/j ( ao- ) ; ( compile call or jump. Takes address of cell and opcode. )
: ;? ( - ) ; ( ZF=1, if ; follows - note drop does not change flags )
: doj ( o0-ox ) ;
: call ( ) ; compile call
: ?compile ( n- ) ; Is the word green?
% ( compiler table )
: dbg dup cr name bl there nrh bl dhere nrh flush ;
dhere cr
h, here ( ignore word ) ] drop ; cr
h, here ( yellow nr ) ] 4 ash next cnr ; cr
h, ( compile word ) ] cw ;
cr h, ( define word ) ] dbg 4 reg @ @ dhere 4 reg @ ! w, w, there w, ; cr
over dup w, w, ( ignore twice )
cr w, ( yellow nr ) drop
cr h, ( yellow word ) ] 0 reg fexec next cnr ;
: tagidx dup #x7 and 2 shl ;
: nop ;
: cword tagidx [ nop ] +l vexec ;

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
: ... 2 +blk buffer a! 0 do ; 
... 
% ( comment block )
: do compile word and advance
: 1x compile word unless on page boundary
: load ( b- ) save address, load block, continue
: +blk ( -a ) Address of the next block ;
: ... load next block ; ( done )
% ( test )
here dup - #x2000 + dup . base ! target
: foo foo foo foo foo  ;
save 0 bye
