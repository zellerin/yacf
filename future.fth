% ( comp.S duplicate )
target mark compile
dhere 4 reg @ ! ( ensure link will be 0 )
0 , ( last )
: a@+ dup da@+ ;
: a! [ #xc789 2c, ] ( nop )
: drop nip [ eax ] reg! ;
: ! nip [ ecx ] reg! !ecx drop ;
: over dup [ #x08438b 3c, ] ( nop ) ;
: 2dup over over ;
: xor /xor/ nip ;
: r@ dup [ eax ] pop ;
: sys/3 [ ebx ] push /sys/ [ ebx ] pop #xc [ ,+stack ] ( nop ) ;
: bye 2dup 1 sys/3 ;
: reg 2 ash #x30000 +l ;
: iobuf 5 reg @ ; ( in x86 )
% ( basics )
% ( output )
: !iobuf 5 reg ! ;
: c! nip [ ecx ] reg! !cl drop ;
: ! nip [ ecx ] reg! !ecx drop ;
: hold iobuf 1- dup !iobuf c! ;
: + over+ nip ;
: write 4 sys/3 drop ;
: flush #x30000 iobuf - + iobuf 1 write ;
1 +blk load
init #xbb c, #x30100 , ( ebx - stack ) ]
#x30000 !iobuf
#x12 .
30 bye ;
4 reg @ @ dbase @ + there + base @ - #x20054 + ! ( fix last )
dump flush 0 bye 
% ( output )
% ( numbers )
: digit 10 / dup [ edx ] ldreg #x30 + hold ;
: hdigit dup #xf and 10 cmp -if 7 + then #x30 + hold 4 lsr ;
: nrh hdigit if drop ; ] then nrh ; 
: uu digit testeax if drop ; ] then uu ;
: nr testeax -if uu ; ] then - uu 45 hold ;
: bl 32 hold ; : cr 10 hold ;
: . bl nrh flush ;
cr
: nop ;
dup . a!
% ( numbers )

% ( Simple app )
: reg 2 shl #xbeef +l ;
: + over+ nip ;
: dup dup ;
: drop nip [ eax ] reg! ;
: 2drop nip drop ;
init
] 23 bye [
0 c, ( align )
( start )
2dup  . .
dump flush 0 bye
=======
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
