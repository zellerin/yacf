% ( Output )
: name bl dname ;
: next @a @ ;
: err cr name [ a@+ error ] name flush ;

( source reading )
: 4a+ a@+ drop ;
: ?compile #x7 and #x2 cmp drop ;
: ;? next [ a@+ ; ] cmp drop ;
: imm? 2 reg find ;

( vocabulary searches )
: fexec find if drop err ; ] then	
: found cfa exec ;

( compiling targets )
: 0var dhere 0 w, ;
: base [ 0var ] ;
: dbase [ 0var ] ;
: dthere [ dbase ] @ dhere + ;

;s
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
dup @ testeax if nip ; ] then - + rfloop ;
: cfa 8 +@ [ base ] @-+ ;

( compile for target )
: voc! 4 reg ! ;
: target [ 0var dup ] voc! ;
: known? [ nop ] @ rfloop ;
: there [ base ] @ here + ;

( saving heap and data heap )
: wfrom - here + dup - here + ;
: save wfrom 3 write ;
: dfrom - dhere + dup - dhere + ;
: dsave dfrom 3 write ;
: mark here - #x20054 +l base ! dhere - dbase ! dhere here ;
: dump save dsave ;

%  ( saving heap )
: rfloop ( wv-a ) return address of word in vocabulary or zero, set flag
: wfrom ( a-an ) push on stack distance between address and here
: save ( a- ) write to stream 3 from address to here
: dfrom 
: dsave ( a- ) write to stream 5 from address to dhere
: mark ( -aa ) marks here and dhere as start for dump
: dump ( aa- ) save heap (from top address) and data heap (from next address)
: init ( a- ) boot code follows; store its location to address

cr (search in offsetted words )
;
% 
