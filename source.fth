% ( boot load page )
: ld cr #x5d hold dup nr #x5b hold flush load ;
: ;s a! ;
: empty dhere [ #x30010 ] @ ! ; ( word is first )
cr ( This page is read after source blocks are loaded )
cr #x1 ld ( nr macros )
cr #x2 ld ( macros )
cr #x3 ld ( x86 )
cr #x4 ld ( conditionals )
cr #x5 ld ( constants )
cr #x6 ld ( boot )
cr 0 bye
% nrmacros empty ( x86 boot )
: +s #xc083 2c,n ;
: + #x05 c,, ;
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
: reg! 11 shl #x038b + 2c, ;
: ldreg 11 shl #xc089 + 2c, ;
: pop #x58 +s c, ;
: push #x50 +s c, ;
;s
% macros empty ( x86 boot )
: ; #xc3 c, ;
: over+ #x044303 3c, ;
: nip 4 ,+stack ;
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
: /and/ #x44323 3c, ;
: /or/ #x4430b 3c, ;
: da@+ #x78b 2c, #x47f8d 3c, ;
: da! #xc789 2c, ; ( dup a! ) 
: tocl #xc189 2c, ;
;s
% forth ( x86 boot )
: - - ;
: eax 0 ; : ecx 1 ; : edx 2 ; : ebx 3 ;
: esp 4 ; : ebp 5 ; : esi 6 ; : edi 7 ; 
: r. [ edx ] pop [ eax ] pop [ edx ] push ;
: dropdup #x038b 2c, ;
: break break ;

;s
% macros ( Conditionals jumps and find )
: testeax #xc085 2c, ;
: if #x75 2c, here ;
: -if #x78 2c, here ;
: then dup raddr - over 1- c! drop ; 
: jne a@+ known? if 5 bye then relcfa -if
-2 +s #x75  c, c, ; ] then -6 +s #x850f 2c, , ;
cr forth
;s
% forth ( boot constants )
: reg 2 shl #x30000 + ;
: 0var dhere 0 w, ;
: voc! [ 4 reg ] ! ;
0var ( sys vocabulary )
: sys a@+ [ dup ] @ find if drop err ; ] then cfa exec ;
voc! empty 
: regs #x30000 ; ( registers start here )
cr ( syscall index x86 )
: write 4 ;
: exit 1 ;
: read 3 ;
: open 5 ;
: ioctl 54 ;
cr 
: linux 3 ; ( elf cpu )
: le 1 ; ( elf endian )
;s
% forth ( noarch boot )
: and /and/ nip ;
: or /or/ nip ;
: xor /xor/ nip ;
: + over+ nip ;
: +blk @a [ 0 buffer - ] + 9 lsr + ;
: initp r. r. 2 shl 28 +s ld compile ; ( no parameter - 32, one par - 36 )
cr dup initp
;s

% ( unused )
% ( forth x86 core basic words )
: over dup 8 nth ;
: dup dup ;
: drop nip [ eax ] reg! ;
: 2dup over over ;
: 2drop nip drop ;
: c! nip [ ecx ] reg! !cl drop ;
: ! nip [ ecx ] reg! !ecx drop ;
: shl tocl drop 0 ,rot ;
: ash tocl drop 8 ,rot ; 
: @ @ ;
;s
% ( forth x86 core layout )
: voc [ 0 reg ] @ ;
: here [ 1 reg ] @ ;
: raddr [ 1 reg ] @-+ ;
: dhere [ 3 reg ] @ ;
: w, [ 3 reg ] @ ! [ 3 reg ] @ 4 +s [ 3 reg ] ! ;
: h, here w, ;

: hold [ #xdff 2c, 5 reg , ] ( decl ) [ 5 reg ] @ c! ;
: buffer 9 shl #x21000 + ;
;s
% ( forth x86 core a-reg )
: a@+ dup da@+ ;
: a! da! drop ;
: @a dup [ edi ] ldreg ;
: sys/3 [ ebx ] push /sys/ [ ebx ] pop #xc [ ,+stack ] ( nop ) ;
: write [ sys write ] sys/3 drop ;
: bye 8 [ - ,+stack ] [ sys exit ] sys/3 ;
: flush #x30000 nop [ 5 reg ] @-+ [ 5 reg ] @ 1 write
: obufset [ 5 reg ] #x30000 !! ;
;s
% ( forth x86 core printing numbers )
: digit ( n-n ) 10 / dup [ edx ] ldreg #x30 +s hold ; ( hold digit, keep /10 )
: hdigit dup #xf and 10 cmp -if 7 + then #x30 +s hold 4 lsr ; ( hold hexa digit, keep /16 )
: nrh hdigit if drop ; ] then nrh ; (  hold unsigned hexa number )
: uu digit testeax if drop ; ] then uu ; ( hold unsigned decimal number )
: nr testeax -if uu ; ] then - uu 45 hold ; ( hold signed decimal number )
: bl 32 hold ; : cr 10 hold ;
: . bl nrh flush ; ( print hexa unsigned digit )
;s
% ( forth noarch core printing names )
: sizeflag dup 30 ash 3 and ;
: size #x7050404 over 3 shl ash #x7f and ;
: offset [ #x161f000 4 shl ] over 3 shl ash #x7f and 3 shl ;
: uncode #x3f and #x20080 + @ #x7f and hold ;
: dname -8 and 
: decode sizeflag offset
[ eax ] push drop size nip 2dup - 32 + ash dup [ eax ] pop over+ nip
uncode shl if drop ; ] then decode ;
;s
% ( forth x86 core heap )
: , [ 1 reg ] @ !
  [ 1 reg ] @ 4 + [ 1 reg ] ! ;
: dc,s [ #x358b 2c,
  1 reg , #x0688 2c,
  #x46 c, #x3589 2c, 1 reg ,
  ] 8 ash ;
: c, dc,s drop ;
: c,, c, , ;
: find ( wv-af ) testeax if ; ( w0 ) ] then
: floop 2dup 4 +@ /xor/ -8 and 2drop if nip testeax ; ] then
dup @ testeax if nip ; ] then - over+ nip floop ;
: cfa 8 +@ ;
: known? voc find ;

: relcfa cfa raddr -126 cmp ;
: ,call #xe8 c, cfa raddr -4 + , ; 
: doj relcfa -if -2 + #xeb c, c, ; 
] then -5 + #xe9 c,, ; 

: vexec @ : exec [ eax ] push drop ;
;s
% ( forth core output/finds )
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

;s
% ( forth x86 core calls )
: doj relcfa -if -2 + #xEB c, c, ; ] then -5 + #xE9 c,, ;
: call ;? if 4a+ doj ; ] then ,call ;
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
% ( forth core compiler )
: tagidx dup #x7 and 2 shl ;
: compi a@+ flush tagidx #x20060 + vexec ;

cr dhere #x20060 base @ - + 3 reg !
cr h, there ( ignore word ) ] drop compi ; cr
h, there ( yellow nr ) ] 4 ash next cnr compi ; cr
h, ( compile word ) ] cw compi ;
cr h, ( define word ) ] dbg
  dhere [ 4 reg ] @ @ - over+
  w, [ 4 reg ] @ ! w, here w, compi ; cr
over dup w, w, ( ignore twice )
cr w, ( yellow nr ) drop 
cr h, ( yellow word ) ] [ 0 reg ] @ fexec next cnr compi ;
3 reg !

;s
% ( boot block )
: sread [ sys read ] sys/3 ;
: load buffer @a over a! nip ;
: openr 0 dup here [ sys open ] sys/3 ;
: nrmacros [ 4 reg 6 reg ] !! ;
: macros [ 4 reg 2 reg ] !! ;
: forth [ 4 reg 0 reg ] !! ; 
;s
% ( unused )
% forth ( noarch compiler )
: allot here + [ 1 reg ] ! ;
: @,+ dup @ , 4 +s ; 
: ,16 @,+ @,+ @,+ @,+ ;
: cpchars #x20080 ,16 ,16 ,16 drop ;
: vexec @ : exec [ eax ] push drop ;
;s
% ( unused )
% nrmacros ( x86 crosscompiler )
: ,rot 8 shl #xe0d3 + 2c, ;
: drop 4 ,+stack dropdup ;
: ! #xa3 c,, 4 ,+stack dropdup ;
: !! #xb9 c,, #x0d89 2c, , ;
;s
% forth ( crosscompiler heaps )
: base [ 0var ] ;
: dbase [ 0var ] ;
: dthere [ dbase ] @ dhere + ;

: rfloop 2dup 4 +@ /xor/ -8 and 2drop if nip testeax ; ] then
dup @ testeax if nip ; ] then - + rfloop ;
: cfa 8 +@ [ base ] @-+ ;

: target [ 0var dup ] voc! ;
: known? [ nop ] @ rfloop ;
: there [ base ] @ here + ;
: h, there w, ; ;s
% forth ( croscommpiler saving )

: wfrom - here + dup - here + ;
: save wfrom 4 write ;
: dfrom - dhere + dup - dhere + ;
: dsave dfrom 4 write ;
: mark here - #x20054 + base ! dhere - dbase ! dhere here ;
: dump save dsave ;
;s

cr (search in offsetted words )
;
% 
% ( elf headers )
: elfw, 2c, ;
: elf, , ; ( save long in elf order )
: +base, #x20000 + elf, ;
: ident
#x4c457f 3c, #x46 c, ( elf )
1 c, [ sys le ] c, #x0301 2c, 0 , 0 , ;
: filehdr 2 elfw, [ sys linux ] elfw, ( et_exec )  1 elf, ( ev_current )
elf, ( start ) #x34 elf, ( ph-addr )
0 elf, ( no sections ) #x1001 elf, ( no flags )
#x34 elfw, ( hsize ) #x20 elfw, ( phentsize )
1 elfw, ( phnum ) #x28 elfw, ( shentsize )
0 , ( sects ) ;
: proghdr
1 , ( pload ) 
#x54 dup elf, dup +base, +base, ( offset p-vaddr p-addr )
elf, ( size )
#x100ac elf, ( memory size ) 
7 elf,  ( flags rwx )
#x1000 elf, ( align )
;
% 
: init here
there ident dup . filehdr
: heap! dup save [ 1 reg ] ! ;
: edump here there dthere + [ #x20054 - ] + proghdr
heap! ;

;s
: base ( - ) convert file address to real one
: ident ( - ) physical header ;
: filehdr ( a- ) file header. Uses relative offset of start. ;
: proghdr ( s- ) program header. Takes size. ;
% ( redefine function calls, using offset )
: relcfa cfa raddr -126 cmp ;
: ,call #xE8 c, cfa raddr -4 + , ;
: doj relcfa -if -2 + #xEB c, c, ; ] then -5 + #xE9 c,, ;
: call ;? if 4a+ doj ; ] then ,call ;
: cw imm? jne found drop known? jne call drop err ;
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
% ( forth noarch core crosscompiler dispatch table )
dhere cr
h, here ( ignore word ) ] drop ; cr
h, here ( yellow nr ) ] 4 ash next cnr ; cr
h, ( compile word ) ] cw ;
cr h, ( define word ) ] dbg
  dhere [ 4 reg ] @ @ - over+
  w, [ 4 reg ] @ ! w, there w, ; cr
over dup w, w, ( ignore twice )
cr w, ( yellow nr ) drop
cr h, ( yellow word ) 0 reg ] @ fexec next cnr ;
: tagidx dup #x7 and 2 shl ;
: cword tagidx [ nop ] + vexec ;
;s
% ( Compile single word. cr
the table of functions is patched back after function is created. cr
all function expect the code on input cr
( define ) load 
[
% ( compile block )
: compi a@+ @a 23 shl drop
  if @a #x200 + a! then cword compi ;
: wfrom - here + dup - here + ;
: save wfrom 3 write drop ;
;s
% ( comment block )
: compile ( w- ) compile word and advance
: load ( b- ) save address, load block, continue
[
% ( load pages to rebuild app )
cr #x13 ld
cr #x15 ld
cr #x16 ld ( search )
cr #x17 ld ( search )
cr #x18 ld ( search )
cr #x1a ld ( elf )
cr #x1c ld ( compiler )
cr #x1e ld ( compiler )
cr target mark compile
cr #x22 ld ( generated code )
cr edump dump flush
;s
% ( rebuild app )
: ld load reporting progress [
: cpchars copy character table from master [
% ( init code )
cr empty
cr 0 , ( last ) 0 , 0 , ( align )
cr 32 allot ( compiler handling table )
cr cpchars
cr #x8 ld #x9 ld #x0a ld #x0b ld #x0c ld #x0d ld #x0e ld #x0f ld #x10 ld #x11 ld
cr init
#xbb c, #x30100 , ( stack )
[ cr ] #x20054 @ dup [ 0 reg ] !
[ cr 1 reg #x2c000 ] !!
[ cr 3 reg #x29000 ] !!
[ cr 4 reg 0 reg ] !!
[ cr ] obufset
[ cr ] 66 here ! ( file name B )
[ cr ] #x10000 nop #x21000 openr sread 0 nip load 
[ cr ] compi ;
1 allot ( align )
cr 4 reg @ @ dbase @ + there + base @ - #x20054 + ! ( save last word )
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
% ( editor )
: tcget here #x5401 nop 0 nop [ sys ioctl ] sys/3 drop ;
: tcset here #x5403 nop 0 nop [ sys ioctl ] sys/3 drop ;
tcget here 12 + @ 11 - and here 12 + ! tcset
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
    h, ( blue word ) ] known? cfa [ eax ] push drop ;
    h, ( white word ) ] nm black ; cr
    h, ( blue number ) ] 4 ash nrh blue bl ; cr
    h, ( yellow word ) ] nm yellow ;
: tagidx dup #x7 and 2 shl ;
: .code tagidx [ nop ] + vexec ;
;s
% ( comment block xxv )
% ( editor - print code blocks )
  : .@-code -4 + dup @ .code ;
  : stop dup 23 shl testeax drop ;
  : gauge stop if 4 + ; ] then -4 + dup @ testeax drop if gauge ; ] then 4 +
   dup - 2 ash #x7f and [ a@+ free ] dname bl nr black cr ; 
  : show .@-code stop if drop ; ] then show ;
  : pg cr dup buffer #x1fc + gauge black show nr bl [ a@+ page ] name top flush ;
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
cr #x1 defk ( a-bort ) ] cr flush
tcget here 12 + @ 10 or here 12 + ! tcset 0 bye ;
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
