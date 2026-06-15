(defpackage #:holomacs
  (:use #:cl)
  (:shadow #:equal #:length #:member #:assoc #:append #:print
           #:symbol-value #:symbol-function #:boundp #:fboundp #:intern #:make-symbol
           #:read-char #:make-hash-table #:gethash #:remhash)
  (:export ;; Public API
           #:run-file
           #:run-string
           #:transpile-elisp
           #:compile-elisp-form
           #:load-elisp-file
           ;; Reader
           #:make-elisp-readtable
           ;; Engine / state
           #:init-elisp-state
           #:elisp-symbol-value
           #:elisp-set-variable
           ;; Primitives (for unit testing)
           #:char-to-string
           #:string-to-char
           #:int-to-string
           #:concat
           #:substring
           #:make-sparse-keymap
           #:define-key
           #:lookup-key
           #:point
           #:buffer-substring
           #:insert
           ;; Command loop
           #:unread-command-char
           #:*this-command-keys*
           #:this-command
           #:last-command
           #:read-char
           #:commandp
           #:command-execute
           #:self-insert-command
           #:redisplay
           #:call-interactively
           #:read-key-sequence
           #:command-loop
           #:bobp
           #:bolp
           #:eobp
           #:eolp
           #:char-after
           #:buffer-string
           #:buffer-size
           #:string-match
           #:match-beginning
           #:match-end
           #:replace-match
           #:search-forward
           #:search-backward
           #:skip-chars-forward
           #:skip-chars-backward
           ;; Case conversion
           #:downcase
           #:upcase
           #:capitalize
           #:downcase-region
           #:upcase-region
           #:capitalize-region
           ;; regex looking-at
           #:looking-at
           ;; hash tables
           #:make-hash-table
           #:gethash
           #:puthash
           #:remhash))

