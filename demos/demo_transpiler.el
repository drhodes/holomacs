;;; demo_transpiler.el --- Comprehensive transpiler verification test

;; 1. Recursive function native compilation
(message "=== 1. Recursive Function ===")
(defun transpile-fib (n)
  (if (< n 2)
      n
    (+ (transpile-fib (- n 1))
       (transpile-fib (- n 2)))))

(print (transpile-fib 10))

;; 2. Dynamic scoping through nested calls
(message "=== 2. Dynamic Scoping ===")
(defun print-dynamic-var ()
  (print transpiler-test-var))

(defun run-scoping-test ()
  (let ((transpiler-test-var 'outer-value))
    (print-dynamic-var)
    (let ((transpiler-test-var 'inner-value))
      (print-dynamic-var))
    (print-dynamic-var)))

(run-scoping-test)

;; 3. Control flow and error handling
(message "=== 3. Control Flow & Errors ===")
(print (catch 'transpile-tag
         (throw 'transpile-tag 'caught-ok)
         'failed))

(print (condition-case err
           (progn
             (symbol-value 'undefined-transpile-var))
         (error 'error-caught-successfully)))
