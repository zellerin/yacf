;;;; -*- mode: emacs-lisp; lexical-binding:t -*-

;;;; TODO:
;;;; - limit what is redisplayed

(eval-when-compile
  (require 'cl-lib))

(defface yacf-yellow '((t (:foreground "black" :slant italic)))
  "Face for yellow words (execute immediately) words"
  :group 'yacf)

(defface yacf-green '((t (:foreground "green")))
  "Face for green (compile me) words"
  :group 'yacf)

(defface yacf-gray '((t (:foreground "gray")))
  "Face for comments"
  :group 'yacf)

(defface yacf-blue '((t (:foreground "blue")))
  "Face for edit time words"
  :group 'yacf)

(defun yacf-get-nr (pos)
  "Get word at point, sans 4 bits of type flag at end."
  (interactive "d")
  (logxor
   (* #x100000 (char-after (+ 3 pos)))
   (* #x1000 (char-after (+ 2 pos)))
   (* #x10 (char-after (+ 1 pos)))
   (floor (char-after pos) #x10)))

(defun yacf-find-code (nr definition)
  (interactive (list (yacf-string-to-nr
		      (read-string "Search: "))
		     current-prefix-arg))
  "Search for next occurance of the word at point.
With prefix, search for definitions only."
  (let ((point (point)))
    (forward-char 4)
    (while (or
	    (/= (yacf-get-nr (point)) nr)
	    (and definition (/= 3 (and #xf (char-after)))))
      (forward-char 4)
      (if (= (point) point) (error "Not found"))
      (if (= (point) (point-max))
	  (goto-char (point-min))))))

(defun yacf-find-forward (definition)
  (interactive "P")
  "Search for next occurance of the word at point.
With prefix, search for definitions only."
  (yacf-find-code  (yacf-get-nr (point)) definition))

(defun yacf-nr-to-string (nr)
  "Convert number to shannon encoded string"
  (let* ((sizeflag (logand 3 (lsh nr -26)))
	 (size (cl-case sizeflag
		 (0 4) (1 4) (2 5) (3 7)))
	 (base
	  (cl-case sizeflag
	    (0 " rto")
	    (1 "eani")
	    (2 "smcylgfw")
	    (3 "dvpbhxuqkzj34567891-0.2/;:!+@*,?")))
	 (offset (lsh (logand nr #x3ffffff)
		      (- size 28))))
    (setq nr (lsh (logand nr (lsh #xfffffff (- size))) size))
    (if (zerop nr)
	(string (aref base offset))
      (concat (yacf-nr-to-string nr) (vector (aref base offset))))))

(defun yacf-string-used-bits (nr)
  (let* ((sizeflag (logand 3 (lsh nr -26)))
	 (size (cl-case sizeflag
		 (0 4) (1 4) (2 5) (3 7))))
    (setq nr (lsh (logand nr (lsh #xfffffff (- size))) size))
    (if (zerop nr) size
      (+ (yacf-string-used-bits nr) size))))

(defun yacf-replace-nr (nr &optional type)
  (interactive "nNumber: ")
  (unless type
    (setq type 1))
  (delete-char 4)
  (insert (+ type (logand #xf0 (lsh nr 4))))
  (insert (logand #xff (lsh nr -4)))
  (insert (logand #xff (lsh nr -12)))
  (insert (logand #xff (lsh nr -20)))
  (forward-char -4))

(defun yacf-insert-nbit-letter (l n mask)
  (lambda ()
    (interactive)
    (let* ((nr (yacf-get-nr (point))))
      (when (= 0 (logand mask nr))
	(yacf-replace-nr (logxor (lsh l (- 28 n)) (lsh nr (- n)))
			 (logand (char-after (point)) #xf))
	(yacf-redisplay)))))

(defun yacf-insert-4bit-letter (l)
  (yacf-insert-nbit-letter l 4 #xf))

(defun yacf-load (file)
  (interactive "G")
  (find-file-literally file)
  (yacf-mode)
  (yacf-redisplay))

(defun yacf-forward-page ()
  (interactive)
  (widen)
  (forward-char 512)
  (yacf-narrow-to-page))

(defun yacf-backward-page ()
  (interactive)
  (widen)
  (forward-char -512)
  (yacf-narrow-to-page))

(defun yacf-redisplay ()
  (interactive)
  (let ((mod (buffer-modified-p)))
    (remove-text-properties (point-min) (point-max) '(display face))
    (dotimes (pos (/ (- (point-max) (point-min)) 4))
      (let* ((beg (+ (point-min) (* pos 4)))
	     (end (+ 4 beg))
	     (nr (yacf-get-nr beg))
	     (type (logand (char-after beg) #x7)))
	(cl-flet ((text-and-face (text face)
				 (put-text-property beg end 'display text)
				 (add-text-properties beg end `(face ,face))))
	    (cl-ecase type
	      (0 (text-and-face (concat ""
					(yacf-nr-to-string nr))
				(if (= (point-min) beg)
				    'yacf-gray
				  (get-text-property (1- beg) 'face))))
	      (1 (when (cl-plusp (logand nr #x8000000))
		   (setq nr (- (logand (- nr) #x7ffffff))))
		 (text-and-face (format " %d" nr) 'yacf-blue))
	      (2 (text-and-face (concat " " (yacf-nr-to-string nr)) 'yacf-green))
	      (3 (text-and-face (concat "\n" (yacf-nr-to-string nr)) 'bold))
	      (4 (text-and-face (concat " " (yacf-nr-to-string nr) "\n") 'yacf-blue))
	      (5 (text-and-face (concat " " (yacf-nr-to-string nr)) 'yacf-gray))
	      (6 (text-and-face (format " %x" nr) 'yacf-green))
	      (7 (text-and-face (concat " " (yacf-nr-to-string nr)) 'yacf-yellow))))))
    (set-buffer-modified-p mod)))

(defcustom yacf-space-order
  '(7 2 3 5 4 0 7 1 6 1 )
  "Order of cycling type"
  :group 'yacf)

(defun yacf-insert-cell ()
  (interactive)
  "Insert N empty words"

  (insert-char 0 4)
  (forward-char -4)
  (yacf-redisplay))

(defun yacf-insert-nr (nr)
  (interactive "N")
  "Insert N"
  (yacf-insert-cell)
  (yacf-replace-nr nr 1)
  (yacf-redisplay))

(defun yacf-sweep ()
  (interactive)
  "Remove empty words, put them at the end of the visible area"
    (dotimes (pos (/ (- (point-max) (point-min)) 4))
      (let* ((beg (- (point-max) (* pos 4) 4))
	     (end (+ 4 beg))
	     (nr (yacf-get-nr beg)))
	(when (and (= 0 (char-after beg) nr))
	  (delete-region beg end)))))

(defun yacf-change-type ()
  (interactive)
  "Change type (color) of word"
  (let ((type (logand 7 (char-after (point))))
	(code (logand #xf8 (char-after (point)))))
    (delete-char 1)
    (insert (logxor code (cadr (member type yacf-space-order))))
    (backward-char)
    (yacf-redisplay)))

(defun yacf-delete ()
  "Remove word at point"
  (interactive)
  (yacf-replace-nr 0 0)
  (yacf-redisplay))

(define-derived-mode yacf-mode fundamental-mode "colforth"
  "Edit tagged Shannon-encoded words."
  (setq page-delimiter (string 4 32 174 74)))	; blue page

(defun yacf-beginning-of-line (count)
  (interactive "p")
  "Move `count' definitions back."
  (message "%d" count)
  (while (not (or
	       (= 3 (logand 7 (char-after (point))))
	       (= (point) (point-min))))
    (forward-char -4))
  (when (> count 1)
    (forward-char -4)
    (yacf-beginning-of-line (1- count))))

(defun yacf-narrow-to-pages (from to)
  (interactive "nFrom: \nnTo: " )
  (narrow-to-region (+ 1 (* from 512))
		    (+ 1 (* to 512)))
  (yacf-redisplay))

(defun yacf-insert-cr ()
  (interactive)
  (insert 4 0 0 25)
  (yacf-redisplay))

(define-key yacf-mode-map (kbd "C-x [") #'yacf-backward-page)
(define-key yacf-mode-map (kbd "C-x ]") #'yacf-forward-page)
(define-key yacf-mode-map (kbd "C-s") #'yacf-find-forward)
(define-key yacf-mode-map (kbd "C-a") #'yacf-beginning-of-line)
(define-key yacf-mode-map (kbd "C-l") #'yacf-redisplay)
(define-key yacf-mode-map (kbd "SPC") #'yacf-change-type)
(define-key yacf-mode-map (kbd "RET") #'yacf-insert-cr)
(define-key yacf-mode-map (kbd "#") #'yacf-insert-nr)
(define-key yacf-mode-map (kbd "<delete>") #'yacf-delete)
(define-key yacf-mode-map (kbd "<deletechar>") #'yacf-delete)
(define-key yacf-mode-map (kbd "<insert>") #'yacf-insert-cell)
(define-key yacf-mode-map (kbd "<insertchar>") #'yacf-insert-cell)

;; Letter inserts
(dotimes (i 8)
  (define-key yacf-mode-map (kbd (string (aref "$rtoeani" i)))
    (yacf-insert-nbit-letter i 4 #xf)))

(dotimes (i 8)
  (define-key yacf-mode-map (kbd (string (aref "smcylgfw" i)))
    (yacf-insert-nbit-letter (+ #x10 i) 5 #x1f)))

(dotimes (i 32)
  (define-key yacf-mode-map (kbd (string (aref "dvpbhxuqkzj34567891-0.2/;:!+@*,?" i)))
    (yacf-insert-nbit-letter (+ i #x60) 7 #x7f)))

(defun yacf-string-to-nr (word)
  (with-temp-buffer
    (insert-char 0 4)
    (goto-char 1)
    (use-local-map yacf-mode-map)
    (mapc (lambda (c) (funcall (key-binding (vector c))))
	  word)
    (yacf-get-nr (point))))
