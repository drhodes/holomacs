(in-package #:holomacs/tests)

;;; =========================================================================
;;; unread-command-char queue  (UnreadCommandCharTestReq)
;;; =========================================================================

(define-test unread-command-char-initial
  (h:init-elisp-state)
  (is = -1 h:unread-command-char))

(define-test unread-command-char-roundtrip
  "Setting unread-command-char makes read-char return that value and resets it."
  (h:init-elisp-state)
  (setf h:unread-command-char 97)
  (is = 97 (h:read-char))
  (is = -1 h:unread-command-char))

;;; =========================================================================
;;; commandp sentinels  (CommandpTestReq)
;;; =========================================================================

(define-test commandp-builtin
  "Built-in marker t -> commandp returns t."
  (let ((sym (intern "TEST-BUILTIN-CMD" '#:holomacs)))
    (setf (get sym :interactive) t)
    (is eq t (h:commandp sym))
    (remprop sym :interactive)))

(define-test commandp-user-interactive
  ":user-interactive sentinel -> commandp returns (interactive)."
  (let ((sym (intern "TEST-USER-CMD" '#:holomacs)))
    (setf (get sym :interactive) :user-interactive)
    (is equal '(:interactive) (h:commandp sym))
    (remprop sym :interactive)))

(define-test commandp-spec-string
  "Spec string -> commandp returns (interactive spec)."
  (let ((sym (intern "TEST-SPEC-CMD" '#:holomacs)))
    (setf (get sym :interactive) "r")
    (is equal '(:interactive "r") (h:commandp sym))
    (remprop sym :interactive)))

(define-test commandp-none
  "No interactive property -> commandp returns nil."
  (is eq nil (h:commandp 'holomacs::car))
  (is eq nil (h:commandp 'holomacs::cons)))

;;; =========================================================================
;;; command-execute dispatch  (CommandExecuteTestReq)
;;; =========================================================================

(define-test command-execute-invokes-function
  "command-execute calls the symbol's function."
  (h:init-elisp-state)
  (let* ((called nil)
         (sym (intern "TEST-EXEC-CMD" '#:holomacs)))
    (setf (symbol-function sym) (lambda () (setq called t)))
    (setf (get sym :interactive) t)
    (h:command-execute sym)
    (is eq t called)))

(define-test command-execute-updates-this-command
  "this-command is set to the executing command symbol after execution."
  (h:init-elisp-state)
  (let ((sym (intern "TEST-THIS-CMD" '#:holomacs)))
    (setf (symbol-function sym) (lambda () nil))
    (setf (get sym :interactive) t)
    (h:command-execute sym)
    (is eq sym h:this-command)))

(define-test command-execute-updates-last-command
  "last-command reflects the command executed before the most recent one."
  (h:init-elisp-state)
  (let ((sym1 (intern "TEST-CMD-AA" '#:holomacs))
        (sym2 (intern "TEST-CMD-BB" '#:holomacs)))
    (setf (symbol-function sym1) (lambda () nil))
    (setf (symbol-function sym2) (lambda () nil))
    (setf (get sym1 :interactive) t)
    (setf (get sym2 :interactive) t)
    (h:command-execute sym1)
    (h:command-execute sym2)
    ;; After sym2 runs, last-command should be sym1
    (is eq sym1 h:last-command)))

;;; =========================================================================
;;; self-insert-command  (SelfInsertCommandTestReq)
;;; =========================================================================

(define-test self-insert-command-inserts-char
  "self-insert-command inserts the character named by *this-command-keys*."
  (h:init-elisp-state)
  (setf h:*this-command-keys* "x")
  (let ((pt-before (h:point)))
    (h:self-insert-command)
    (is = (1+ pt-before) (h:point))
    (is string= "x" (h:buffer-substring 1 2))))
