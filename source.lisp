(defpackage forth-source
  (:nicknames #:fs)
  (:use #:cl))

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

(defun compile-symbol (output symbol)
  (encode-word output symbol 7))

(defun compile-cons (output item)
  (ecase (car item)
    (dec (compile-number output (second item) 1))
    (cmt (mapcar (lambda (a) (compile-comment output a))
		 (cdr item)))
    (defun
	(encode-word output (cadr item) 3)
	(loop for i in (cddr item)
	   do (etypecase i
		((integer * -1) (compile-number output i 1))
		((integer 0) (compile-number output i))
		(symbol (encode-word output i 2))
		(cons (compile-cons output i))))
      (encode-word output '|;| 2))))

(defmacro with-page (name options &body body)
  (declare (ignorable options name))
  `(let ((output (make-array 512
			     :element-type 'word
			     :fill-pointer 0)))
     (loop for item in ',body
	do (etypecase item
	     ((eql cr) (encode-word output item 4))
	     ((integer * -1) (compile-number output item 1))
	     ((integer 0) (compile-number output item))
	     (symbol (compile-symbol output item))
	     (cons (compile-cons output item))))
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
   (defun ash #xf8c1 |2c,n|)
   (defun lsr #xe8c1 |2c,n|)
   (defun shl #xe0c1 |2c,n|)
   (defun and #xe083 |2c,n|)
   (defun / #xbed231 |3c,| |,| #xf6f7 |2c,|)
   (defun cmp #x3d |c,,|)
   (defun nth #x08438b |2c,n|)
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
   |;s|))

