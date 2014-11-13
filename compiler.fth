% ( redo calls def, with offset )
: relcfa cfa raddr -126 cmp ;
: ,call #xE8 c, cfa raddr -4 + , ;
: doj relcfa -if -2 + #xEB c, c, ; ] then -5 + #xE9 c,, ;
: call ;? if 4a+ doj ; ] then ,call ;
: cw imm? jne found drop known? jne call drop err ;
: ,lit [ a@+ dup ] cw #xb8 c,, ;
: ytog next 6 reg find if 2drop ,lit ; ] then 4a+ found ; 
: cnr ?compile if ytog then ;
: dbg dup cr name bl there nrh bl dthere nrh flush ;
% ( comment block xv )
: relcfa ( a-o ) relative cfa for short calls ; set flag if small
: ,call ( ) ; compile call
: doj ( o0-ox )
: call ( ) ; compile call or jump
: ytog handle yellow to green transition  
;
% ( compiler table )
dhere cr
h, here ( ignore word ) ] drop ; cr
h, here ( yellow nr ) ] 4 ash next cnr ; cr
h, ( compile word ) ] cw ;
cr h, ( define word ) ] dbg 4 reg @ @ dhere [ dbase ] @ + 4 reg @ ! w, w, there w, ; cr
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
% 
