% ( rebuild app )
#x0e load ( conditionals )
#x10 load ( numbers )
: ld bl #x5d hold dup nr #x5b hold flush load ;
#x12 ld ( names )
#x14 ld ( output )
#x16 ld ( search )
#x18 ld ( search )
#x1a ld ( elf )
#x1c ld ( compiler )
#x1e ld ( compiler )
: oreg reg ;
: reg 2 shl #x30000 +l ;
target mark compile
#x22 ld ( generated code )
dump flush
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