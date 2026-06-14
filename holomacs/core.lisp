(in-package #:holomacs)

(define-condition elisp-error (error)
  ((symbol :initarg :symbol :reader elisp-error-symbol)
   (data :initarg :data :reader elisp-error-data))
  (:report (lambda (condition stream)
             (format stream "~A: ~A"
                     (elisp-error-symbol condition)
                     (elisp-error-data condition)))))

(defun signal-elisp-error (symbol &rest data)
  (error 'elisp-error :symbol symbol :data data))

;;;; =========================================================================
;;;; Core Data Structures & Environment
;;;; =========================================================================

(defstruct (elisp-buffer (:conc-name buffer-))
  name
  (contents (make-array 0 :element-type 'character :adjustable t :fill-pointer 0))
  (point 1)
  (local-vars (make-hash-table :test 'eq))
  (markers nil))

(defstruct (elisp-marker (:conc-name marker-)
                         (:print-function print-elisp-marker))
  buffer
  position
  (insertion-type nil))

(defun print-elisp-marker (marker stream depth)
  (declare (ignore depth))
  (if (marker-buffer marker)
      (format stream "#<marker at ~A in ~A>"
              (marker-position marker)
              (buffer-name (marker-buffer marker)))
      (format stream "#<marker in no buffer>")))

(defun resolve-position (pos)
  (cond
    ((integerp pos) pos)
    ((elisp-marker-p pos)
     (let ((buf (marker-buffer pos))
           (mpos (marker-position pos)))
       (if (and buf mpos)
           mpos
           (signal-elisp-error 'wrong-type-argument 'integer-or-marker-p pos))))
    (t (signal-elisp-error 'wrong-type-argument 'integer-or-marker-p pos))))

(defvar *buffers* nil)
(defvar *current-buffer* nil)
(defvar *global-env* (make-hash-table :test 'eq))
(defvar *dynamic-env* nil) ; Alist of (symbol . value)
(defvar *noninteractive-need-newline* nil)

;; Standard output capture
(defvar *elisp-output* (make-string-output-stream))

;; Initialize state
(defun init-elisp-state ()
  (setf *buffers* nil
        *current-buffer* nil
        *dynamic-env* nil
        *noninteractive-need-newline* nil)
  (clrhash *global-env*)
  (setf *elisp-output* (make-string-output-stream))
  ;; Initialize nil and t in global env
  (setf (gethash 'nil *global-env*) nil)
  (setf (gethash 't *global-env*) 't)
  ;; Create initial scratch buffer
  (get-buffer-create "*scratch*")
  (set-buffer "*scratch*"))

;;;; =========================================================================
;;;; Variable Lookup & Assignment
;;;; =========================================================================

(defun elisp-variable-boundp (var)
  (or (assoc var *dynamic-env* :test #'eq)
      (and *current-buffer* (nth-value 1 (gethash var (buffer-local-vars *current-buffer*))))
      (nth-value 1 (gethash var *global-env*))))

(defun elisp-symbol-value (var)
  (let ((dyn-binding (assoc var *dynamic-env* :test #'eq)))
    (if dyn-binding
        (cdr dyn-binding)
        (if *current-buffer*
            (multiple-value-bind (val found) (gethash var (buffer-local-vars *current-buffer*))
              (if found
                  val
                  (multiple-value-bind (gval gfound) (gethash var *global-env*)
                    (if gfound
                        gval
                        (signal-elisp-error 'void-variable var)))))
            (multiple-value-bind (gval gfound) (gethash var *global-env*)
              (if gfound
                  gval
                  (signal-elisp-error 'void-variable var)))))))

(defun elisp-set-variable (var val)
  (let ((dyn-binding (assoc var *dynamic-env* :test #'eq)))
    (if dyn-binding
        (setf (cdr dyn-binding) val)
        (if *current-buffer*
            (multiple-value-bind (lval lfound) (gethash var (buffer-local-vars *current-buffer*))
              (declare (ignore lval))
              (if lfound
                  (setf (gethash var (buffer-local-vars *current-buffer*)) val)
                  (setf (gethash var *global-env*) val)))
            (setf (gethash var *global-env*) val))))
  val)

;;;; =========================================================================
;;;; Buffer Management Helpers
;;;; =========================================================================

(defun get-buffer-create (name)
  (let ((existing (find name *buffers* :key #'buffer-name :test #'string=)))
    (if existing
        existing
        (let ((new-buf (make-elisp-buffer :name name)))
          (setf *buffers* (append *buffers* (list new-buf)))
          new-buf))))

(defun set-buffer (buf-or-name)
  (let ((buf (if (stringp buf-or-name)
                 (get-buffer-create buf-or-name)
                 buf-or-name)))
    (setf *current-buffer* buf)
    buf))

;;;; =========================================================================
;;;; Elisp Evaluator / Interpreter
;;;; =========================================================================

(defvar *primitives* (make-hash-table :test 'eq))

(defun register-primitive (name fn)
  (setf (gethash name *primitives*) fn))

(defun eval-elisp (expr)
  (cond
    ((null expr) nil)
    ((eq expr 't) 't)
    ((symbolp expr)
     (elisp-symbol-value expr))
    ((or (numberp expr) (stringp expr) (characterp expr))
     expr)
    ((consp expr)
     (let ((head (car expr))
           (args (cdr expr)))
       (case head
         (quote (car args))
         (setq
          (let (last-val)
            (loop while args do
                  (let ((var (pop args))
                        (val-expr (pop args)))
                    (setf last-val (elisp-set-variable var (eval-elisp val-expr)))))
            last-val))
         (progn
          (let (last-val)
            (dolist (form args)
              (setf last-val (eval-elisp form)))
            last-val))
         (if
          (let ((cond-val (eval-elisp (first args))))
            (if cond-val
                (eval-elisp (second args))
                (eval-elisp (third args)))))
         (let
          (let* ((bindings (first args))
                 (body (rest args))
                 (new-env (loop for b in bindings
                                collect (let ((var (if (listp b) (first b) b))
                                              (val-expr (if (listp b) (second b) nil)))
                                          (cons var (eval-elisp val-expr))))))
            (let ((*dynamic-env* (append new-env *dynamic-env*)))
              (eval-elisp (cons 'progn body)))))
         (let*
          (let* ((bindings (first args))
                 (body (rest args))
                 (*dynamic-env* *dynamic-env*))
            (dolist (b bindings)
              (let ((var (if (listp b) (first b) b))
                    (val-expr (if (listp b) (second b) nil)))
                (push (cons var (eval-elisp val-expr)) *dynamic-env*)))
            (eval-elisp (cons 'progn body))))
         (while
          (let ((cond-expr (first args))
                (body (rest args))
                last-val)
            (loop while (eval-elisp cond-expr) do
                  (setf last-val (eval-elisp (cons 'progn body))))
            last-val))
         (catch
          (let ((tag (eval-elisp (first args)))
                (body (rest args)))
            (catch tag
              (eval-elisp (cons 'progn body)))))
         (condition-case
          (let ((var (first args))
                (bodyform (second args))
                (handlers (cddr args)))
            (handler-case
                (eval-elisp bodyform)
              (error (c)
                (let ((matching-handler (find 'error handlers :key #'first)))
                  (if matching-handler
                      (let ((handler-body (rest matching-handler)))
                        (let* ((err-val (if (typep c 'elisp-error)
                                            (cons (elisp-error-symbol c) (elisp-error-data c))
                                            (list 'error (format nil "~A" c)))))
                          (if var
                              (let ((*dynamic-env* (cons (cons var err-val) *dynamic-env*)))
                                (eval-elisp (cons 'progn handler-body)))
                              (eval-elisp (cons 'progn handler-body)))))
                      (error c)))))))
         (unwind-protect
          (let ((bodyform (first args))
                (unwind-forms (rest args)))
            (unwind-protect
                (eval-elisp bodyform)
              (dolist (form unwind-forms)
                (eval-elisp form)))))
         (t
          ;; Normal function call
          (let ((prim (gethash head *primitives*)))
            (if prim
                (apply prim (mapcar #'eval-elisp args))
                (signal-elisp-error 'void-function head)))))))
    (t (error "Cannot evaluate: ~A" expr))))
