% ( load code from ch4 )
forth
: +blk @a [ 0 buffer - ] +l 9 lsr + ;
: sread 3 sys/3 ;
: load buffer @a over a! nip ;
: ;s a! ;
: openr 0 dup iobuf 5 sys/3 ;
: r. [ edx ] pop [ eax ] pop [ edx ] push ;
: x10  1 shl dup 2 shl + ;
: prnr @ dup 8 ash #xf and over #xf and x10 + ;
0 hold 65 hold
openr drop obufset
cr #x10000 2 +blk buffer
3 sread drop
r. r. r. prnr load
0 bye
;s
% ( load code from ch4 )
: +blk ( -n ) number of code block n blocks forward
: sread ( size from fd - ) read data from input
: load ( n-a ) read source from code block; store return address
% 