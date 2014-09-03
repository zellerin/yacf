( number macros )
: 2c, dc,s c, ;
: 3c, dc,s 2c, ;
: 2c,n 2c, c, ;
: c,, c, , ;
: ,put #x0389 2c, ;
: ,+stack #x5b8d 2c,n ;

cr
nrmacros
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
% : + ; Add number to top
: 2c, ( store 2byte opcode )
: 3c, ( store 3byte opcode )
: 2c,n ( store 2 byte opcode followed by short number )

: / ( divides by number; remainder is left in edx. )
: @-+ @ - + ; ( sub <addr>, %eax )

% ( assembler )
cr macros
: ; ] #xc3 c, ;
cr forth
: eax 0 ; : ecx 1 ; : edx 2 ; : ebx 3 ;
: esi 6 ; : edi 7 ; 
cr nrmacros 
: reg! 11 shl #x038b +l 2c, ;
: ldreg 11 shl #xc089 +l 2c, ;
: pop #x58 +l c, ;
: push #x50 +l c, ;

macros
% ( Assembler )
: reg! ; mov @ebx, reg
: ldreg ; Load register ( cl ecx ) to TOP
: edx ldreg ; also remainder after division
: edi ldreg ; part of @a

% 
: /+/ #x044303 3c, ;
: nip 4 ,+stack ;
: !cl #x0888 2c, ;
: !ecx #x0889 2c, ;
: !esi #xc689 2c, ;
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
: *esi #xe6ff 2c, ;
% 
: ,put ; Make code to store eax below stack
: ,+stack ; ( n- ) Make code to advance ( that is drop ) stack by value

: xxx! ; Load word pointed by ebx to register
: !xxx ; store register to pointed by eax 
: break int $3 ( debugging )
: @ movl @eax, eax ( stack does not move )
: - ( negate - 2bit complement )
: 1- decx %eax ( slightly more effective than -1 + ) ;
% ( Basic words )
forth
: reg /reg/ ;
: dup dup ;
: drop nip [ eax ] reg! ;
: 2dup over over ;
: 2drop nip drop ;
: c! nip [ ecx ] reg! !cl drop ;
: ! nip [ ecx ] reg! !ecx drop ;

: + /+/ nip ;
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

: vexec @ : exec !esi drop *esi [

macros
: jne a@+ ffind if 5 bye then relcfa -if
-2 + #x75  c, c, ; ] then -6 + #x850f 2c, , ;

% ( lalla )
: ffind ; ( w-af ) find word in dictionary 
: wjump ; ( wc- ) compile short relative call to passed word
: jne ; jump to word unless zero flag set. Handles long calls.
: relcfa ; relative CFA of word on address; set NF if near


% 