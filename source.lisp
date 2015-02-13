(defpackage forth-source
  (:nicknames #:fs)
  (:use #:cl)
  (:documentation "Package with utilities to make a source for yacf.

Terminology to keep:
- encode converts source text (Lisp objects, now; text, previously) to WORDs
- compile converts the WORDs to binary objects (in yacf)"))

(defpackage forth-expanders
  (:nicknames #:fe)
  (:use)
  (:documentation "Package for names of functions that expand yacf sources."))

(in-package forth-source)

(deftype word ()
  "32-bit word.
Interpretation depends on its (ldb (byte 3 0)):
0 - comment, ignored
1 - decimal number
2 - encoded word to compile
3 - encoded word to define
4 - editor word
5 -
6 - hexa number
7 - word to execute"
  '(unsigned-byte 32))

(defun encode-number (output nr &optional (flag 6))
  "Convert a number to the WORD. By default, use flag for decimal"
  (declare ((member 1 6) flag)
	   ((vector word) output)
	   ((signed-byte 29) nr))
  (vector-push (dpb nr (byte 28 4) flag) output))

(defun encode-word (output word type)
  "Encode one word into output, using type as a flag.
Depending on length of the word, it may put on or more elements in
output.

Current code is almost verbatim rewrite from C. Cleanup desirable.
"
  (declare (symbol word)
	   (vector output) ; with fill pointer
	   ((integer 0 7) type))
  (with-input-from-string (out (symbol-name word))
    (loop
       with word = 0
       and shift = 3
       and letter-codes
	 = (load-time-value
	    (make-array 96 :element-type '(unsigned-byte 8)
			:initial-contents
			;; Translation table for char codes. Contains the length
			;; indicator (ldb (byte 2 6)) and value in (ldb (byte 6
			;; 0)).  Originally calculated, now placed here
			;; verbatim from original C source
			#(#x00 #xfa #x00 #x00 #x00 #x00 #x00 #x00
			  #x00 #x00 #xfd #xfb #xfe #xf3 #xf5 #xf7
			  #xf4 #xf2 #xf6 #xeb #xec #xed #xee #xef
			  #xf0 #xf1 #xf9 #xf8 #x00 #x00 #x00 #xff
			  #xfc #x05 #xe3 #x52 #xe0 #x04 #x56 #x55
			  #xe4 #x07 #xea #xe8 #x54 #x51 #x06 #x03
			  #xe2 #xe7 #x01 #x50 #x02 #xe6 #xe1 #x57
			  #xe5 #x53 #xe9 #x00 #x00 #x00 #x00 #x00
			  #x00 #x05 #xe3 #x52 #xe0 #x04 #x56 #x55
			  #xe4 #x07 #xea #xe8 #x54 #x51 #x06 #x03
			  #xe2 #xe7 #x01 #x50 #x02 #xe6 #xe1 #x57
			  #xe5 #x53 #xe9 #x00 #x00 #x00 #x00 #x00))
	    t)
       for letter = (- (char-code (read-char out nil #\Space)) 32)
       while (plusp letter)
       for size-code = (aref letter-codes letter)
       for size = (+ 4 (ldb (byte 2 6) size-code))
       when (> (+ size shift) 32 )
       do
	 (vector-push (+ type (ash word (- 32 shift)))
		       output)
	 (setq word 0 shift 3 type 0)
       do
	 (setf (ldb (byte size shift) word)
	       size-code)
	 (incf shift size)
       finally (vector-push (+ type (ash word (- 32 shift))) output))))

(defun encode-list (output default-symbol list)
  "Encode a lisp list.

Symbols are encoded with default-symbol flag.
Numbers are encoded as hexa if positive, decimal if negative.
Conses call function in FE package named by their cons, if available.
[ ] change encoding of following symbols.
CR is treated specifically for compatibility purposes
(exit) causes return with T
"
  (loop for i in list
     do (etypecase i
	  ((eql cr) (encode-word output i
				 (if (= default-symbol 2)
				     default-symbol 4)))
	  ((eql [) (setq default-symbol 7))
	  ((eql ]) (setq default-symbol 2))
	  ((cons (eql exit)) (return-from encode-list t))
	  ((integer * -1) (encode-number output i 1))
	  ((integer 0) (encode-number output i))
	  (symbol (encode-word output i default-symbol))
	  (cons (encode-cons output i)))))

(defun fe::defun (output word &rest code)
  "Define word as sequence of code, terminate by |;|."
  (encode-word output word 3)
  (unless (encode-list output 2 code)
    (encode-word output '|;| 2)))

(defun fe::def-top-op (output word code &optional asm)
  "Define word that makes an 2byte operation followed by number"
  (declare (ignorable asm))
  (fe::defun output word code '|2c,n|))

(defun fe::-if-exit (output &rest if)
  "Encode terminal if sequence."
  (encode-list output 2 `(-if ,@if |;| then)))

(defun encode-cons (output item)
  (case (car item)
    (dec (encode-number output (second item) 1))
    (cmt (mapcar (lambda (a) (encode-word output a 5))
		 (cdr item)))
    (t (apply (or
	       (find-symbol (symbol-name (car item)) 'fe)
	       (error "No fe function ~s" (car item)))
	      output (cdr item)))))

(defmacro with-page (name options &body body)
  (declare (ignorable options name))
  `(let ((output (make-array 512
			     :element-type 'word
			     :fill-pointer 0)))
     (encode-list output 7 ',body)
     (setf (fill-pointer output) 128)
     output))

(defmacro make-raw (&body body)
  `(with-open-file (out "raw" :direction :output
		     :if-does-not-exist :create
		     :if-exists :overwrite
		     :element-type '(unsigned-byte 32))
     ,@(mapcar (lambda (page)
		 `(write-sequence
		   (with-page foo ()
		     ,@page)
		   out))
	       body)))


(make-raw
  ((cmt boot load page)
   (defun ld cr #x5d hold dup nr #x5b hold flush load)
   (defun |;s| |a!|)
   (defun empty dhere #x30010 @ !) (cmt word is first)
   cr (cmt this page is read after source blocks are loaded)
   cr 1 ld (cmt nr macros)
   cr 2 ld (cmt macros)
   cr 3 ld (cmt x86)
   cr 4 ld (cmt conditionals)
   cr 5 ld (cmt constants)
   cr 6 ld (cmt boot)
   cr (dec 0) bye)

  (nrmacros empty (cmt x86 boot)
   (defun +s #xc083 |2c,n|)
   (defun + #x05 |c,,|)
   (defun +@ #x408b |2c,n|)
   (defun @+ #x0503 |dc,s| |c,,|)
   (defun @-+ #x052b |dc,s| |c,,|)
   (defun @ |,put| -4 |,+stack| #xa1 |c,,|)
   (def-top-op ash #xf8c1)
   (def-top-op lsr #xe8c1)
   (def-top-op shl #xe0c1)
   (def-top-op and #xe083)
   (defun / #xbed231 |3c,| |,| #xf6f7 |2c,|)
   (defun cmp #x3d |c,,|)
   (def-top-op nth #x08438b)
   (defun nop |,lit|)
   (defun reg! (dec 11) shl #x038b + |2c,|)
   (defun ldreg (dec 11) shl #xc089 + |2c,|)
   (defun pop #x58 +s |c,|)
   (defun push #x50 +s |c,|)
   |;s|)

  (macros empty (cmt x86 boot )
   (defun |;| #xc3 |c,|)
   (defun over+ #x044303 |3c,|)
   (defun nip (dec 4) |,+stack|)
   (defun !cl #x0888 |2c,|)
   (defun !ecx #x0889 |2c,|)
   (defun break (dec 204) |c,|)
   (defun @ #x8b |2c,|)
   (defun - #xd8f7 |2c,|)
   (defun 1- (dec 72) |c,|)
   (defun dup |,put| -4 |,+stack|)
   (defun /sys/ #x0c538b |3c,| #x084b8b |3c,|
	  #x045b8b |3c,| #x80cd |2c,|)
   (defun /xor/ #x44333 |3c,|)
   (defun /and/ #x44323 |3c,|)
   (defun /or/ #x4430b |3c,|)
   (defun da@+ #x78b |2c,| #x47f8d |3c,|)
   (defun da! #xc789 |2c,|) (cmt dup a!)
   (defun tocl #xc189 |2c,|)
   |;s|)

  (forth (cmt x86 boot )
	 (defun - - )
	 (defun eax (dec 0))
	 (defun ecx (dec 1))
	 (defun edx (dec 2))
	 (defun ebx (dec 3))
	 (defun esp (dec 4))
	 (defun ebp (dec 5))
	 (defun esi (dec 6))
	 (defun edi (dec 7))
	 (defun r. [ edx ] pop [ eax ] pop [ edx ] push)
	 (defun dropdup #x038b |2c,|)
	 (defun break break)
	 |;s|)

  (macros (cmt conditionals jumps and find )
	  (defun testeax #xc085 |2c,|)
	  (defun if #x75 |2c,| here)
	  (defun -if #x78 |2c,| here)
	  (defun then dup raddr - over 1- c! drop)
	  (defun jne a@+ known? if (dec 5) bye then relcfa
		 (-if-exit -2 +s #x75 |c,| |c,|)
		 -6 +s #x850f |2c,| |,|)
	  cr forth
	  |;s|
	  )
  (forth (cmt boot constants )
	 (defun reg (dec 2) shl #x30000 +)
	 (defun 0var dhere (dec 0) |w,|)
	 (defun voc! [ (dec 4) reg ] !)
	 0var (cmt sys vocabulary )
	 (defun sys a@+ [ dup ] @ find if drop err |;| then cfa exec)
	 voc! empty
	 (defun regs #x30000) (cmt registers start here )
	 cr (cmt syscall index x86 )
	 (defun write (dec 4))
	 (defun exit (dec 1))
	 (defun read (dec 3))
	 (defun open (dec 5))
	 (defun ioctl (dec 54))
	 cr
	 (defun linux (dec 3)) (cmt elf cpu )
	 (defun le (dec 1)) (cmt elf endian )
	 |;s|)

  (forth (cmt noarch boot )
	 (defun and /and/ nip)
	 (defun or /or/ nip)
	 (defun xor /xor/ nip)
	 (defun + over+ nip)
	 (defun +blk @a [ (dec 0) buffer - ] + (dec 9) lsr +)
	 (defun initp r. r. (dec 2) shl (dec 28) +s ld compile)
	 (cmt no parameter - |x32,| one par - x36)
	 cr dup initp
	 |;s|)
  ((cmt unused))
  ((cmt forth x86 core basic words )
   (defun  over dup (dec 8) nth)
   (defun  dup dup)
   (defun  drop nip [ eax ] reg!)
   (defun  2dup over over)
   (defun  2drop nip drop)
   (defun  c! nip [ ecx ] reg! !cl drop)
   (defun  ! nip [ ecx ] reg! !ecx drop)
   (defun  shl tocl drop (dec 0) |,rot|)
   (defun  ash tocl drop (dec 8) |,rot|)
   (defun  @ @)
   |;s|)

  ((cmt forth x86 core layout)
   (defun  voc [ (dec 0) reg ] @ )
   (defun  here [ (dec 1) reg ] @ )
   (defun  raddr [ (dec 1) reg ] @-+ )
   (defun  dhere [ (dec 3) reg ] @ )
   (defun  |w,| [ (dec 3) reg ] @ ! [ (dec 3) reg ] @ (dec 4) +s [ (dec 3) reg ] ! )
   (defun  |h,| here |w,| )

   (defun  hold [ #xdff |2c,| (dec 5) reg |,| ] (cmt decl ) [ (dec 5) reg ] @ c! )
   (defun  buffer (dec 9) shl #x21000 + )
   |;s|)

 ((cmt forth x86 core a-reg )
   (defun a@+ dup da@+ )
   (defun a! da! drop )
   (defun @a dup [ edi ] ldreg )
   (defun sys/3 [ ebx ] push /sys/ [ ebx ] pop #xc [ |,+stack| ] (cmt nop ) )
   (defun write [ sys write ] sys/3 drop )
   (defun bye (dec 8) [ - |,+stack| ] [ sys exit ] sys/3 )
   (defun flush #x30000 nop [ (dec 5) reg ] @-+ [ (dec 5) reg ] @ (dec 1) write (exit))
   (defun obufset [ (dec 5) reg ] #x30000 !! )
   |;s|)
 
 ((cmt forth x86 core printing numbers )
   (defun digit (cmt n-n ) (dec 10) / dup [ edx ] ldreg #x30 +s hold )
    (cmt hold |digit,| keep /10 )
   (defun hdigit dup #xf and (dec 10) cmp -if (dec 7) + then #x30 +s hold (dec 4) lsr )
   (cmt hold hexa |digit,| keep /16 )
   (defun nrh hdigit if drop |;| ] then nrh ) (cmt  hold unsigned hexa number )
   (defun uu digit testeax if drop |;| ] then uu ) (cmt hold unsigned decimal number )
   (defun nr testeax -if uu |;| ] then - uu (dec 45) hold ) (cmt hold signed decimal number )
   (defun bl (dec 32) hold )
   (defun cr (dec 10) hold )
   (defun |.| bl nrh flush )
   (cmt print hexa unsigned digit)
  |;s|)

 (
  (cmt forth noarch core printing names )
  (defun sizeflag dup (dec 30) ash (dec 3) and )
  (defun size #x7050404 over (dec 3) shl ash #x7f and )
  (defun offset [ #x161f000 (dec 4) shl ] over (dec 3) shl ash #x7f and (dec 3) shl )
  (defun uncode #x3f and #x20080 + @ #x7f and hold )
  (defun dname -8 and (exit))
  (defun decode sizeflag offset
	 [ eax ] push drop size nip 2dup - (dec 32) + ash dup [ eax ] pop over+ nip
	 uncode shl if drop |;| ] then decode )
  |;s|)

 (
  (cmt forth x86 core heap )
  (defun |,| [ (dec 1) reg ] @ !
	 [ (dec 1) reg ] @ (dec 4) + [ (dec 1) reg ] ! )
  (defun |dc,s| [ #x358b |2c,|
	 (dec 1) reg |,| #x0688 |2c,|
	 #x46 |c,| #x3589 |2c,| (dec 1) reg |,|
	 ] (dec 8) ash )
  (defun |c,| |dc,s| drop )
  (defun |c,,| |c,| |,| )
  (defun find (cmt wv-af ) testeax if ) (cmt w0 ) ] then
  (defun floop 2dup (dec 4) +@ /xor/ -8 and 2drop if nip testeax |;| ] then
	 dup @ testeax if nip |;| ] then - over+ nip floop )
  (defun cfa (dec 8) +@ )
  (defun known? voc find )
  
  (defun relcfa cfa raddr -126 cmp )
  (defun |,call| #xe8 |c,| cfa raddr -4 + |,| ) 
  (defun doj relcfa (-if-exit -2 + #xeb |c,| |c,|)
	 -5 + #xe9 |c,,| )
  
  (defun vexec @ (exit))
  (defun exec [ eax ] push drop)
  [ |;s|) ; why [?

 (
  (cmt forth core output/finds )
  (defun name bl dname )
  (defun next @a @ )
  (defun err cr name [ a@+ error ] name flush )
  
  (cmt source reading )
  (defun 4a+ a@+ drop )
  (defun ?compile #x7 and #x2 cmp drop )
  (defun |;?| next [ a@+ ] |;| cmp drop)
  (defun imm? [ (dec 2) reg ] @ find )
  
  (cmt vocabulary searches )
  (defun fexec find if drop err |;| ] then (exit))
  (defun found cfa exec )
  
  (cmt compiling targets )
  
  |;s|)

 (
  (cmt forth x86 core calls)
  (defun doj relcfa (-if-exit -2 + #xEB |c,| |c,|) -5 + #xE9 |c,,|)
  (defun call |;?| if 4a+ doj |;| then |,call|)
  (defun imm? [ (dec 2) reg ] @ find )
  
  (defun cw imm? if drop known?
	 if drop err |;| then call |;|
	 then cfa exec )
  (defun |2c,| |dc,s| |c,| )
  (defun |3c,| |dc,s| |2c,| )
  (defun |2c,n| |2c,| |c,| )
  (defun |,put| #x0389 |2c,| )
  (defun |,+stack| #x5b8d |2c,n| )
  (defun |,lit| |,put| -4 |,+stack| #xb8 |c,,| )
  (defun ytog next [ (dec 6) reg ] @ find if 2drop |,lit| |;| then 4a+ found )
  (defun cnr ?compile if ytog then )
  (defun dbg dup cr name bl here nrh bl dhere nrh flush )
  
  |;s|)
 
 )

7797
