% ( load code from ch4 )
forth
: load buffer a! ;
: +blk @a [ 0 buffer - ] +l 9 lsr + ;
: sread 3 sys/3 ;
cr #x10000 2 +blk buffer 4 sread drop
2 +blk load flush 18 bye
% ( load code from ch4 )

% 