% ( rebuild app )
cr #x0e load ( conditionals )
cr #x10 load ( numbers )
: ld bl #x5d hold dup nr #x5b hold flush load ;
cr #x12 ld ( names )
cr #x14 ld ( output )
cr #x16 ld ( search )
cr #x18 ld ( search )
cr #x1a ld ( elf )
cr #x1c ld ( compiler )
cr #x1e ld ( compiler )
: oreg reg ;
: reg 2 shl #x30000 +l ;
cr target mark compile
cr #x22 ld ( generated code )
cr dump flush
;s
% ( rebuild app )
42 bye
% ( init code )
cr dhere 4 oreg @ ! ( ensure link will be 0 )
0 , ( last )
: over dup [ #x08438b 3c, ] ( nop ) ;
#x08 ld ( basic words )
#x0a ld ( a-words )
#x10 ld ( numbers )
init #xbb c, #x30100 , ( ebx - stack ) ]
#x30000 dup !iobuf
[ 8 reg ] !
#x12 . 30 bye ;
4 oreg @ @ dbase @ + there + base @ - #x20054 + ! ( fix last )
;s
% ( init code )
cr ensure last links is 0
cr place for latest word
cr basic words
cr a-words
cr numbers
cr stack top to ebx
cr set iobuf and its end
cr print #x12
cr fixt latest pointer
% 