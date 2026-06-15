(in-package #:holomacs/tests)

;;; =========================================================================
;;; Call Interactively Unit Tests  (CallInteractivelyUnitTestReq)
;;; =========================================================================

(define-test call-interactively-empty
  "Calling a command with no interactive spec string."
  (h:init-elisp-state)
  (let ((called nil))
    (setf (symbol-function 'my-empty-cmd)
          (lambda () (setf called t)))
    (setf (get 'my-empty-cmd :interactive) :user-interactive)
    (h::call-interactively 'my-empty-cmd)
    (is eq t called)))

(define-test call-interactively-region
  "Calling a command with region interactive spec 'r'."
  (h:init-elisp-state)
  (h:insert "abcdef")
  (h::elisp-goto-char 2)
  ;; Set the buffer's mark (internals)
  (setf (h::buffer-mark h::*current-buffer*) 5)
  (let ((args nil))
    (setf (symbol-function 'my-region-cmd)
          (lambda (start end) (setf args (list start end))))
    (setf (get 'my-region-cmd :interactive) "r")
    (h::call-interactively 'my-region-cmd)
    (is equal '(2 5) args)))

(define-test call-interactively-prefix
  "Calling a command with prefix interactive spec 'P'."
  (h:init-elisp-state)
  ;; Set global prefix arg
  (h::elisp-set-variable 'h::current-prefix-arg 4)
  (let ((arg-received nil))
    (setf (symbol-function 'my-prefix-cmd)
          (lambda (p) (setf arg-received p)))
    (setf (get 'my-prefix-cmd :interactive) "P")
    (h::call-interactively 'my-prefix-cmd)
    (is = 4 arg-received)))


(define-test call-interactively-prompt-string
  "Calling a command with a prompt string spec like 's'."
  (h:init-elisp-state)
  (let ((input-received nil))
    (setf (symbol-function 'my-prompt-cmd)
          (lambda (s) (setf input-received s)))
    (setf (get 'my-prompt-cmd :interactive) "sPrompt: ")
    ;; Mock standard input stream
    (with-input-from-string (*standard-input* "hello-prompt-input
")
      (h::call-interactively 'my-prompt-cmd))
    (is string= "hello-prompt-input" input-received)))
