% ( comp.S duplicate )
target mark dthere compile
: a@+ dup da@+ ;
: a! [ #xc789 2c, ] ( nop )
: drop nip [ eax ] reg! ;
: ! nip [ ecx ] reg! !ecx drop ;
: over dup [ #x08438b 3c, ] ( nop ) ;
: 2dup over over ;
: xor /xor/ nip ;
: floop 2dup 4 +@ xor -8 and drop if nip testeax ; ] then
: find @ testeax if ; ] then floop ;
: r@ dup [ eax ] pop ;
: sys/3 [ ebx ] push /sys/ [ ebx ] pop #xc [ ,+stack ] ( nop ) ;
: bye 2dup 1 sys/3 ;
init #xbb c, #x30100 , ( ebx - stack ) ]
30 bye ;
drop save flush 0 bye 

% ( comp.S duplicate )
% ( Simple app )
: reg 2 shl #xbeef +l ;
: + over+ nip ;
: dup dup ;
: drop nip [ eax ] reg! ;
: 2drop nip drop ;
: c! nip [ ecx ] reg! !cl drop ;
: ! nip [ ecx ] reg! !ecx drop ;
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
