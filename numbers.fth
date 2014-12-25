% ( Print numbers )
: digit 10 / dup [ edx ] ldreg #x30 + hold ;
: hdigit dup #xf and 10 cmp -if 7 + then #x30 + hold 4 lsr ;
: nrh hdigit if drop ; ] then nrh ; 
: uu digit testeax if drop ; ] then uu ;
: nr testeax -if uu ; ] then - uu 45 hold ;
: bl 32 hold ; : cr 10 hold ;
: . bl nrh flush ;
cr
: nop ;
;s
% 
: digit ( n-n ) hold last digit; keep nr/10
: hdigit ( n-n ) hold last hexa digit, keep nr/0x10
: nr ( n- ) hold signed decimal number
: nrh ( n- ) hold unsigned hexa number
: uu ( n- ) hold unsigned decimal number
% ( Print names )
43 bye
: sizeflag dup 30 ash 3 and ;
macros : tocl #xc189 2c, ;
nrmacros : ,rot 8 shl #xe0d3 +l 2c, ;
forth
: shl tocl drop 0 ,rot ;
: ash tocl drop 8 ,rot ; 
: size #x7050404 over 3 shl ash #x7f and ;
: offset [ #x161f000 4 shl ] over 3 shl ash #x7f and 3 shl ;
: uncode #x3f and [ 10 reg @ ] +l @ #x7f and hold ;
: dname -8 and 
: decode sizeflag offset
[ eax ] push drop size nip 2dup - 32 + ash dup [ eax ] pop + 
uncode shl if drop ; ] then decode ;
;s
% ( Print names )
: sizeflag ( word -- word sizeflag )
: size ( sizeflag -- sizeflag size )
: offset ( sizeflag -- sizeflag offset )
: decode ( word -- word size letter )
[
% 