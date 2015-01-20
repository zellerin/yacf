% ( Boot structure )
cr ( This page is read after source blocks are loaded )
cr 1 load ( nr macros )
cr 2 load ( macros )
cr 3 load ( x86 )
cr 4 load
cr 0 bye
% ( number macros )
nrmacros
0 dhere
: + [ ! ] #xc083 2c,n ;
: +l #x05 c,, ;
: +@ #x408b 2c,n ;
: @+ #x0503 dc,s c,, ;
: @-+ #x052b dc,s c,, ;
: @ ,put -4 ,+stack #xa1 c,, ;
: ash #xf8c1 2c,n ;
: lsr #xe8c1 2c,n ;
: shl #xe0c1 2c,n ;
: and #xe083 2c,n ;
: / #xbed231 3c, , #xf6f7 2c, ;
: cmp #x3d c,, ;
: nth #x08438b 2c,n ;
: nop ,lit ;
;s
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
: da! #xc789 2c, ; ( dup a! ) 
forth
: reg 2 shl #x30000 +l ;
: +blk @a [ 0 buffer - ] +l 9 lsr + ;
;s
% ( init )
forth
: r. [ edx ] pop [ eax ] pop [ edx ] push ;
: initp r. r. 2 shl 28 + load compile ; ( no parameter - 32, one par - 36 )
cr dup initp
;s
% ( unused )
% ( unused )
% ( unused )
% ( Basic words )
: over dup 8 nth ;
: + over+ nip ;
: dup dup ;
: drop nip [ eax ] reg! ;
: 2dup over over ;
: 2drop nip drop ;
: c! nip [ ecx ] reg! !cl drop ;
: ! nip [ ecx ] reg! !ecx drop ;
: shl tocl drop 0 ,rot ;
: ash tocl drop 8 ,rot ; 
: @ @ ;
: - - ;
: break break ;
;s
% ( More basic words )
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
: buffer 9 shl [ 9 reg ] @+ ;
;s
% ( A register and linux interface )
: a@+ dup da@+ ;
: a! da! drop ;
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
% ( unused )
% ( unused )
% ( Conditionals jumps and find )
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
: ffind ;
: wjump ; ( wc- ) compile short relative call to passed word
: jne ; jump to word unless zero flag set. Handles long calls.
: relcfa ; relative CFA of word on address; set NF if near
% ( Print numbers )
: digit 10 / dup [ edx ] ldreg #x30 + hold ;
: hdigit dup #xf and 10 cmp -if 7 + then #x30 + hold 4 lsr ;
: nrh hdigit if drop ; ] then nrh ; 
: uu digit testeax if drop ; ] then uu ;
: nr testeax -if uu ; ] then - uu 45 hold ;
: bl 32 hold ; : cr 10 hold ;
: . bl nrh flush ;
cr
: nop ;
;s
% ( unused )
: digit ( n-n ) hold last digit; keep nr/10
: hdigit ( n-n ) hold last hexa digit, keep nr/0x10
: nr ( n- ) hold signed decimal number
: nrh ( n- ) hold unsigned hexa number
: uu ( n- ) hold unsigned decimal number
% ( Print names )
: sizeflag dup 30 ash 3 and ;
: size #x7050404 over 3 shl ash #x7f and ;
: offset [ #x161f000 4 shl ] over 3 shl ash #x7f and 3 shl ;
: uncode #x3f and [ 10 reg ] @+ @ #x7f and hold ;
: dname -8 and 
: decode sizeflag offset
[ eax ] push drop size nip 2dup - 32 + ash dup [ eax ] pop +
uncode shl if drop ; ] then decode ;
;s
% ( Print names )
: sizeflag ( word -- word sizeflag )
: size ( sizeflag -- sizeflag size )
: offset ( sizeflag -- sizeflag offset )
: decode ( word -- word size letter )
[
% % ( Output )
: name bl dname ;
: next @a @ ;
: err cr name [ a@+ error ] name flush ;

( source reading )
: 4a+ a@+ drop ;
: ?compile #x7 and #x2 cmp drop ;
: ;? next [ a@+ ; ] cmp drop ;
: imm? [ 2 reg ] @ find ;

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
: voc! [ 4 reg ] ! ;
: target [ 0var dup ] voc! ;
: known? [ nop ] @ rfloop ;
: there [ base ] @ here + ;

( saving heap and data heap )
: wfrom - here + dup - here + ;
: save wfrom 4 write ;
: dfrom - dhere + dup - dhere + ;
: dsave dfrom 4 write ;
: mark here - #x20054 +l base ! dhere - dbase ! dhere here ;
: dump save dsave ;
;s
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
% ( elf headers )
: +base, #x20000 +l , ;
: ident
#x4c457f 3c, #x46 c, ( elf )
#x010101 , 0 , 0 , ;
: filehdr
#x30002 , ( et_exec )  1 , ( ev_current )
, ( start ) #x34 , ( ph-addr )
0 , ( no sections ) 0 , ( no flags )
#x200034 , ( header-size phentsize )
#x280001 , ( e-phnum s-shentsize )
0 , ( sects ) ;
: proghdr
1 , ( pt-load ) 
#x54 dup , dup +base, +base, ( offset p-vaddr p-addr )
, ( size )
#x100ac , ( memory size ) 
7 ,  ( flags rwx )
#x1000 , ( align )
;
: init here
there ident dup . filehdr
: heap! dup save [ 1 reg ] ! ;
: edump here there dthere + [ #x20054 - ] +l proghdr
heap! ;

;s
% ( elf )
: base ( - ) convert file address to real one
: ident ( - ) physical header ;
: filehdr ( a- ) file header. Uses relative offset of start. ;
: proghdr ( s- ) program header. Takes size. ;
% % ( redefine function calls, using offset )
: relcfa cfa raddr -126 cmp ;
: ,call #xE8 c, cfa raddr -4 + , ;
: doj relcfa -if -2 + #xEB c, c, ; ] then -5 + #xE9 c,, ;
: call ;? if 4a+ doj ; ] then ,call ;
: : cw imm? jne found drop known? jne call drop err ;
: ,lit ,put -4 ,+stack
: ,dlit testeax if #xc031 nip 2c, ; ] then #xb8 c,, ;
: ytog next [ 6 reg ] @ find if 2drop ,lit ; ] then 4a+ found ; 
: cnr ?compile if ytog then ;
: dbg dup cr name bl there nrh bl dthere nrh flush ;
nrmacros : nip ,dlit ; forth
;s
% ( comment block xv )
: relcfa ( a-o ) relative cfa for short calls ; set flag if small
: ,call ( a- ) compile call to address
: cw ( w- ) execute if immediate, compile call if in dictionary or error
: ,lit ( w-,-w ) compile call to last dup definition and ensure top is loaded
: doj ( a- ) compile short or long jump to address
: call ( a- ) ; compile call or jump (short or long)
: ytog ( n-? ) execute following numeric macro or ensure top is loaded
: cnr ( ?-? ) run ytog if green word follows
: dbg ( w-w ) print current word and position
[
% ( compiler table )
dhere cr
h, here ( ignore word ) ] drop ; cr
h, here ( yellow nr ) ] 4 ash next cnr ; cr
h, ( compile word ) ] cw ;
cr h, ( define word ) ] dbg
  dhere 4 reg @ @ - over +
  w, 4 reg @ ! w, there w, ; cr
over dup w, w, ( ignore twice )
cr w, ( yellow nr ) drop
cr h, ( yellow word ) ] 0 reg @ fexec next cnr ;
: tagidx dup #x7 and 2 shl ;
: cword tagidx [ nop ] +l vexec ;
;s
% ( Compile single word. cr
the table of functions is patched back after function is created. cr
all function expect the code on input cr
( define ) load 
[ % ( compile block )
: compi a@+ @a 23 shl drop
  if @a #x200 +l a! then cword compi ;
: wfrom - here + dup - here + ;
: save wfrom 3 write drop ;
;s
% ( comment block )
: compile ( w- ) compile word and advance
: load ( b- ) save address, load block, continue
[ % 
% ( rebuild app )
cr #x0e load ( conditionals )
cr #x10 load ( numbers )
: ld bl #x5d hold dup nr #x5b hold flush load ;
cr 52 ld 
cr #x12 ld ( names )
cr #x14 ld ( output )
cr #x16 ld ( search )
cr #x18 ld ( search )
cr #x1a ld ( elf )
cr #x1c ld ( compiler )
cr #x1e ld ( compiler )
: allot here + 1 reg ! ;
: oreg reg ;
: h, there dup . w, ;
: reg 2 shl #x30000 +l ;
: @,+ dup @ , 4 + ;
: ,16 @,+ @,+ @,+ @,+ ;
: cpchars 10 oreg @ ,16 ,16 ,16 drop ;
cr target mark compile
cr #x22 ld ( generated code )
cr edump dump flush
;s
% ( rebuild app )
: ld load reporting progress [
: cpchars copy character table from master [
% 
cr dhere 4 oreg @ !
cr 0 , ( last ) 0 , 0 ,
32 allot
cpchars
cr #x08 ld 9 ld #x0a ld #x10 ld #x12 ld 54 ld
#x14 ld 56 ld 58 ld 60 ld
cr init
#xbb c, #x30100 ,
] #x30000 dup !iobuf [ 8 reg ] !
[ 10 reg #x20080 ] !!
[ 9 reg #x21000 ] !!
[ 3 reg #x29000 ] !!
[ 1 reg #x2c000 ] !!
#x20054 @ dup [ 0 reg ] !
[ 4 reg 0 reg ] !!
0 hold 66 hold
#x10000 nop #x21000
openr obufset
sread drop
0 load
compi ;
1 allot
4 oreg @ @ dbase @ + there + base @ - #x20054 + !
;s
% ( init code )
cr ensure last links is 0
cr place for latest word
: over insert again word below top [
cr basic words
cr a-words
cr numbers
cr init
cr stack top to ebx
cr set iobuf and its end
cr print #x12
cr fixt latest pointer
% % ( editor )
#x0e load ( conditionals )
#x10 load ( numbers )
: ld bl #x5d hold dup nr #x5b hold flush load ;
52 ld
#x12 ld ( names )
#x14 ld ( output )
#x16 ld ( search )
#x18 ld ( search )
2 +blk load ( ansi color )
4 +blk load ( editor )
6 +blk load ( editor 2 )
8 +blk load ( keys )
10 +blk load ( number keys )
12 +blk load ( number keys? )
a@+ ---- view
% ( editor )
% ( editor - ANSI coloured output. ) 
: hld/ dup #xff and hold 8 ash if drop ; ] then hld/ ;
: fg 109 hold hold #x1b5b33 hld/ ;
: top #x1b5b4a hld/ #x3b3166 hld/ #x1b5b31 hld/ ;
: blue 52 fg ; : green 50 fg ;
: yellow 51 fg ; : red 49 fg ;
: black 48 fg ; ( when white background )
: black 57 fg ; cr
;s
% ( Individual color words )
% ( editor - Print individual token categories )
: nm dname bl ;
dhere ( address of table ) cr
    h, ( continued word ) ] dname ; cr
    h, ( yellow number ) ] 4 ash nr yellow bl ; cr
    h, ( green word ) ] nm green ; cr
    h, ( red word ) ] nm red cr ; cr
    h, ( blue word ) ] ffind cfa [ eax ] push drop ;
    h, ( white word ) ] nm black ; cr
    h, ( blue number ) ] 4 ash nrh blue bl ; cr
    h, ( yellow word ) ] nm yellow ;
: tagidx dup #x7 and 2 shl ;
: .code tagidx [ nop ] +l vexec ;
;s
% ( comment block xxv )
% ( editor - print code blocks )
  : .@-code -4 + dup @ .code ;
  : stop dup 23 shl testeax drop ;
  : gauge stop if 4 + ; ] then -4 + dup @ testeax drop if gauge ; ] then 4 +
   dup - 2 ash #x7f and [ a@+ free ] dname bl nr black cr ; 
  : show .@-code stop if drop ; ] then show ;
  : pg cr dup buffer #x1fc +l gauge black show nr bl [ a@+ page ] name top flush ;
;s
%
: .@-code ( n-n ) print code, decrease addr )
% ( key driven actions )
: vock [ 0var ] ;
: map [ 0var ] ; vock map !
: key 4 here 0 over ! 0 sread here nip @ ;
: fkey 4 shl map @ @ find ;
: defk map @ @ dhere map @ ! - dhere + dup . w, 4 shl w, here w, ;
: !blk [ 0var dup ] ! ; 24 !blk
: @blk [ nop ] @ ;
: err [ 0var dup ] @ exec ;
: !err [ nop ] ! ;
: exekey key fkey if
: undef drop 4 ash dup nrh bl hold [ a@+ undef ] name err ; ] then cfa exec ;
: .many dup nrh dup bl nr bl nm cr ;
: state 2dup .many .many [ a@+ stack ] name cr flush ;
cr here !err 

: view @blk pg state exekey ;
;s
%
: vock keys vocabulary
: map current map to use
: key ( -c ) read 4 chars return as word
: fkey ( c-a ) find word in vock
: defk ( c- ) code for char starts here
: !blk ( b- ) set curent block
: @blk ( -b ) read current block
: err ( - ) execute error routine. Should not return.
: !err ( a- ) set error routine
: exekey ( - ) read key and execute associated action
: view ( - ) display page and read/execute keys. does not return
[ % ( editor - simple keys )
dhere vock !
cr #x1 defk ( a-bort ) ] cr flush 0 bye ;
cr #x6 defk ( f-orward ) ] @blk 1 + !blk view ;
cr #x2 defk ( b-ackward ) ] @blk 1- !blk view ;
cr #x4 defk ( d-rop ) ] drop view ;
;s
% ( editor - simple keys )
% ( editor - numbers )
: defdigit #x30 defk #x31 defk #x32 defk #x33 defk #x34 defk [ cr ] #x35 defk
#x36 defk #x37 defk #x38 defk #x39 defk ;
: digk [ 0var ] ; digk map !
defdigit ( in digit  ) ] 4 shl here @ -48 + + view ;
cr #x61 defk #x62 defk #x63 defk #x64 defk #x65 defk #x66 defk
( hexa digit ) ] 4 shl here @ -87 + + view ;
cr #x70 defk ( p-age ) ] !blk [
cr #x20 defk ( go back ) ] vock map ! view ;
vock map !  
cr defdigit ( 0-9 ) ] here @ -48 + digk map ! view ;
;s
% ( editor - numbers )
% ( editor - symbols )
here 
cr #x20 defk ( go back ) ] vock map ! view ;
cr #x27 defk ( single quote ) ] key #x7f and -32 + view ;
;s
% ( editor - symbols )
% ( Better x86 macros )
: dropdup #x038b 2c, ;
macros
: tocl #xc189 2c, ;
nrmacros
: ,rot 8 shl #xe0d3 +l 2c, ;
: drop 4 ,+stack dropdup ;
: ! #xa3 c,, 4 ,+stack dropdup ;
: !! #xb9 c,, #x0d89 2c, , ;
forth
;s
% ( Better x86 macros )
% ( Heap )
: , [ 1 reg ] @ !
  [ 1 reg ] @ 4 + [ 1 reg ] ! ;
: dc,s [ #x358b 2c,
  1 reg , #x0688 2c,
  #x46 c, #x3589 2c, 1 reg ,
  ] 8 ash ;
: c, dc,s drop ;
: c,, c, , ;
: find ( wv-af ) testeax if ; ( w0 ) ] then
: floop 2dup 4 + @ xor -8 and drop if nip testeax ; ] then
dup @ testeax if nip ; ] then - + floop ;
: cfa 8 +@ ;
: ffind  ( w-af ) voc find ; ( find word in dictionary )

: relcfa cfa raddr -126 cmp ;
: ,call #xe8 c, cfa raddr -4 + , ; 
: doj relcfa -if -2 + #xeb c, c, ; 
] then -5 + #xe9 c,, ; 

: vexec @ : exec [ eax ] push drop ;
;s
% ( foo )
% ( bar )
: doj relcfa -if -2 + #xEB c, c, ; ] then -5 + #xE9 c,, ;
: call ;? if 4a+ doj ; ] then ,call ;
: known? voc find ;
: imm? [ 2 reg ] @ find ;

: cw imm? if drop known?
  if drop err ; ] then call ;
   ] then cfa exec ;
: 2c, dc,s c, ;
: 3c, dc,s 2c, ;
: 2c,n 2c, c, ;
: ,put #x0389 2c, ;
: ,+stack #x5b8d 2c,n ;
: ,lit ,put -4 ,+stack #xb8 c,, ;
: ytog next [ 6 reg ] @ find if 2drop ,lit ; ] then 4a+ found ; 
: cnr ?compile if ytog then ;
: dbg dup cr name bl here nrh bl dhere nrh flush ;

;s
% ( Heap )
% ( compiler table )
: tagidx dup #x7 and 2 shl ;
: compi a@+ flush tagidx #x20060 +l vexec ;

dhere #x20060 base @ - + dup . 3 oreg !
h, there ( ignore word ) ] drop compi ; cr
h, there ( yellow nr ) ] 4 ash next cnr compi ; cr
h, ( compile word ) ] cw compi ;
cr h, ( define word ) ] dbg
  dhere [ 4 reg ] @ @ - over +
  w, [ 4 reg ] @ ! w, here w, compi ; cr
over dup w, w, ( ignore twice )
cr w, ( yellow nr ) drop 
cr h, ( yellow word ) ] [ 0 reg ] @ fexec next cnr compi ;
3 oreg !

;s
% ( Compile single word. cr
the table of functions is patched back after function is created. cr
all function expect the code on input cr
( define ) load 
% ( boot block )
: sread 3 sys/3 ;
: load buffer @a over a! nip ;
: ;s a! ;
: openr 0 dup iobuf 5 sys/3 ;
: nrmacros [ 4 reg 6 reg ] !! ;
: macros [ 4 reg 2 reg ] !! ;
: forth [ 4 reg 0 reg ] !! ; 
;s
% ( comment block )
: compile ( w- ) compile word and advance
: load ( b- ) save address, load block, continue
: +blk ( -a ) Address of the next block ;
: ... load next block [
% 

