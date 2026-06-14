(in-package #:holomacs)

;;;; =========================================================================
;;;; String Representation Helper
;;;; =========================================================================

(defun elisp-to-string (obj)
  (cond
    ((null obj) "nil")
    ((eq obj 't) "t")
    ((symbolp obj) (string-downcase (symbol-name obj)))
    ((stringp obj) obj)
    ((elisp-buffer-p obj) (format nil "#<buffer ~A>" (buffer-name obj)))
    (t (format nil "~A" obj))))

(defun elisp-to-string-readable (obj)
  (cond
    ((stringp obj) (format nil "~S" obj))
    (t (elisp-to-string obj))))

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
                      obj))

(register-primitive 'message
                    (lambda (format-str &rest args)
                      (let ((msg (apply #'format nil format-str args)))
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
