% ( Output )
: name bl dname drop ;
: next @a @ ;
: err cr name [ a@+ ] error name flush ;

( source reading )
: 4a+ a@+ drop ;
: ?compile #x7 and #x2 cmp drop ;
: ;? next [ a@+ ; ] cmp drop ;
: imm? 2 reg find if ;

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
: ;? ( - ) flag if semicolon follows
: err ( w- ) print error on word
: fexec ( cw-a ) find word in the vocabulary, exec if found
: found ( a- ) execute found word
: nop ( - ) do nothing
;

% ( search in offsetted words )
: rfloop 2dup 4 + @ xor -8 and drop if nip testeax ; ] then
: rfind @ testeax if ; ] then [ dbase ] @ - + rfloop ;
: cfa 8 +@ [ base ] @ - + ;

( compile for target )
: voc! 4 reg ! ;
: target [ 0var dup ] voc! ;
: known? [ nop ] rfind ;
: there [ base ] @ here + ;

( saving heap and data heap )
: wfrom - here + dup - here + ;
: save wfrom 3 write  ;
: dfrom - dhere + dup - dhere + ;
: dsave dfrom 5 write ;
: mark here - base ! dhere - dbase ! dhere here ;
: dump save dsave ;
: init there over ! drop ;

%  ( saving heap )
: wfrom ( a-an ) push on stack distance between address and here
: save ( a- ) write to stream 3 from address to here
: dfrom 
: dsave ( a- ) write to stream 5 from address to dhere
: mark ( -aa ) marks here and dhere as start for dumo
: dump ( aa- ) save heap (from top address) and data heap (from next address)
: init ( a- ) boot code follows; store its location to address

cr (search in offsetted words )
;
% 
