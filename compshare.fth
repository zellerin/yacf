% ( Output )
: name bl dname drop ;
: next @a @ ;
: err cr name [ a@+ ] error name flush ;

( source reading )
: 4a+ a@+ drop ;
: ?compile #x7 and #x2 cmp drop ;
: ;? next [ a@+ ; ] cmp drop ;

( vocabulary searches )
: fexec find if drop err ; ] then	
: found cfa exec ;


( compiling targets )
: 0var dhere 0 w, ;
: base [ 0var ] ;
: dbase [ 0var ] ;
: dthere [ dbase ] @ dhere + ;


% ( Shared compile words )
: name ( n- ) hold name
: next ( -w ) ; ( next word to compile )
: 4a+ ( - ) advance a by 4
: ?compile ( c- ) use in ?compile if do-other do-compile ...
: err ( w- ) print error on word
: fexec ( cw-a ) find word in the vocabulary, exec if found
: found ( a- ) execute found word
: nop ( - ) do nothing
;

% ( saving heap and data heap )
: wfrom - here + dup - here + ;
: save wfrom 3 write drop ;

cr ( search in offsetted words )
: rfloop 2dup 4 + @ xor -8 and drop if nip testeax ; ] then
: rfind @ testeax if ; ] then [ dbase ] @ - + rfloop ;
: cfa 8 +@ [ base ] @ - + ;

( compile for target )
: voc! 4 reg ! ;
: target [ 0var dup ] voc! ;
: known? [ nop ] rfind ;
: there [ base ] @ here + ;

%  ( saving heap )
: wfrom ( a-an ) push on stack distance between address and here
: save ( a- ) write to stream 3 from address to here
: ;? ( - ) flag if semicolon follows

cr (search in offsetted words )
;
% 
