% ( bootstrap macros )
macros
: if #x75 2c, here ;
: -if #x78 2c, here ;
: then dup raddr - over 1- c! drop ; 
forth
: h, here w, ;
: name dname drop 10 hold ;
: 4a+ a@+ drop ;      
% ( conditionals )
% ( compile word )
: next @a @ ;
: err name [ a@+ ] error name 
: ;? next [ a@+ ; ] cmp drop ;
: far? [ #x7e - ] cmp ;
: doj cfa raddr far? -if -2 + #xeb c, c, ; 
] then -5 + #xe9 c,, ; 
: c/j c, cfa [ 1 reg ] @-+ -4 + , ; 
: call ;? if 4a+ doj ; ] then #xe8 c/j ;
: fexec find if drop err ; ] then
: found cfa exec ;
: imm? [ 2 reg ] find if ;
: known? [ voc ] @ find ;
: cw imm? jne found drop known? jne call drop err ;
: nrm 4a+ found ;
: cnr #xf and -2 + drop if next [ 6 reg ] find jne nrm drop drop [ a@+ dup ] cw #xb8 c,, then ;
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
% ( compile item )
dhere cr
h, here ( ignore word ) ] drop ; cr
h, here ( yellow nr ) ] 4 ash next cnr ; cr
h, ( compile word ) ] cw ;
h, ( define word ) 4 reg ] @ @ dhere [ 4 reg ] @ ! w, w, here w, ; cr
over dup w, w, ( ignore twice ) cr
w, ( yellow nr ) drop
h, ( yellow word ) ] [ 0 reg ] fexec next cnr ;
: cword dup #xf and dispatch ;
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
ook
%
