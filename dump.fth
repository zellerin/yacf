: stop dup 23 shl testeax drop ;
: show .@-code stop if ; ] then show ;
: gauge -4 + dup @ testeax drop if gauge ; ] then 4 +
   dup - 2 ash #x7f and [ a@+ free ] dname bl nr black cr ; 
: a2pg [ 0 buffer - ] +l 9 ash ;
: page dup a2pg digit nr [ a@+ page ] name black cr ;
: pg cr cr -4 + gauge show page cr flush -512 +l ;
: 3pg pg pg pg ;
45 buffer 3pg 3pg 3pg 3pg 3pg 3pg 3pg 0 bye