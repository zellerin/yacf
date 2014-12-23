% ( simple sample app )
target mark compile
: reg 2 shl #xbeef +l ;
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
: floop 2dup 4 + @ xor -8 and drop if nip testeax ; ] then
: find @ testeax if ; ] then floop ;
init
#xbb c, #x30100 , ( ebx - stack )
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
