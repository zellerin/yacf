% ( Main application )
: numbers [ 2 +blk ] ;
: view [ 4 +blk ] ;
numbers load
: . bl nrh flush ;
view load
0 pg 2 pg 4 pg 6 pg 8 pg
a@+ drop ffind cfa save 0 bye
% ( load numbers and do basic test )
% ( Print numbers )
: digit 10 / dup ldedx #x30 + hold ;
: hdigit dup #xf and 10 cmp -if 7 + then #x30 + hold 4 lsr ;
: nrh hdigit jne nrh drop ; 
: uu digit testeax jne uu drop ;
: nr testeax -if uu ; ] then - uu 45 hold ;
: bl 32 hold ; : cr 10 hold ;
%
: digit ( n-n ) hold last digit; keep nr/10
: hdigit ( n-n )hold last hexa digit, keep nr/0x10
: nr ( n- ) hold signed decimal number
: nrh ( n- ) hold unsigned hexa number
: uu ( n- ) hold unsigned decimal number
% ( ANSI coloured output. ) 
: hld/ dup #xff and hold 8 ash jne hld/ drop ;
: fg 109 hold hold #x1b5b33 hld/ ;
: top #x1b5b4a hld/ #x3b3166 hld/ #x1b5b31 hld/ ;
: blue 52 fg ; : green 50 fg ;
: yellow 51 fg ; : red 49 fg ;
: black 48 fg ; ( when white background )
: black 57 fg ; cr
...
% ( Individual color words )
% ( Print individual token categories )
  : name dname drop bl ;
  : 2dup over over ;
  : page flush 4 + ; ( just stall at same place )
  dhere ( address of table ) cr
    h, ( continued word ) ] dname drop ; cr
    h, ( yellow number ) ] 4 ash nr yellow bl ; cr
    h, ( green word ) ] name green ; cr
    h, ( red word ) ] name red cr ; cr
    h, ( blue word ) 0 reg ] find cfa !esi drop *esi [ cr
    h, ( white word ) ] name black ; cr
    h, ( blue number ) ] 4 ash nrh blue bl ; cr
    h, ( yellow word ) ] name yellow ;
  : .code tagidx [ nop ] +l vexec ;
...
% ( comment block xxv )
% ( print code blocks )
  : .@-code -4 + dup @ .code ;
  : 4x .@-code .@-code .@-code .@-code ;
  : 16x 4x 4x 4x 4x ;
  : 64x 16x 16x 16x 16x ;
  : show black 64x 64x drop ;
  : pg cr dup buffer #x1fc +l show nr bl [ a@+ page ] name cr flush ;
%
: .@-code ( n-n ) print code, decrease addr )

