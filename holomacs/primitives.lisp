(in-package #:holomacs)

;;;; =========================================================================
;;;; String Representation Helper
;;;; =========================================================================

(defun elisp-print-object (obj &optional (readable nil))
  (cond
    ((null obj) "nil")
    ((eq obj 't) "t")
    ((symbolp obj) (string-downcase (symbol-name obj)))
    ((stringp obj)
     (if readable
         (let ((out (make-string-output-stream)))
           (write-char #\" out)
           (loop for c across obj do
                 (case c
                   (#\" (write-string "\\\"" out))
                   (#\\ (write-string "\\\\" out))
                   (t (write-char c out))))
           (write-char #\" out)
           (get-output-stream-string out))
         obj))
    ((integerp obj) (format nil "~D" obj))
    ((numberp obj) (format nil "~A" obj))
    ((characterp obj) (if readable (format nil "?~C" obj) (string obj)))
    ((elisp-buffer-p obj) (format nil "#<buffer ~A>" (buffer-name obj)))
    ((vectorp obj)
     (format nil "[~{~A~^ ~}]" (map 'list (lambda (x) (elisp-print-object x t)) obj)))
    ((consp obj)
     (let ((result (make-string-output-stream)))
       (write-char #\( result)
       (let ((curr obj))
         (loop
           (write-string (elisp-print-object (car curr) t) result)
           (setf curr (cdr curr))
           (cond
             ((null curr) (return))
             ((consp curr) (write-char #\Space result))
             (t
              (write-string " . " result)
              (write-string (elisp-print-object curr t) result)
              (return)))))
       (write-char #\) result)
       (get-output-stream-string result)))
    (t (format nil "~A" obj))))

(defun elisp-to-string (obj)
  (elisp-print-object obj nil))

(defun elisp-to-string-readable (obj)
  (elisp-print-object obj t))

(defun format-elisp (format-str &rest args)
  (let ((out (make-string-output-stream))
        (len (length format-str))
        (i 0)
        (arg-idx 0))
    (loop while (< i len) do
          (let ((c (char format-str i)))
            (if (char= c #\%)
                (if (< (1+ i) len)
                    (let ((next (char format-str (1+ i))))
                      (incf i 2)
                      (case next
                        (#\% (write-char #\% out))
                        (#\s (if (< arg-idx (length args))
                                 (write-string (elisp-print-object (nth arg-idx args) nil) out)
                                 (error "Not enough arguments for format string"))
                             (incf arg-idx))
                        (#\S (if (< arg-idx (length args))
                                 (write-string (elisp-print-object (nth arg-idx args) t) out)
                                 (error "Not enough arguments for format string"))
                             (incf arg-idx))
                        (#\d (if (< arg-idx (length args))
                                 (write-string (format nil "~D" (nth arg-idx args)) out)
                                 (error "Not enough arguments for format string"))
                             (incf arg-idx))
                        (t (write-char #\% out) (write-char next out))))
                    (progn (write-char #\% out) (incf i)))
                (progn (write-char c out) (incf i)))))
    (get-output-stream-string out)))

;;;; =========================================================================
;;;; Primitive Registrations
;;;; =========================================================================

;; Math
(register-primitive '+ #'+)
(register-primitive '- #'-)
(register-primitive '* #'*)
(register-primitive '/ #'/)
(register-primitive '1+ #'1+)
(register-primitive '1- #'1-)

;; Comparison
(register-primitive '= #'=)
(register-primitive '< #'<)
(register-primitive '> #'>)
(register-primitive '<= #'<=)
(register-primitive '>= #'>=)

;; List Helpers
(register-primitive 'car (lambda (x) (car x)))
(register-primitive 'cdr (lambda (x) (cdr x)))
(register-primitive 'consp (lambda (x) (consp x)))

;; Buffer Primitives
(register-primitive 'current-buffer
                    (lambda () *current-buffer*))

(register-primitive 'set-buffer
                    (lambda (buf-or-name)
                      (set-buffer buf-or-name)))

(register-primitive 'get-buffer-create
                    (lambda (name)
                      (get-buffer-create name)))

(register-primitive 'buffer-list
                    (lambda () *buffers*))

(register-primitive 'buffer-name
                    (lambda (buf)
                      (if (elisp-buffer-p buf)
                          (buffer-name buf)
                          (error "Wrong type argument: bufferp"))))

(register-primitive 'point
                    (lambda ()
                      (buffer-point *current-buffer*)))

(register-primitive 'point-min
                    (lambda () 1))

(register-primitive 'point-max
                    (lambda ()
                      (1+ (length (buffer-contents *current-buffer*)))))

(register-primitive 'goto-char
                    (lambda (pos)
                      (let ((max-pos (1+ (length (buffer-contents *current-buffer*)))))
                        (cond
                          ((< pos 1) (setf (buffer-point *current-buffer*) 1))
                          ((> pos max-pos) (setf (buffer-point *current-buffer*) max-pos))
                          (t (setf (buffer-point *current-buffer*) pos)))
                        (buffer-point *current-buffer*))))

(register-primitive 'buffer-substring
                    (lambda (start end)
                      (let ((contents (buffer-contents *current-buffer*)))
                        (subseq contents (1- start) (1- end)))))

(register-primitive 'insert
                    (lambda (&rest args)
                      (dolist (arg args)
                        (let* ((str (elisp-to-string arg))
                               (buf *current-buffer*)
                               (contents (buffer-contents buf))
                               (idx (1- (buffer-point buf)))
                               (len (length str)))
                          ;; Adjust fill pointer and content array size
                          (let ((new-total (+ (length contents) len)))
                            (when (> new-total (array-dimension contents 0))
                              (adjust-array contents new-total))
                            (setf (fill-pointer contents) new-total)
                            ;; Shift elements to the right to make room
                            (loop for i from (1- new-total) downto (+ idx len) do
                                  (setf (aref contents i) (aref contents (- i len))))
                            ;; Write new string chars
                            (loop for i from 0 to (1- len) do
                                  (setf (aref contents (+ idx i)) (char str i)))
                            ;; Advance point
                            (setf (buffer-point buf) (+ (buffer-point buf) len)))))))

;; Printing & Formatting
(register-primitive 'print
                    (lambda (obj &optional stream)
                      (declare (ignore stream))
                      (format *elisp-output* "~%~A~%" (elisp-to-string-readable obj))
                      (setf *noninteractive-need-newline* t)
                      obj))

(register-primitive 'message
                    (lambda (format-str &rest args)
                      (let ((msg (apply #'format-elisp format-str args)))
                        (when *noninteractive-need-newline*
                          (write-char #\Newline *elisp-output*)
                          (setf *noninteractive-need-newline* nil))
                        (format *elisp-output* "~A~%" msg)
                        msg)))

(register-primitive 'concat
                    (lambda (&rest args)
                      (apply #'concatenate 'string (mapcar #'elisp-to-string args))))

(register-primitive 'int-to-string
                    (lambda (n)
                      (format nil "~D" n)))

(register-primitive 'string-equal
                    (lambda (s1 s2)
                      (if (string= (elisp-to-string s1) (elisp-to-string s2)) 't nil)))

(register-primitive 'substring
                    (lambda (str start &optional end)
                      (subseq (elisp-to-string str) start end)))

;; Local variables
(register-primitive 'make-local-variable
                    (lambda (var)
                      (unless (nth-value 1 (gethash var (buffer-local-vars *current-buffer*)))
                        (setf (gethash var (buffer-local-vars *current-buffer*))
                              (elisp-symbol-value var)))
                      var))

(register-primitive 'make-variable-buffer-local
                    (lambda (var)
                      (unless (nth-value 1 (gethash var (buffer-local-vars *current-buffer*)))
                        (setf (gethash var (buffer-local-vars *current-buffer*))
                              (elisp-symbol-value var)))
                      var))

(register-primitive 'boundp
                    (lambda (var)
                      (if (elisp-variable-boundp var)
                          't
                          nil)))

;;;; =========================================================================
;;;; New Primitives (Equality, Lists, Symbols, Control, I/O)
;;;; =========================================================================

;; Structural equality helper
(defun elisp-equal (x y)
  (cond
    ((eq x y) t)
    ((and (stringp x) (stringp y)) (string= x y))
    ((and (consp x) (consp y))
     (and (elisp-equal (car x) (car y))
          (elisp-equal (cdr x) (cdr y))))
    ((and (vectorp x) (vectorp y))
     (and (= (length x) (length y))
          (every #'elisp-equal x y)))
    (t nil)))

;; Equality
(register-primitive 'eq (lambda (x y) (if (eq x y) 't nil)))
(register-primitive 'equal (lambda (x y) (if (elisp-equal x y) 't nil)))

;; Lists
(register-primitive 'cons #'cons)
(register-primitive 'list #'list)
(register-primitive 'vector (lambda (&rest args) (apply #'vector args)))
(register-primitive 'length #'length)
(register-primitive 'nth (lambda (n list) (nth n list)))
(register-primitive 'nthcdr (lambda (n list) (nthcdr n list)))
(register-primitive 'member (lambda (elt list) (member elt list :test #'elisp-equal)))
(register-primitive 'memq (lambda (elt list) (member elt list :test #'eq)))
(register-primitive 'assoc (lambda (key alist) (assoc key alist :test #'elisp-equal)))
(register-primitive 'assq (lambda (key alist) (assoc key alist :test #'eq)))
(register-primitive 'nconc (lambda (&rest lists) (apply #'nconc lists)))
(register-primitive 'append (lambda (&rest lists) (apply #'append lists)))

;; Type Predicates
(register-primitive 'symbolp (lambda (x) (if (symbolp x) 't nil)))
(register-primitive 'stringp (lambda (x) (if (stringp x) 't nil)))
(register-primitive 'integerp (lambda (x) (if (integerp x) 't nil)))
(register-primitive 'numberp (lambda (x) (if (numberp x) 't nil)))
(register-primitive 'listp (lambda (x) (if (listp x) 't nil)))
(register-primitive 'arrayp (lambda (x) (if (or (stringp x) (vectorp x)) 't nil)))

;; Symbols
(register-primitive 'symbol-value #'elisp-symbol-value)
(register-primitive 'symbol-function (lambda (sym) (or (gethash sym *primitives*) (signal-elisp-error 'void-function sym))))
(register-primitive 'intern (lambda (str) (intern (string-upcase str) '#:holomacs)))
(register-primitive 'make-symbol (lambda (str) (make-symbol str)))

;; Control Flow (Throw)
(register-primitive 'throw (lambda (tag value) (throw tag value)))

;; File I/O
(register-primitive 'find-file-noselect
                    (lambda (filename &optional nowarn rawfile wildcards)
                      (declare (ignore nowarn rawfile wildcards))
                      (let* ((name (file-namestring filename))
                             (buf (get-buffer-create name)))
                        (with-open-file (stream filename :direction :input :if-does-not-exist nil)
                          (when stream
                            (let ((contents (make-array (file-length stream)
                                                        :element-type 'character
                                                        :adjustable t
                                                        :fill-pointer 0)))
                              (loop for char = (read-char stream nil nil)
                                    while char do
                                    (vector-push-extend char contents))
                              (setf (buffer-contents buf) contents))))
                        buf)))

(register-primitive 'write-region
                    (lambda (start end filename &optional append visit lockname mustbenew)
                      (declare (ignore visit lockname mustbenew))
                      (let ((str (if (stringp start)
                                     start
                                     (let ((contents (buffer-contents *current-buffer*)))
                                       (subseq contents (1- start) (1- end))))))
                        (with-open-file (stream filename
                                               :direction :output
                                               :if-exists (if append :append :supersede)
                                               :if-does-not-exist :create)
                          (write-string str stream))
                        ;; Print the message like Emacs does: "Wrote <abspath>"
                        (let ((abspath (namestring (truename filename))))
                          (format *elisp-output* "Wrote ~A~%" abspath)))
                      nil))

(register-primitive 'insert-file-contents
                    (lambda (filename &optional visit beg end replace)
                      (declare (ignore visit beg end replace))
                      (let ((old-point (buffer-point *current-buffer*)))
                        (with-open-file (stream filename :direction :input :if-does-not-exist nil)
                          (when stream
                            (let ((contents (make-string (file-length stream))))
                              (read-sequence contents stream)
                              (apply (gethash 'insert *primitives*) (list contents)))))
                        (setf (buffer-point *current-buffer*) old-point))
                      nil))

;; Keymaps
(register-primitive 'make-sparse-keymap
                    (lambda (&optional prompt)
                      (declare (ignore prompt))
                      (list 'keymap)))

(register-primitive 'define-key
                    (lambda (keymap key definition)
                      (if (and (consp keymap) (eq (car keymap) 'keymap))
                          (let ((existing (assoc key (cdr keymap) :test #'equal)))
                            (if existing
                                (setf (cdr existing) definition)
                                (setf (cdr keymap) (cons (cons key definition) (cdr keymap)))))
                          (error "Wrong type argument: keymapp"))
                      definition))

(register-primitive 'lookup-key
                    (lambda (keymap key &optional accept-default)
                      (declare (ignore accept-default))
                      (if (and (consp keymap) (eq (car keymap) 'keymap))
                          (let ((binding (assoc key (cdr keymap) :test #'equal)))
                            (if binding
                                (cdr binding)
                                nil))
                          (error "Wrong type argument: keymapp"))))

(defvar *global-map* nil)
(register-primitive 'use-global-map
                    (lambda (keymap)
                      (setf *global-map* keymap)
                      nil))

