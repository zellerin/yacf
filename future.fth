% ( comment block )
: do compile word and advance
: 1x compile word unless on page boundary
: load ( b- ) save address, load block, continue
: +blk ( -a ) Address of the next block ;
: ... load next block
; ( done )
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

: floop 2dup 4 + @ xor -8 and drop if nip testeax ; ] then
: find @ testeax if ; ] then floop ;
init ( nop ) ] 0 reg @ bye ;
( dstart start ) 
over - dhere + over 4 + ! ( fix last to work )
42 w,
dump flush 0 bye
% 

