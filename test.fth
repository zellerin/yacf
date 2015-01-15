% ( Boot structure )
cr 2 load ( nr macros )
cr 4 load ( macros )
cr 6 load ( x86 )
cr 8 load ( words )
cr 10 load
cr 12 load
cr 0 bye
% ( Boot structure )
% ( number macros )
nrmacros
0 dhere
: + [ ! ] #xc083 2c,n ;
: +l #x05 c,, ;
: +@ #x408b 2c,n ;
: @-+ #x052b dc,s c,, ;
: @ ,put -4 ,+stack #xa1 c,, ;
: ash #xf8c1 2c,n ;
: lsr #xe8c1 2c,n ;
: shl #xe0c1 2c,n ;
: and #xe083 2c,n ;
: / #xbed231 3c, , #xf6f7 2c, ;
: cmp #x3d c,, ;
;s
% ( number macros )
% ( x86 )
macros
0 dhere : ; [ ! ] #xc3 c, ;
: over+ #x044303 3c, ;
: nip 4 ,+stack ;
forth
: eax 0 ; : ecx 1 ; : edx 2 ; : ebx 3 ;
: esp 4 ; : ebp 5 ; : esi 6 ; : edi 7 ; 
nrmacros 
: reg! 11 shl #x038b +l 2c, ;
: ldreg 11 shl #xc089 +l 2c, ;
: pop #x58 + c, ;
: push #x50 + c, ;
;s
% ( x86 ... )
% ( x86 asm )
macros
: !cl #x0888 2c, ;
: !ecx #x0889 2c, ;
: break 204 c, ;
: @ #x8b 2c, ;
: - #xd8f7 2c, ;
: 1- 72 c, ;
: dup ,put -4 ,+stack ;
: /sys/ #x0c538b 3c, #x084b8b 3c,
      #x045b8b 3c, #x80cd 2c, ;
: /xor/ #x44333 3c, ;
: da@+ #x78b 2c, #x47f8d 3c, ;
forth
: reg 2 shl #x30000 +l ;
;s

% ( asm )
% ( Basic words )
: dup dup ;
: drop nip [ eax ] reg! ;
: 2dup over over ;
: 2drop nip drop ;
: c! nip [ ecx ] reg! !cl drop ;
: ! nip [ ecx ] reg! !ecx drop ;

: @ @ ;
: - - ;
: break break ;

: voc [ 0 reg ] @ ;
: here [ 1 reg ] @ ;
: raddr [ 1 reg ] @-+ ;

: dhere [ 3 reg ] @ ;
: w, [ 3 reg ] @ ! [ 3 reg ] @ 4 + [ 3 reg ] ! ;
: h, here w, ;

: iobuf [ 5 reg ] @ ;
: !iobuf [ 5 reg ] ! ;
: hold iobuf 1- dup !iobuf c! ;
: xor /xor/ nip ;
: buffer 9 shl [ 9 reg ] @ + ;
;s
% ( Basic words )
% ( A register and linux interface )
: a@+ dup da@+ ;
: a! [ #xc789 2c, ] ( nop ) drop ;
: @a dup [ edi ] ldreg ;
: sys/3 [ ebx ] push /sys/ [ ebx ] pop #xc [ ,+stack ] ( nop ) ;
: write 4 sys/3 drop ;
: bye 2dup 1 sys/3 ;

: flush [ 8 reg ] @ [ 5 reg ] @-+ iobuf 1 write
: obufset
  [ 8 reg ] @ !iobuf ;
;s
%
: sys/3 ; unix syscall
: w, ; write word on data stack 
Some macros need also counterpart on the interpret side.
: + ; needs a variant that would work on the non-immediate values/stack as well. 
% % ( load code from ch4 )
forth
: +blk @a [ 0 buffer - ] +l 9 lsr + ;
: r. [ edx ] pop [ eax ] pop [ edx ] push ;
: x10  1 shl dup 2 shl + ;
: prnr @ dup 8 ash #xf and over #xf and x10 + ;
32 load
0 bye
;s
% ( load code from ch4 )
: +blk ( -n ) number of code block n blocks forward
: sread ( size from fd - ) read data from input
: load ( n-a ) read source from code block; store return address
% 