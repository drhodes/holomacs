(in-package #:holomacs/tests)

;;; =========================================================================
;;; Helper: read one form from a string using the Elisp readtable
;;; =========================================================================

(defun read-elisp (str)
  (let ((*readtable* (h:make-elisp-readtable))
        (*package*   (find-package '#:holomacs)))
    (read-from-string str)))

;;; =========================================================================
;;; Char literal reader  (ReaderCharLiteralTestReq)
;;; =========================================================================

(define-test char-literal-plain
  (is = 97  (read-elisp "?a"))
  (is = 90  (read-elisp "?Z"))
  (is = 48  (read-elisp "?0"))
  (is = 32  (read-elisp "? ")))

(define-test char-literal-escapes
  (is = 10  (read-elisp "?\\n"))
  (is =  9  (read-elisp "?\\t"))
  (is = 13  (read-elisp "?\\r"))
  (is = 92  (read-elisp "?\\\\")))

;;; =========================================================================
;;; String literal reader  (ReaderStringLiteralTestReq)
;;; =========================================================================

(define-test string-literal-plain
  (is string= "hello" (read-elisp "\"hello\"")))

(define-test string-literal-escapes
  (is string= (format nil "a~cb" #\Newline) (read-elisp "\"a\\nb\""))
  (is string= (format nil "a~cb" #\Tab)     (read-elisp "\"a\\tb\""))
  (is string= "a\\b"                         (read-elisp "\"a\\\\b\"")))

;;; =========================================================================
;;; Readtable composition  (ReaderReadtableCompositionTestReq)
;;; =========================================================================

(define-test readtable-composition
  "Both readers active simultaneously; standard CL tokens unaffected."
  (let ((result (read-elisp "(?a \"hello\" 42 nil t)")))
    (is =        97       (first  result))
    (is string=  "hello"  (second result))
    (is =        42       (third  result))
    (is eq       nil      (fourth result))
    (is eq       t        (fifth  result))))
