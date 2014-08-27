 % ( bootstrap macros )
forth
: name dname drop 10 hold ;
: 4a+ a@+ drop ;

% ( conditionals )
: @@ ( n- ) find next word in vocabulary

% ( compile word )
: next @a @ ;
: err name [ a@+ ] error name 
: ;? next [ a@+ ; ] cmp drop ;

: call ;? if 4a+ doj ; ] then ,call ;
: fexec find if drop err ; ] then
: found cfa exec ;
: imm? 2 reg find if ;
: known? [ voc ] @ find ;
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
dhere cr
h, here ( ignore word ) ] drop ; cr
h, here ( yellow nr ) ] 4 ash next cnr ; cr
h, ( compile word ) ] cw ;
h, ( define word ) ] 4 reg @ @ dhere 4 reg @ ! w, w, here w, ; cr
over dup w, w, ( ignore twice ) cr
w, ( yellow nr ) drop
h, ( yellow word ) ] 0 reg fexec next cnr ;
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
2 +blk load 18 bye
% ( comment block )
: wfrom ( a-ac ) ; push on stack distance between address and here
%
