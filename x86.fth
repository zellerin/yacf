% ( auxiliary words for macros )
: 2c, dc,s c, ;
: 3c, dc,s 2c, ;
: 2c,n 2c, c, ;
: c,, c, , ;
: ,put #x0389 2c, ;
: ,+stack #x5b8d 2c,n ;
% ( auxiliary words for macros )
: 2c, ( w- ) store 2byte opcode
: 3c, ( w- ) store 3byte opcode
: 2c,n ( cw- )store 1byte opcode followed by short number
: c,, ( wc- ) store octet instruction and long parameter
: ,put ( - ) dup sr @ ! ; compile code to copy top below stack
: ,+stack ( c- ) sr @ + sr ! ; compile code to advance stack by octet
% nrmacros
: + #xc083 2c,n ;
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
% ( nrmacros )
: +  ( c- , w - w+c ) Add octet to top
: +l Add word to top
: +@ + @ 
: @-+ @ - +
: @ ( a- ; -w ) reads word from address 
: ash arithmetical shift right 
: lsr logical shift right 
: shl shift left 
: and and with signed octet 
: / ( y- , a-b ) divides a by y remainder is left in edx 
: cmp ( w- , n-n; sets flag ) 
[
% ( x86 assembler )
cr macros
: ; ] #xc3 c, ;
: over+ #x044303 3c, ;
: nip 4 ,+stack ;
cr forth
: eax 0 ; : ecx 1 ; : edx 2 ; : ebx 3 ;
: esp 4 ; : ebp 5 ; : esi 6 ; : edi 7 ; 
: + over+ nip ;
cr nrmacros 
: reg! 11 shl #x038b +l 2c, ;
: ldreg 11 shl #xc089 +l 2c, ;
: pop #x58 + c, ;
: push #x50 + c, ;

macros
% ( x86 assembler ) cr macros
: ; return - now we can return from functions
: over+ over +
: nip drop second value [
cr forth 
: eax top [
cr
: edx remainder after division
: ebx stack
: esp return stack
: ebp regbase [
 cr
: edi a-reg [ cr cr 
nrmacros
: reg! /stack/ to reg
: ldreg /reg/ to top
% ( x86 asm )
: !cl #x0888 2c, ;
: !ecx #x0889 2c, ;
: break 204 c, ;
: @ #x8b 2c, ;
: - #xd8f7 2c, ;
: 1- 72 c, ;
: dup ,put -4 ,+stack ;
: /reg/ #x85448d , ;
: /sys/ #x0c538b 3c, #x084b8b 3c,
      #x045b8b 3c, #x80cd 2c, ;
: /xor/ #x44333 3c, ;
: da@+ #x78b 2c, #x47f8d 3c, ;
% ( x86 asm )
: !cl cl over !
: !ecx ecx over !
: break int $3 ( debugging )
: @ /top/ to top ( stack does not move )
: - ( negate - 2bit complement )
: 1- -1 + ;
[ cr
: /reg/ 4* regbase + @
: /sys/ syscall, needs sysnr and three args
: /xor/ over xor
: da@+ drop a@+
[ % ( Basic words )
forth
: reg /reg/ ;
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
: buffer 9 shl [ 9 reg @ ] +l ;
%
: cfa ( a-a ) voc entry address to code address ;
% ( A register and linux interface )
: a@+ dup da@+ ;
: a! [ #xc789 2c, ] ( nop ) drop ;
: @a dup [ edi ] ldreg ;
: sys/3 [ ebx ] push /sys/ [ ebx ] pop #xc [ ,+stack ] ( nop ) ;
: write 4 sys/3 drop ;
: bye 2dup 1 sys/3 ;

: flush [ 8 reg ] @ [ 5 reg ] @-+ iobuf 1 write
  [ 8 reg ] @ !iobuf ;

%
: sys/3 ; unix syscall
: w, ; write word on data stack 
Some macros need also counterpart on the interpret side.
: + ; needs a variant that would work on the non-immediate values/stack as well. 
% ( Conditionals jumps and  find )
cr macros
: testeax #xc085 2c, ;
: if #x75 2c, here ;
: -if #x78 2c, here ;
: then dup raddr - over 1- c! drop ; 

cr forth
: cfa 8 +@ ;
: floop 2dup 4 + @ xor -8 and drop if nip testeax ; ] then
: find @ testeax if ; ] then floop ;
: ffind voc find ;

: relcfa cfa raddr -126 cmp ;
: ,call #xe8 c, cfa raddr -4 + , ; 
: doj relcfa -if -2 + #xeb c, c, ; 
] then -5 + #xe9 c,, ; 

: vexec @ : exec [ eax ] push drop ;

macros
: jne a@+ ffind if 5 bye then relcfa -if
-2 + #x75  c, c, ; ] then -6 + #x850f 2c, , ;

% ( lalla )
: ffind ; ( w-af ) find word in dictionary 
: wjump ; ( wc- ) compile short relative call to passed word
: jne ; jump to word unless zero flag set. Handles long calls.
: relcfa ; relative CFA of word on address; set NF if near
% 