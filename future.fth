% ( simple sample app )
mark target
0var ( offset of start )
: reg 2 shl #xbeef +l ; ( will be saved later )
: over dup [ #x08438b 3c, ] ( nop ) ;
: 2dup over over ;
: sys/3 [ ebx ] push /sys/ [ ebx ] pop #xc [ ,+stack ] ( nop ) ;
: bye 2dup 1 sys/3 ;
: xor /xor/ nip ;
: + over+ nip ;
: dup dup ;
: drop nip [ eax ] reg! ;
: 2drop nip drop ;
: c! nip [ ecx ] reg! !cl drop ;
: ! nip [ ecx ] reg! !ecx drop ;

: iobuffer #x100000 ;
: letter #x100004 @ + @ #x7f and 
: hold iobuffer @ -1 + iobuffer ! iobuffer @ c! ;
: write 4 sys/3 drop ;
: iob! #x100100 iobuffer ! ;
...
% ( comment )
% 
: flush #x100100 iobuffer @ - + iobuffer @ 1 write
  #x100100 iobuffer ! ;
: digit 10 / dup [ edx ] ldreg #x30 + hold ;
: hdigit dup #xf and 10 cmp -if 7 + then #x30 + hold 4 lsr ;
: nrh hdigit if drop ; ] then nrh ; 
: uu digit testeax if drop ; ] then uu ;
: nr testeax -if uu ; ] then - uu 45 hold ;
: bl 32 hold ; : cr 10 hold ;
: . bl nrh flush ;
...
% ( comment )
%
: floop 2dup 4 + @ xor -8 and drop if nip testeax ; ] then
: find @ testeax if ; ] then floop ;
: align 1 shl ifc ; ] then align ;

init ( nop ) ]
dup iob!
#x100004 !
1 letter flush
0 bye ;
2dup .  . ( dstart start ) 
over - dhere + over 4 + ! ( fix last to work )
dump flush
% 
