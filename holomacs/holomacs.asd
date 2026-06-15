(asdf:defsystem #:holomacs
  :description "Holomacs Common Lisp Proof of Concept Engine"
  :author "Antigravity"
  :license "MIT"
  :depends-on (#:cl-ppcre)
  :serial t

  :components ((:file "package")
               (:file "core")
               (:file "transpiler")
               (:file "primitives")
               (:file "command_loop")
               (:file "redisplay")
               (:file "cli")))

(asdf:defsystem #:holomacs/tests
  :description "Holomacs Parachute unit test suite"
  :author "Antigravity"
  :license "MIT"
  :depends-on (#:holomacs #:parachute)
  :serial t
  :pathname "../tests"
  :components ((:file "package")
               (:file "test-reader")
               (:file "test-primitives")
               (:file "test-transpiler")
               (:file "test-command-loop")
               (:file "test-redisplay")
               (:file "test-interactive-args"))
  :perform (asdf:test-op (op c)
             (uiop:symbol-call :parachute :test :holomacs/tests)))


