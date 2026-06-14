;;; demo_engine.el --- Test suite for core primitives and special forms

;; 1. Equality & List Primitives
(message "=== 1. Equality & Lists ===")
(print (eq 'foo 'foo))
(print (eq 'foo 'bar))
(print (eq "abc" "abc"))
(print (equal "abc" "abc"))
(print (equal '(1 2 (3)) '(1 2 (3))))
(print (equal (vector 1 2 3) (vector 1 2 3)))

(let ((lst (list 1 2 3 4)))
  (print (length lst))
  (print (car lst))
  (print (cdr lst))
  (print (nth 2 lst))
  (print (nthcdr 2 lst))
  (print (cons 0 lst))
  (print (append '(a b) '(c d)))
  (print (nconc lst '(5 6)))
  (print lst))

(let ((alist '((a . 1) ("b" . 2) (c . 3))))
  (print (assq 'a alist))
  (print (assoc "b" alist))
  (print (assoc 'c alist))
  (print (memq 'c '(a b c d))))

;; 2. Type Predicates & Symbols
(message "=== 2. Predicates & Symbols ===")
(print (symbolp 'foo))
(print (symbolp "foo"))
(print (stringp "foo"))
(print (integerp 42))
(print (listp '(1 2)))
(print (listp nil))
(print (arrayp "abc"))
(print (arrayp (vector 1 2)))

(setq my-dyn-symbol 'test-val)
(print (symbol-value 'my-dyn-symbol))
(print (symbolp (make-symbol "uninterned")))
(print (eq (intern "my-dyn-symbol") 'my-dyn-symbol))

;; 3. Control Flow (Catch, Throw, Condition-case, Unwind-protect)
(message "=== 3. Control Flow ===")
(print (catch 'tag1
         (throw 'tag1 'caught-value)
         'not-reached))

(print (condition-case err
           (progn
             (message "In condition-case try block")
             (symbol-value 'void-variable-test))
         (error (message "Caught error: %s" err)
                'error-handled)))

(let ((cleanup-run nil))
  (catch 'tag2
    (unwind-protect
        (progn
          (message "In unwind-protect body")
          (throw 'tag2 'exiting))
      (setq cleanup-run t)))
  (print cleanup-run))

;; 4. Keymap Operations
(message "=== 4. Keymaps ===")
(let ((kmap (make-sparse-keymap)))
  (define-key kmap "a" 'self-insert-command)
  (print (lookup-key kmap "a"))
  (print (lookup-key kmap "b")))

;; 5. File Operations
(message "=== 5. File Operations ===")
(let ((write-buf (get-buffer-create "*temp-write-buffer*")))
  (set-buffer write-buf)
  (insert "Hello from temp file!\n")
  (write-region (point-min) (point-max) "temp_test_file.txt"))
(let ((buf (get-buffer-create "*temp-file-buffer*")))
  (set-buffer buf)
  (insert-file-contents "temp_test_file.txt")
  (print (buffer-substring (point-min) (point-max))))
