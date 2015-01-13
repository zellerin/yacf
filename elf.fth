% ( elf headers )
: +base, #x20000 +l , ;
: ident
#x4c457f 3c, #x46 c, ( elf )
#x010101 , 0 , 0 , ;
: filehdr
#x30002 , ( et_exec )  1 , ( ev_current )
, ( start ) #x34 , ( ph-addr )
0 , ( no sections ) 0 , ( no flags )
#x200034 , ( header-size phentsize )
#x280001 , ( e-phnum s-shentsize )
0 , ( sects ) ;
: proghdr
1 , ( pt-load ) 
#x54 dup , dup +base, +base, ( offset p-vaddr p-addr )
, ( size )
#x100ac , ( memory size ) 
7 ,  ( flags rwx )
#x1000 , ( align )
;
: init here
there ident dup . filehdr
: heap! dup save [ 1 reg ] ! ;
: edump here there dthere + [ #x20054 - ] +l proghdr
heap! ;

;s
% ( elf )
: base ( - ) convert file address to real one
: ident ( - ) physical header ;
: filehdr ( a- ) file header. Uses relative offset of start. ;
: proghdr ( s- ) program header. Takes size. ;
% 