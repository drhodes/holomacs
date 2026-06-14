(in-package #:holomacs)

(defun transpile-elisp (expr)
  "Recursively transpile an Elisp expression into a Common Lisp expression."
  (cond
    ((null expr) nil)
    ((eq expr 't) 't)
    ((symbolp expr)
     (cond
       ((or (null expr) (eq expr 't) (keywordp expr))
        expr)
       (t
        `(elisp-symbol-value ',expr))))
    ((or (numberp expr) (stringp expr) (characterp expr))
     expr)
    ((consp expr)
     (let ((head (car expr))
           (args (cdr expr)))
        (case head
          (quote
           `(quote ,(car args)))
          (setq
           (let (setq-forms)
             (loop while args do
                   (let ((var (pop args))
                         (val-expr (pop args)))
                     (push `(elisp-set-variable ',var ,(transpile-elisp val-expr)) setq-forms)))
             (if (null (cdr setq-forms))
                 (car setq-forms)
                 `(progn ,@(nreverse setq-forms)))))
         (progn
          `(progn ,@(mapcar #'transpile-elisp args)))
         (if
          `(if ,(transpile-elisp (first args))
               ,(transpile-elisp (second args))
               ,(if (cddr args)
                    `(progn ,@(mapcar #'transpile-elisp (cddr args)))
                    nil)))
         (cond
          `(cond ,@(mapcar (lambda (clause)
                             (mapcar #'transpile-elisp clause))
                           args)))
         (let
          (let* ((bindings (first args))
                 (body (rest args))
                 (cl-bindings (mapcar (lambda (b)
                                        (if (listp b)
                                            (list (first b) (transpile-elisp (second b)))
                                            b))
                                      bindings))
                 (vars (mapcar (lambda (b) (if (listp b) (first b) b)) bindings)))
            `(let ,cl-bindings
               (declare (special ,@vars))
               ,@(mapcar #'transpile-elisp body))))
         (let*
          (let* ((bindings (first args))
                 (body (rest args))
                 (cl-bindings (mapcar (lambda (b)
                                        (if (listp b)
                                            (list (first b) (transpile-elisp (second b)))
                                            b))
                                      bindings))
                 (vars (mapcar (lambda (b) (if (listp b) (first b) b)) bindings)))
            `(let* ,cl-bindings
               (declare (special ,@vars))
               ,@(mapcar #'transpile-elisp body))))
         (defun
          (let* ((name (first args))
                 (params (second args))
                 (body (cddr args))
                 (first-form (first body))
                 (is-interactive (and (consp first-form) (eq (car first-form) 'interactive)))
                 (interactive-spec (when is-interactive (cdr first-form)))
                 (real-body (if is-interactive (rest body) body)))
            `(progn
               (defun ,name ,params
                 (declare (special ,@params))
                 ,@(mapcar #'transpile-elisp real-body))
               ,(when is-interactive
                  `(setf (get ',name 'interactive)
                         ,(if (null interactive-spec)
                              :user-interactive
                              (first interactive-spec))))
               ',name)))
         (while
          `(loop while ,(transpile-elisp (first args))
                 do (progn ,@(mapcar #'transpile-elisp (rest args)))))
         (catch
          `(catch ,(transpile-elisp (first args))
             ,@(mapcar #'transpile-elisp (rest args))))
         (throw
          `(throw ,(transpile-elisp (first args)) ,(transpile-elisp (second args))))
         (condition-case
          (let ((var (first args))
                (bodyform (second args))
                (handlers (cddr args)))
            `(handler-case ,(transpile-elisp bodyform)
               (elisp-error (c)
                 (let ,(when var
                         (list (list var `(cons (elisp-error-symbol c) (elisp-error-data c)))))
                   ,@(when var
                       (list `(declare (special ,var))))
                   ,@(let ((matching-handler (find 'error handlers :key #'first)))
                       (if matching-handler
                           (mapcar #'transpile-elisp (rest matching-handler))
                           (list `(error c)))))))))
         (unwind-protect
          `(unwind-protect ,(transpile-elisp (first args))
             ,@(mapcar #'transpile-elisp (rest args))))
         (t
          `(,head ,@(mapcar #'transpile-elisp args))))))
    (t (error "Cannot transpile: ~A" expr))))

(defun compile-elisp-form (expr)
  "Transpile and evaluate/compile a single Elisp form."
  (let ((cl-form (transpile-elisp expr)))
    (eval cl-form)))

(defun load-elisp-file (filename)
  "Load, transpile, and compile/execute an Elisp file."
  (let ((*package* (find-package '#:holomacs))
        (*readtable* (make-elisp-readtable)))
    (with-open-file (stream filename :direction :input)
      (loop
        (let ((expr (read stream nil :eof)))
          (if (eq expr :eof)
              (return)
              (compile-elisp-form expr)))))))
