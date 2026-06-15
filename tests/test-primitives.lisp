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

;;; =========================================================================
;;; Primitive Coverage (PrimitiveCoverageUnitTestReq)
;;; =========================================================================

(define-test primitive-coverage-bobp-bolp
  (with-fresh-state
    (h:insert "line 1
line 2
line 3")
    ;; Point is at the end. Move to start.
    (h::elisp-goto-char 1)
    (is eq t (h::bobp))
    (is eq t (h::bolp))
    
    ;; Move to middle of line 1
    (h::elisp-goto-char 3)
    (is eq nil (h::bobp))
    (is eq nil (h::bolp))
    
    ;; Move to beginning of line 2 (char 8)
    (h::elisp-goto-char 8)
    (is eq nil (h::bobp))
    (is eq t (h::bolp))))

(define-test primitive-coverage-eobp-eolp
  (with-fresh-state
    (h:insert "abc
def")
    ;; At end of buffer (point is 8)
    (is eq t (h::eobp))
    (is eq t (h::eolp))
    
    ;; Move to middle of line 1
    (h::elisp-goto-char 2)
    (is eq nil (h::eobp))
    (is eq nil (h::eolp))
    
    ;; Move to end of line 1 (char 4, right before newline)
    (h::elisp-goto-char 4)
    (is eq nil (h::eobp))
    (is eq t (h::eolp))))

(define-test primitive-coverage-char-after
  (with-fresh-state
    (h:insert "xyz")
    (is = 120 (h::char-after 1)) ; 'x'
    (is = 121 (h::char-after 2)) ; 'y'
    (is = 122 (h::char-after 3)) ; 'z'
    (is eq nil (h::char-after 4)) ; past eob
    ;; Implicit point
    (h::elisp-goto-char 2)
    (is = 121 (h::char-after))))

(define-test primitive-coverage-buffer-string-size
  (with-fresh-state
    (is string= "" (h::buffer-string))
    (is = 0 (h::buffer-size))
    (h:insert "hello")
    (is string= "hello" (h::buffer-string))
    (is = 5 (h::buffer-size))))

