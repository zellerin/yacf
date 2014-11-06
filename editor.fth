% ( ANSI coloured output. ) 
: hld/ dup #xff and hold 8 ash jne hld/ drop ;
: fg 109 hold hold #x1b5b33 hld/ ;
: top #x1b5b4a hld/ #x3b3166 hld/ #x1b5b31 hld/ ;
: blue 52 fg ; : green 50 fg ;
: yellow 51 fg ; : red 49 fg ;
: black 48 fg ; ( when white background )
: black 57 fg ; cr
% ( Individual color words )
% ( Print individual token categories )
  : name dname drop bl ;
  dhere ( address of table ) cr
    h, ( continued word ) ] dname drop ; cr
    h, ( yellow number ) ] 4 ash nr yellow bl ; cr
    h, ( green word ) ] name green ; cr
    h, ( red word ) ] name red cr ; cr
    h, ( blue word ) 0 reg ] find cfa [ eax ] push drop ; cr
    h, ( white word ) ] name black ; cr
    h, ( blue number ) ] 4 ash nrh blue bl ; cr
    h, ( yellow word ) ] name yellow ;
: tagidx dup #x7 and 2 shl ;
: nop ;
: .code tagidx [ nop ] +l vexec ;
% ( comment block xxv )
% ( print code blocks )
  : .@-code -4 + dup @ .code ;
  : 4x .@-code .@-code .@-code .@-code ;
  : 16x 4x 4x 4x 4x ;
  : 64x 16x 16x 16x 16x ;
  : show black 64x 64x drop ;
  : pg cr dup buffer #x1fc +l show nr bl [ a@+ page ] name top flush ;
%
: .@-code ( n-n ) print code, decrease addr )
% ( key-based operations )
: 0var dhere 0 w, ;
: vock [ 0var ] ;
: map [ 0var ] ; vock map !
: sread 3 sys/3 ;
: key 4 here 120 + 0 sread drop here 120 + @ ;
: fkey 4 shl vock find ;
: defk map @ @ dhere map @ ! w, 4 shl w, here w, ;
: blk [ 0var ] ;
: found cfa exec ;
: main [ blk ] @ pg
	     key dup fkey jne found
          drop drop nrh [ a@+ undef ] name main ;
#x66 defk [ blk ] @ 2 + [ blk ] ! main ;
#x62 defk [ blk ] @ -2 + [ blk ] ! main ;
#x63 defk [ blk ] @ 1 xor [ blk ] ! main ;
flush main
%

: 0var ; allocate memory cell
: vock ; keys vocabulary
: map ; current map to use
: blk ; curent block
: main ; view texts
( f-orward, b-ackwards, c-omments )
%

