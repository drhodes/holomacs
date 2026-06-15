;;; run_tests.lisp — Load and execute the Holomacs Parachute test suite.
;;; Usage: sbcl --noinform --non-interactive --load run_tests.lisp

;; 1. Bootstrap Quicklisp if available
(let ((ql-init (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname))))
  (when (probe-file ql-init)
    (load ql-init)))

;; 2. Ensure Parachute is loaded
(handler-case
    (progn
      (unless (find-package :parachute)
        #+quicklisp (ql:quickload :parachute :silent t)
        #-quicklisp (asdf:load-system :parachute)))
  (error (e)
    (format *error-output* "~&[run_tests] ERROR: Could not load Parachute: ~A~%" e)
    (uiop:quit 1)))

;; 3. Load the holomacs main system
(handler-case
    (progn
      (load (merge-pathnames "holomacs/holomacs.asd"
                             (uiop:getcwd)))
      (asdf:load-system :holomacs :silent t))
  (error (e)
    (format *error-output* "~&[run_tests] ERROR: Could not load :holomacs: ~A~%" e)
    (uiop:quit 1)))

;; 4. Load the test system
(handler-case
    (asdf:load-system :holomacs/tests :silent t)
  (error (e)
    (format *error-output* "~&[run_tests] ERROR: Could not load :holomacs/tests: ~A~%" e)
    (uiop:quit 1)))

;; 5. Run all tests; exit with appropriate code
(let ((results (parachute:test :holomacs/tests)))
  (uiop:quit (if (parachute:status results) 0 1)))
