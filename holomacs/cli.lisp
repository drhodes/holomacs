(in-package #:holomacs)

(defun elisp-string-reader (stream char)
  (declare (ignore char))
  (let ((out (make-string-output-stream)))
    (loop for c = (read-char stream t nil t)
          until (char= c #\")
          do (if (char= c #\\)
                 (let ((next (read-char stream t nil t)))
                   (case next
                     (#\n (write-char #\Newline out))
                     (#\t (write-char #\Tab out))
                     (#\r (write-char #\Return out))
                     (t (write-char next out))))
                 (write-char c out)))
    (get-output-stream-string out)))

(defun run-file (filename)
  (init-elisp-state)
  (handler-case
      (load-elisp-file filename)
    (error (err)
      (format *error-output* "Error during execution: ~A~%" err)
      (uiop:quit 1)))
  ;; Print captured output to standard output
  (write-string (get-output-stream-string *elisp-output*)))

(defun run-string (str)
  (init-elisp-state)
  (let ((*package* (find-package '#:holomacs))
        (*readtable* (copy-readtable nil)))
    (set-macro-character #\" #'elisp-string-reader)
    (with-input-from-string (stream str)
      (handler-case
          (loop
            (let ((expr (read stream nil :eof)))
              (if (eq expr :eof)
                  (return)
                  (compile-elisp-form expr))))
        (error (err)
          (format *error-output* "Error during execution: ~A~%" err)
          (uiop:quit 1)))))
  (write-string (get-output-stream-string *elisp-output*)))
