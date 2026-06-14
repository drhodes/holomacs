(in-package #:holomacs)

(defun run-file (filename)
  (init-elisp-state)
  (let ((*package* (find-package '#:holomacs)))
    (with-open-file (stream filename :direction :input)
      (handler-case
          (loop
            (let ((expr (read stream nil :eof)))
              (if (eq expr :eof)
                  (return)
                  (eval-elisp expr))))
        (error (err)
          (format *error-output* "Error during execution: ~A~%" err)
          (uiop:quit 1)))))
  ;; Print captured output to standard output
  (write-string (get-output-stream-string *elisp-output*)))
