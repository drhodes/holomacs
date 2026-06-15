(in-package #:holomacs/tests)

;;; =========================================================================
;;; Atom roundtrip  (TranspilerAtomRoundtripTestReq)
;;; =========================================================================

(define-test transpile-atoms
  (is =       42    (h:transpile-elisp 42))
  (is string= "hi"  (h:transpile-elisp "hi"))
  (is eq      nil   (h:transpile-elisp nil))
  (is eq      t     (h:transpile-elisp t)))

;;; =========================================================================
;;; setq form  (TranspilerSetqFormTestReq)
;;; =========================================================================

(define-test transpile-setq-single
  "Single setq becomes one elisp-set-variable call."
  (let ((form (h:transpile-elisp '(holomacs::setq holomacs::x 1))))
    ;; form: (holomacs::elisp-set-variable 'holomacs::x 1)
    (is eq 'holomacs::elisp-set-variable (first form))
    ;; second element is the quoted var name
    (is equal '(quote holomacs::x) (second form))))

(define-test transpile-setq-multi
  "Multi-assignment setq becomes a progn of two set calls."
  (let ((form (h:transpile-elisp '(holomacs::setq holomacs::a 1 holomacs::b 2))))
    (is eq 'progn (first form))
    (is = 2 (length (rest form)))))

;;; =========================================================================
;;; defun + (interactive) sentinel  (TranspilerDefunInteractiveTestReq)
;;; =========================================================================

(define-test transpile-defun-interactive-empty
  "Empty (interactive) stores :user-interactive sentinel."
  (h:init-elisp-state)
  ;; compile-elisp-form uses the holomacs package, so the defun name
  ;; will be interned there
  (h:compile-elisp-form
   '(defun my-test-cmd-ii () (interactive) (holomacs::insert "x")))
  (is eq :user-interactive
      (get (find-symbol "MY-TEST-CMD-II" '#:holomacs) :interactive)))

(define-test transpile-defun-interactive-spec
  "Parameterized (interactive \"r\") stores the spec string."
  (h:init-elisp-state)
  (h:compile-elisp-form
   '(defun my-region-cmd-ii (b e) (interactive "r") b))
  (is string= "r"
      (get (find-symbol "MY-REGION-CMD-II" '#:holomacs) :interactive)))

(define-test transpile-defun-no-interactive
  "defun without (interactive) leaves the property unset."
  (h:init-elisp-state)
  (h:compile-elisp-form '(defun plain-func-ii (x) x))
  (is eq nil (get (find-symbol "PLAIN-FUNC-II" '#:holomacs) :interactive)))

;;; =========================================================================
;;; Char literal end-to-end  (TranspilerCharLiteralTestReq)
;;; =========================================================================

(define-test char-literal-end-to-end
  "?a read through elisp readtable and compiled evaluates to 97."
  (h:init-elisp-state)
  (let ((*readtable* (h:make-elisp-readtable))
        (*package*   (find-package '#:holomacs)))
    (is = 97 (h:compile-elisp-form (read-from-string "?a")))
    (is = 10 (h:compile-elisp-form (read-from-string "?\\n")))))
