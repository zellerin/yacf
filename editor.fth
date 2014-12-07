% ( editor - ANSI coloured output. ) 
: hld/ dup #xff and hold 8 ash jne hld/ drop ;
: fg 109 hold hold #x1b5b33 hld/ ;
: top #x1b5b4a hld/ #x3b3166 hld/ #x1b5b31 hld/ ;
: blue 52 fg ; : green 50 fg ;
: yellow 51 fg ; : red 49 fg ;
: black 48 fg ; ( when white background )
: black 57 fg ; cr
% ( Individual color words )
% ( editor - Print individual token categories )
: nm dname drop bl ;
dhere ( address of table ) cr
    h, ( continued word ) ] dname drop ; cr
    h, ( yellow number ) ] 4 ash nr yellow bl ; cr
    h, ( green word ) ] nm green ; cr
    h, ( red word ) ] nm red cr ; cr
    h, ( blue word ) 0 reg ] find cfa [ eax ] push drop ; cr
    h, ( white word ) ] nm black ; cr
    h, ( blue number ) ] 4 ash nrh blue bl ; cr
    h, ( yellow word ) ] nm yellow ;
: tagidx dup #x7 and 2 shl ;
: .code tagidx [ nop ] +l vexec ;
% ( comment block xxv )
% ( editor - print code blocks )
  : .@-code -4 + dup @ .code ;
  : 4x .@-code .@-code .@-code .@-code ;
  : 16x 4x 4x 4x 4x ;
  : 64x 16x 16x 16x 16x ;
  : show black 64x 64x drop ;
  : pg cr dup buffer #x1fc +l show nr bl [ a@+ page ] name top flush ;
%
: .@-code ( n-n ) print code, decrease addr )
% ( key ops )
: vock [ 0var ] ;
: map [ 0var ] ; vock map !
: key 4 here 0 sread drop here @ ;
: fkey 4 shl vock find ;
: defk map @ @ dhere map @ ! w, 4 shl w, here w, ;
: !blk [ 0var dup ] ! ; 24 !blk
: @blk [ nop ] @ ;
: err [ 0var dup ] @ exec ;
: !err [ nop ] ! ;
: exekey key dup fkey jne found
          2drop nrh [ a@+ undef ] name err ;
here !err 
: main @blk pg exekey ;
cr #x61 defk ( a-bort ) ] 0 bye ;
cr #x66 defk ( f-orward ) ] @blk 2 + !blk main ;
cr #x62 defk ( b-ackward ) ] @blk -2 + !blk main ;
cr #x63 defk ( c-comment ) ] @blk 1 xor !blk main ;
cr flush main
%
: vock ; keys vocabulary
: map ; current map to use
: key ( -c ) read 4 chars return as word
: fkey ( c-a ) find word in vock
: defk ( c- ) code for char starts here
: !blk ( b- ) set curent block
: @blk ( -b ) read current block
: main ( - ) display page and read/execute key
%

