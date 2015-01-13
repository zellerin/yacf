% ( Conditionals jumps and  find )
cr macros
: testeax #xc085 2c, ;
: if #x75 2c, here ;
: -if #x78 2c, here ;
: then dup raddr - over 1- c! drop ; 
: jne a@+ ffind if 5 bye then relcfa -if
-2 + #x75  c, c, ; ] then -6 + #x850f 2c, , ;
forth
: vexec @ : exec [ eax ] push drop ;
;s
% ( lalla )
: ffind ; ( w-af ) find word in dictionary 
: wjump ; ( wc- ) compile short relative call to passed word
: jne ; jump to word unless zero flag set. Handles long calls.
: relcfa ; relative CFA of word on address; set NF if near
% 