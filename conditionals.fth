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
forth
;s
% ( lalla )
: ffind ; ( w-af ) find word in dictionary 
: wjump ; ( wc- ) compile short relative call to passed word
: jne ; jump to word unless zero flag set. Handles long calls.
: relcfa ; relative CFA of word on address; set NF if near
% 