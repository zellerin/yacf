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
%
: digit ( n-n ) hold last digit; keep nr/10
: hdigit ( n-n )hold last hexa digit, keep nr/0x10
: nr ( n- ) hold signed decimal number
: nrh ( n- ) hold unsigned hexa number
: uu ( n- ) hold unsigned decimal number
% ( Print names )
: sizeflag dup 30 ash 3 and ;
macros : tocl #xc189 2c, ;
nrmacros : ,rot 8 shl #xe0d3 +l 2c, ;
forth
: shl tocl drop 0 ,rot ;
: ash tocl drop 8 ,rot ; 
: size #x7050404 over 3 shl ash #x7f and ;
: offset [ #x161f000 4 shl ] over 3 shl ash #x7f and 3 shl ;
: 2. 2dup nrh bl nrh bl ;
: decode sizeflag offset
[ eax ] push drop size nip 2dup - 32 + ash dup [ eax ] pop + ;
a@+ i decode nrh bl nrh bl nrh flush
1 bye
cr #x10000 2 +blk buffer 4 sread drop
2 +blk load flush 18 bye

% ( Print names )
: sizeflag ( word -- word sizeflag )
: size ( sizeflag -- sizeflag size )
: offset ( sizeflag -- sizeflag offset )
: decode ( word -- word size letter )
[