(defpackage forth-source
  (:nicknames #:fs)
  (:use #:cl))

(defpackage forth-expanders
  (:nicknames #:fe)
  (:use))

(in-package forth-source)

(deftype word ()
  "32-bit word, interpreted based on its (ldb (byte 3 0))"
  '(unsigned-byte 32))

(defun compile-number (output nr &optional (flag 6))
  (setf (ldb (byte 28 4) flag) nr)
  (vector-push flag output))

(defvar letter-codes
  (vector
   #x00 #xfa #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #xfd #xfb #xfe #xf3 #xf5 #xf7
   #xf4 #xf2 #xf6 #xeb #xec #xed #xee #xef #xf0 #xf1 #xf9 #xf8 #x00 #x00 #x00 #xff
   #xfc #x05 #xe3 #x52 #xe0 #x04 #x56 #x55 #xe4 #x07 #xea #xe8 #x54 #x51 #x06 #x03
   #xe2 #xe7 #x01 #x50 #x02 #xe6 #xe1 #x57 #xe5 #x53 #xe9 #x00 #x00 #x00 #x00 #x00
   #x00 #x05 #xe3 #x52 #xe0 #x04 #x56 #x55 #xe4 #x07 #xea #xe8 #x54 #x51 #x06 #x03
   #xe2 #xe7 #x01 #x50 #x02 #xe6 #xe1 #x57 #xe5 #x53 #xe9 #x00 #x00 #x00 #x00 #x00)
  "Translation table for codes"
)

(defun encode-word (output word type)
  (with-input-from-string (out (symbol-name word))
    (let (letter
	  (word 0)
	  (shift 3))
      (loop while (> (setq letter (char-code (read-char out nil #\Space))) 32)
	 do (let* ((size-code (aref letter-codes (- letter 32)))
		   (size (+ 4 (ldb (byte 2 6) size-code))))
	      (when (> (+ size shift) 32 )
		(vector-push (+ type (ash word (- 32 shift)))
			     output)
		(setq word 0 shift 3 type 0))
	      (setf (ldb (byte size shift) word)
		    size-code)
	      (incf shift size))
	 finally (vector-push (+ type (ash word (- 32 shift))) output)))))

(defun compile-comment (output symbol)
  (encode-word output symbol 5))

(defun compile-list (output default-symbol list)
  (loop for i in list
     do (etypecase i
	  ((eql cr) (encode-word output i
				 (if (= default-symbol 2)
				     default-symbol 4)))
	  ((eql [) (setq default-symbol 7))
	  ((eql ]) (setq default-symbol 2))
	  ((integer * -1) (compile-number output i 1))
	  ((integer 0) (compile-number output i))
	  (symbol (encode-word output i default-symbol))
	  (cons (compile-cons output i)))))

(defun fe::defun (output word &rest code)
  (encode-word output word 3)
  (compile-list output 2 code)
  (encode-word output '|;| 2))

(defun fe::def-top-op (output word code &optional asm)
  "Define word that makes an 2byte operation followed by number"
  (declare (ignorable asm))
  (fe::defun output word code '|2c,n|))

(defun fe::-if-exit (output &rest if)
  (compile-list output 2 `(-if ,@if |;| then)))

(defun compile-cons (output item)
  (case (car item)
    (dec (compile-number output (second item) 1))
    (cmt (mapcar (lambda (a) (compile-comment output a))
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
     (compile-list output 7 ',body)
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
	 |;s|




   )
  
  )
