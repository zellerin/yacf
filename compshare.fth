% ( Shared compile words )
: name bl dname drop ;
: 4a+ a@+ drop ;
: found cfa exec ;
: ?compile #x7 and 2 cmp drop ;
: err cr name [ a@+ ] error name flush ;
: fexec find if drop err ; ] then	
: found cfa exec ;
: wfrom - here + dup - here + ;
: save wfrom 3 write drop ;
: nop ;
: next @a @ ;
: ;? next [ a@+ ; ] cmp drop ;

% ( Shared compile words )
: name ( n- ) hold name
: 4a+ ( - ) advance a by 4
: ?compile ( c- ) use in ?compile if do-other do-compile ...
: err ( w- ) print error on word
: fexec ( cw-a ) find word in the vocabulary, exec if found
: found ( a- ) execute found word
: wfrom ( a-an ) push on stack distance between address and here
: save ( a- ) write to stream 3 from address to here
: nop ( - ) do nothing
: ;? ( - ) flag if semicolon follows
;
% 