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

(defun adjust-markers-on-insert (buf pos len)
  (dolist (m (buffer-markers buf))
    (let ((mpos (marker-position m)))
      (when mpos
        (cond
          ((> mpos pos)
           (setf (marker-position m) (+ mpos len)))
          ((= mpos pos)
           (when (marker-insertion-type m)
             (setf (marker-position m) (+ mpos len)))))))))

(defun adjust-markers-on-delete (buf pos len)
  (dolist (m (buffer-markers buf))
    (let ((mpos (marker-position m)))
      (when mpos
        (cond
          ((> mpos (+ pos len))
           (setf (marker-position m) (- mpos len)))
          ((>= mpos pos)
           (setf (marker-position m) pos)))))))

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

(defun elisp-goto-char (pos)
  (let* ((resolved (resolve-position pos))
         (max-pos (1+ (length (buffer-contents *current-buffer*)))))
    (cond
      ((< resolved 1) (setf (buffer-point *current-buffer*) 1))
      ((> resolved max-pos) (setf (buffer-point *current-buffer*) max-pos))
      (t (setf (buffer-point *current-buffer*) resolved)))
    (buffer-point *current-buffer*)))

(register-primitive 'goto-char #'elisp-goto-char)

(register-primitive 'buffer-substring
                    (lambda (start end)
                      (let ((contents (buffer-contents *current-buffer*))
                            (s-pos (resolve-position start))
                            (e-pos (resolve-position end)))
                        (subseq contents (1- s-pos) (1- e-pos)))))

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
                            (let ((pos (buffer-point buf)))
                              ;; Write new string chars
                              (loop for i from 0 to (1- len) do
                                    (setf (aref contents (+ idx i)) (char str i)))
                              ;; Advance point
                              (setf (buffer-point buf) (+ (buffer-point buf) len))
                              ;; Adjust markers
                              (adjust-markers-on-insert buf pos len)))))))

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
                                     (let ((contents (buffer-contents *current-buffer*))
                                           (s-pos (resolve-position start))
                                           (e-pos (resolve-position end)))
                                       (subseq contents (1- s-pos) (1- e-pos))))))
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

;;;; =========================================================================
;;;; Markers & Buffer Editing Primitives
;;;; =========================================================================

(register-primitive 'make-marker
                    (lambda ()
                      (make-elisp-marker)))

(register-primitive 'markerp
                    (lambda (x)
                      (if (elisp-marker-p x) 't nil)))

(register-primitive 'integer-or-marker-p
                    (lambda (x)
                      (if (or (integerp x) (elisp-marker-p x)) 't nil)))

(register-primitive 'number-or-marker-p
                    (lambda (x)
                      (if (or (numberp x) (elisp-marker-p x)) 't nil)))

(register-primitive 'marker-position
                    (lambda (m)
                      (if (elisp-marker-p m)
                          (marker-position m)
                          (signal-elisp-error 'wrong-type-argument 'markerp m))))

(register-primitive 'marker-buffer
                    (lambda (m)
                      (if (elisp-marker-p m)
                          (marker-buffer m)
                          (signal-elisp-error 'wrong-type-argument 'markerp m))))

(register-primitive 'set-marker
                    (lambda (m pos &optional buffer)
                      (unless (elisp-marker-p m)
                        (signal-elisp-error 'wrong-type-argument 'markerp m))
                      (let ((buf (or buffer *current-buffer*)))
                        (unless (elisp-buffer-p buf)
                          (signal-elisp-error 'wrong-type-argument 'bufferp buf))
                        (let ((old-buf (marker-buffer m)))
                          (when old-buf
                            (setf (buffer-markers old-buf) (delete m (buffer-markers old-buf)))))
                        (if pos
                            (let* ((resolved (resolve-position pos))
                                   (max-pos (1+ (length (buffer-contents buf)))))
                              (setf (marker-position m) (max 1 (min resolved max-pos)))
                              (setf (marker-buffer m) buf)
                              (push m (buffer-markers buf)))
                            (progn
                              (setf (marker-position m) nil)
                              (setf (marker-buffer m) nil))))
                      m))

(register-primitive 'copy-marker
                    (lambda (m)
                      (cond
                        ((elisp-marker-p m)
                         (let ((new-m (make-elisp-marker
                                       :buffer (marker-buffer m)
                                       :position (marker-position m)
                                       :insertion-type (marker-insertion-type m))))
                           (when (marker-buffer m)
                             (push new-m (buffer-markers (marker-buffer m))))
                           new-m))
                        ((integerp m)
                         (let ((new-m (make-elisp-marker
                                       :buffer *current-buffer*
                                       :position m)))
                           (push new-m (buffer-markers *current-buffer*))
                           new-m))
                        (t (signal-elisp-error 'wrong-type-argument 'integer-or-marker-p m)))))

(register-primitive 'point-marker
                    (lambda ()
                      (let ((m (make-elisp-marker
                                :buffer *current-buffer*
                                :position (buffer-point *current-buffer*))))
                        (push m (buffer-markers *current-buffer*))
                        m)))

(register-primitive 'point-min-marker
                    (lambda ()
                      (let ((m (make-elisp-marker
                                :buffer *current-buffer*
                                :position 1)))
                        (push m (buffer-markers *current-buffer*))
                        m)))

(register-primitive 'point-max-marker
                    (lambda ()
                      (let ((m (make-elisp-marker
                                :buffer *current-buffer*
                                :position (1+ (length (buffer-contents *current-buffer*))))))
                        (push m (buffer-markers *current-buffer*))
                        m)))

(defun delete-buffer-region (buf start end)
  (let* ((s (resolve-position start))
         (e (resolve-position end))
         (s-idx (1- (min s e)))
         (e-idx (1- (max s e)))
         (len (- e-idx s-idx))
         (contents (buffer-contents buf)))
    (when (> len 0)
      ;; Shift remaining elements left
      (loop for i from s-idx to (- (length contents) len 1) do
            (setf (aref contents i) (aref contents (+ i len))))
      ;; Adjust fill pointer
      (setf (fill-pointer contents) (- (length contents) len))
      ;; Adjust point
      (let ((pt (buffer-point buf)))
        (cond
          ((> pt (+ s-idx len)) (setf (buffer-point buf) (- pt len)))
          ((>= pt (1+ s-idx)) (setf (buffer-point buf) (1+ s-idx)))))
      ;; Adjust markers
      (adjust-markers-on-delete buf (1+ s-idx) len))))

(register-primitive 'delete-region
                    (lambda (start end)
                      (delete-buffer-region *current-buffer* start end)
                      nil))

(register-primitive 'delete-char
                    (lambda (n &optional killflag)
                      (declare (ignore killflag))
                      (let* ((pt (buffer-point *current-buffer*))
                             (max-pos (1+ (length (buffer-contents *current-buffer*)))))
                        (if (> n 0)
                            (let ((end (min (+ pt n) max-pos)))
                              (delete-buffer-region *current-buffer* pt end))
                            (let ((start (max (- pt (- n)) 1)))
                              (delete-buffer-region *current-buffer* start pt))))
                      nil))

(register-primitive 'erase-buffer
                    (lambda ()
                      (delete-buffer-region *current-buffer* 1 (1+ (length (buffer-contents *current-buffer*))))
                      nil))

(register-primitive 'forward-char
                    (lambda (&optional n)
                      (let ((steps (or n 1)))
                        (elisp-goto-char (+ (buffer-point *current-buffer*) steps)))
                      nil))

(register-primitive 'backward-char
                    (lambda (&optional n)
                      (let ((steps (or n 1)))
                        (elisp-goto-char (- (buffer-point *current-buffer*) steps)))
                      nil))

(defun line-beginning-position ()
  (let* ((contents (buffer-contents *current-buffer*))
         (pt (buffer-point *current-buffer*))
         (idx (1- pt)))
    (loop for i from (1- idx) downto 0 do
          (when (char= (aref contents i) #\Newline)
            (return-from line-beginning-position (+ i 2))))
    1))

(register-primitive 'beginning-of-line
                    (lambda (&optional n)
                      (declare (ignore n))
                      (elisp-goto-char (line-beginning-position))
                      nil))

(defun line-end-position ()
  (let* ((contents (buffer-contents *current-buffer*))
         (len (length contents))
         (pt (buffer-point *current-buffer*))
         (idx (1- pt)))
    (loop for i from idx to (1- len) do
          (when (char= (aref contents i) #\Newline)
            (return-from line-end-position (1+ i))))
    (1+ len)))

(register-primitive 'end-of-line
                    (lambda (&optional n)
                      (declare (ignore n))
                      (elisp-goto-char (line-end-position))
                      nil))

(defun get-line-starts ()
  (let* ((contents (buffer-contents *current-buffer*))
         (len (length contents))
         (starts (list 1)))
    (loop for i from 0 to (1- len) do
          (when (char= (aref contents i) #\Newline)
            (push (+ i 2) starts)))
    (nreverse starts)))

(defun current-line-index (starts pt)
  (let ((idx 0))
    (dolist (start (cdr starts))
      (if (< pt start)
          (return-from current-line-index idx)
          (incf idx)))
    idx))

(register-primitive 'forward-line
                    (lambda (&optional n)
                      (let* ((count (or n 1))
                             (starts (get-line-starts))
                             (num-lines (length starts))
                             (curr-idx (current-line-index starts (buffer-point *current-buffer*)))
                             (target-idx (+ curr-idx count)))
                        (cond
                          ((< target-idx 0)
                           (elisp-goto-char 1))
                          ((>= target-idx num-lines)
                           (elisp-goto-char (1+ (length (buffer-contents *current-buffer*)))))
                          (t
                           (elisp-goto-char (nth target-idx starts)))))
                      nil))

