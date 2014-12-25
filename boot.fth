% ( load code from ch4 )
forth
: +blk @a [ 0 buffer - ] +l 9 lsr + ;
: sread 3 sys/3 ;
: load buffer @a over a! nip ;
: ;s a! ;
cr #x10000 2 +blk buffer 4 sread drop
#x0e load ( condits )
#x10 load ( numbers )
6 +blk load ( names )
8 +blk load ( program ...)
18 bye
% ( load code from ch4 )
: +blk ( -n ) number of code block n blocks forward
: sread ( size from fd - ) read data from input
: load ( n-a ) read source from code block; store return address
% 