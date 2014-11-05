% ( compile word )
here 0 , : base [ nop ] nop ;
: call cfa #x20 ;? if 4a+ 8 + ] then c, c, ;
: macro 4a+ found ;
: next @a @ ;
: found cfa exec ;
: cw imm? jne found drop known? jne call drop err ;
: cnr ?compile if next 6 reg find jne macro 2drop #x30 c, c, then ;
...
% ( comment block xv )
: base 
: call do a call
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
cr h, ( define word ) ] 4 reg @ @ dhere 4 reg @ ! w, w, here base @ + w, ; cr
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
: ... 2 +blk buffer a! 0 do ; 
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
macros
: nop 0 2c, ;

forth
2 +blk load flush 0 bye
% ( macros )
% ( asm test )
here - base !
: foo foo nop;
: bar foo bar ;
: bar foo bar ;
base @ - -1 +  save 0 bye
% ( comment )