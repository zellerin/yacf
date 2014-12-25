% ( redefine function calls, using offset )
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
: ,call ( a- ) compile call to address
: cw ( w- ) execute if immediate, compile call if in dictionary or error
: ,lit ( w-,-w ) compile call to last dup definition and ensure top is loaded
: doj ( a- ) compile short or long jump to address
: call ( a- ) ; compile call or jump (short or long)
: ytog ( n-? ) execute following numeric macro or ensure top is loaded
: cnr ( ?-? ) run ytog if green word follows
: dbg ( w-w ) print current word and position
[
% ( compiler table )
dhere cr
h, here ( ignore word ) ] drop ; cr
h, here ( yellow nr ) ] 4 ash next cnr ; cr
h, ( compile word ) ] cw ;
cr h, ( define word ) ] dbg
  dhere 4 reg @ @ - over +
  w, 4 reg @ ! w, there w, ; cr
over dup w, w, ( ignore twice )
cr w, ( yellow nr ) drop
cr h, ( yellow word ) ] 0 reg fexec next cnr ;
: tagidx dup #x7 and 2 shl ;
: nop ;
: cword tagidx [ nop ] +l vexec ;

% ( Compile single word. cr
the table of functions is patched back after function is created. cr
all function expect the code on input cr
( define ) load 
[ % ( compile block )
: compile a@+ cword
: 1x @a 23 shl drop jne compile @a #x200 +l a! compile ;
: wfrom - here + dup - here + ;
: save wfrom 3 write drop ;
: load buffer @a [ eax ] push drop dup a! compile dup [ eax ] pop a! ;
: +blk @a [ 0 buffer - ] +l 9 lsr + ;
: ... 2 +blk buffer a! 0 compile ; 
macros
: ifc #x73 2c, here ;
% ( comment block )
: compile ( w- ) compile word and advance
: 1x ( - ) compile word unless on page boundary
: load ( b- ) save address, load block, continue
: +blk ( -a ) Address of the next block ;
: ... load next block [
% 
