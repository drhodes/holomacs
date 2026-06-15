(in-package #:holomacs/tests)

;;; Helper: run primitives in a fresh Elisp state
(defmacro with-fresh-state (&body body)
  `(progn (h:init-elisp-state) ,@body))

;;; =========================================================================
;;; char-to-string  (PrimCharToStringTestReq)
;;; =========================================================================

(define-test char-to-string
  (is string= "A" (h:char-to-string 65))
  (is string= "a" (h:char-to-string 97))
  (is string= (string #\Newline) (h:char-to-string 10)))

;;; =========================================================================
;;; string-to-char  (PrimStringToCharTestReq)
;;; =========================================================================

(define-test string-to-char
  (is = 65  (h:string-to-char "A"))
  (is = 104 (h:string-to-char "hello"))
  (is = 0   (h:string-to-char "")))

;;; =========================================================================
;;; int-to-string  (PrimIntToStringTestReq)
;;; =========================================================================

(define-test int-to-string
  (is string= "0"  (h:int-to-string 0))
  (is string= "42" (h:int-to-string 42))
  (is string= "-7" (h:int-to-string -7)))

;;; =========================================================================
;;; concat  (PrimConcatTestReq)
;;; =========================================================================

(define-test concat
  (is string= "abc"         (h:concat "a" "b" "c"))
  (is string= ""            (h:concat))
  (is string= "hello world" (h:concat "hello" " " "world")))

;;; =========================================================================
;;; substring  (PrimSubstringTestReq)
;;; =========================================================================

(define-test substring
  (is string= "el"    (h:substring "hello" 1 3))
  (is string= "llo"   (h:substring "hello" 2))
  (is string= "hello" (h:substring "hello" 0 5)))

;;; =========================================================================
;;; define-key / lookup-key  (PrimDefineKeyTestReq, PrimLookupKeyTestReq)
;;; =========================================================================

(define-test define-and-lookup-key
  (with-fresh-state
    (let ((map (h:make-sparse-keymap)))
      ;; Unbound key returns nil
      (is eq nil (h:lookup-key map "a"))
      ;; Bind and look up (use equal: symbol may be in holomacs package)
      (h:define-key map "a" 'holomacs::my-cmd)
      (is equal 'holomacs::my-cmd (h:lookup-key map "a"))
      ;; Case sensitivity
      (is eq nil (h:lookup-key map "A"))
      ;; Re-bind replaces
      (h:define-key map "a" 'holomacs::other-cmd)
      (is equal 'holomacs::other-cmd (h:lookup-key map "a"))
      ;; Unbind with nil
      (h:define-key map "a" nil)
      (is eq nil (h:lookup-key map "a")))))

;;; =========================================================================
;;; Symbol / variable roundtrip  (SymbolValueRoundtripTestReq)
;;; =========================================================================

(define-test symbol-value-roundtrip
  (with-fresh-state
    ;; Set and get a global variable
    (h:elisp-set-variable 'test-var-xyz 42)
    (is = 42 (h:elisp-symbol-value 'test-var-xyz))
    ;; Void variable signals an error
    (fail (h:elisp-symbol-value 'definitely-not-bound-xyz))))
