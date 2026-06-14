(asdf:defsystem #:holomacs
  :description "Holomacs Common Lisp Proof of Concept Engine"
  :author "Antigravity"
  :license "MIT"
  :serial t
  :components ((:file "package")
               (:file "core")
               (:file "primitives")
               (:file "cli")))
