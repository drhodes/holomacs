(defpackage #:holomacs
  (:use #:cl)
  (:shadow #:equal #:length #:member #:assoc #:append #:print
           #:symbol-value #:symbol-function #:boundp #:fboundp #:intern #:make-symbol
           #:read-char)
  (:export #:run-file
           #:run-string
           #:transpile-elisp
           #:compile-elisp-form
           #:load-elisp-file))
