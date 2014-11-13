% ( Print numbers )
forth
: digit 10 / dup [ edx ] ldreg #x30 + hold ;
: hdigit dup #xf and 10 cmp -if 7 + then #x30 + hold 4 lsr ;
: nrh hdigit jne nrh drop ; 
: uu digit testeax jne uu drop ;
: nr testeax -if uu ; ] then - uu 45 hold ;
: bl 32 hold ; : cr 10 hold ;
: . bl nrh flush ;
cr
: nop ;
: load buffer a! ;
: +blk @a [ 0 buffer - ] +l 9 lsr + ;
: sread 3 sys/3 ;
cr #x10000 2 +blk buffer 4 sread drop
2 +blk load flush 18 bye
%
: digit ( n-n ) hold last digit; keep nr/10
: hdigit ( n-n )hold last hexa digit, keep nr/0x10
: nr ( n- ) hold signed decimal number
: nrh ( n- ) hold unsigned hexa number
: uu ( n- ) hold unsigned decimal number
% 
