( x86 )
: 2c, dc,s c, ;
: 3c, dc,s 2c, ;
: 2c,n 2c, c, ;
: c,, c, , ;
: ,put #x0389 2c, ;
: ,+stack #x5b8d 2c,n ;
cr macros
: ; ] #xc3 c, ;
: eax! #x038b 2c, ;
: ecx! #x0b8b 2c, ;
: !cl #x0888 2c, ;
: !ecx #x0889 2c, ;
: ldedx #xd089 2c, ;
: ldedi #xf889 2c, ;
: pop #x58 c, ;

: break 204 c, ;
: @ #x8b 2c, ; ( top -- mem/top/ )
: - #xd8f7 2c, ; ( top -- -top )
: 1- 72 c, ; ( top -- top-1 )
: dup ,put -4 ,+stack ;
: nip 4 ,+stack ;
%
: ,put ; Make code to store eax below stack
: ,+stack ; ( n- ) Make code to advance ( that is drop ) stack by value

: xxx! ; Load word pointed by ebx to register
: !xxx ; store register to pointed by eax 
: ldxxx ; Load register ( cl ecx ) to TOP
: ldedx ; also remainder after division
: ldedi ; part of @a
: break int $3 ( debugging )
: @ movl @eax, eax ( stack does not move )
: - ( negate - 2bit complement )
: 1- decx %eax ( slightly more effective than -1 + ) ;
% ( Macros )
cr nrmacros
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
forth
: drop nip eax! ;
: reg [ #x85448d , ] ( nop ) ; ( top -- top ; top to mem/ebp+4*eax/ )
: c! nip ecx! !cl drop ;
: ! nip ecx! !ecx drop ;
% ( Implementation of macros )
: 2c, ( store 2byte opcode )
: 3c, ( store 3byte opcode )
: 2c,n ( store 2 byte opcode followed by short number )

: / ( divides by number; remainder is left in edx. )
: @-+ @ - + ; ( sub <addr>, %eax )
% ( Macros iii nop nop )
: voc [ 0 reg ] @ ;
: here [ 1 reg ] @ ;
: dhere [ 3 reg ] @ ;
: ffind voc find ;
: dup dup ;
: cfa 8 +@ ;
: raddr [ 1 reg ] @-+ ;
: testeax 133 c, 192 c, ;
: wjump c, ffind cfa raddr 1- c, ;
: @@ a@+ ffind ;
: toesi [ @@ drop ] ,call #xe6ff 2c, ;
cr  macros
: nop ;
: jne testeax a@+ #x75 wjump ;
: exec #x89 c, 198 c, toesi ;
: dispatch #x85348b 3c, , toesi ;

forth
%
: ffind ( w-af ) find word in ditcionary )
: cfa ( a-a ) voc entry address to code address
: wjump ( wc- ) compile short relative call to passed word
: @@ ( n- ) find next word in vocabulary
: jne ; jump to word unless zero flag set
% ( Basic words )
: sys/3 [ #x53 c, #x0c538b 3c, #x084b8b 3c,
      #x045b8b 3c, #x80cd 2c, #x5b c,
      #x0cc383 3c, ] ( nop ) ; 
: write 4 sys/3 drop ;
: bye dup dup 1 sys/3 ;
: + [ #x044303 3c, ] ( nop ) nip ;
: @ @ ;
: dup dup ;
: - - ;
: break break ;
: @a dup ldedi ;
: w, [ 3 reg ] @ ! [ 3 reg ] @ 4 + [ 3 reg ] ! ;
: buffer 9 shl [ 9 reg @ ] +l ;
%
: sys/3 ; unix syscall
: w, ; write word on data stack 
Some macros need also counterpart on the interpret side.
: + ; needs a variant that would work on the non-immediate values/stack as well. 
% 