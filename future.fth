% ( rebuild app )
cr #x0e load ( conditionals )
cr #x10 load ( numbers )
: ld bl #x5d hold dup nr #x5b hold flush load ;
cr 52 ld 
cr #x12 ld ( names )
cr #x14 ld ( output )
cr #x16 ld ( search )
cr #x18 ld ( search )
cr #x1a ld ( elf )
cr #x1c ld ( compiler )
cr #x1e ld ( compiler )
: oreg reg ;
: h, there dup . w, ;
: reg 2 shl #x30000 +l ;
: @,+ dup @ , 4 + ;
: ,16 @,+ @,+ @,+ @,+ ;
: cpchars 10 oreg @ ,16 ,16 ,16 drop ;
cr target mark compile
cr #x22 ld ( generated code )
cr edump dump flush
;s
% ( rebuild app )
: ld load reporting progress [
: cpchars copy character table from master [
% ( init code )
cr dhere 4 oreg @ !
cr 0 , ( last ) 0 , 0 ,
here 32 + 1 oreg !
cpchars
: over dup [ #x08438b 3c, ] ( nop ) ;
: + over+ nip ;
cr #x08 ld #x0a ld #x10 ld #x12 ld 54 ld
#x14 ld 56 ld 58 ld 60 ld
cr init
cr #xbb c, #x30100 ,
[ cr ] #x30000 dup !iobuf [ 8 reg ] !
[ 10 reg #x20080 ] !!
[ cr ] #x20054 dup [ 0 reg ] ! [ 7 reg ] !
[ 9 reg #x21000 ] !!
[ 1 reg #x29000 ] !!

0 hold 66 hold
#x10000 nop #x21000 nop
openr obufset
sread drop
#x21000 a!
compile
0 bye ;
cr 4 oreg @ @ dbase @ + there + base @ - #x20054 + !
;s
% ( init code )
cr ensure last links is 0
cr place for latest word
: over insert again word below top [
cr basic words
cr a-words
cr numbers
cr init
cr stack top to ebx
cr set iobuf and its end
cr print #x12
cr fixt latest pointer
% 