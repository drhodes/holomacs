(in-package #:holomacs)

(defun elisp-string-reader (stream char)
  (declare (cl:ignore char))
  (let ((out (make-string-output-stream)))
    (loop for c = (cl:read-char stream t nil t)
          until (char= c #\")
          do (if (char= c #\\)
                 (let ((next (cl:read-char stream t nil t)))
                   (case next
                     (#\n (write-char #\Newline out))
                     (#\t (write-char #\Tab out))
                     (#\r (write-char #\Return out))
                     (t (write-char next out))))
                 (write-char c out)))
    (get-output-stream-string out)))

(defun elisp-char-reader (stream char)
  "Reader macro for Elisp ?x character literals. Returns the integer char code."
  (declare (cl:ignore char))
  (let ((next (cl:read-char stream t nil t)))
    (if (char= next #\\)
        ;; Escape sequence: ?\n ?\t ?\r ?\\ etc.
        (let ((escaped (cl:read-char stream t nil t)))
          (char-code
           (case escaped
             (#\n #\Newline)
             (#\t #\Tab)
             (#\r #\Return)
             (#\0 #\Null)
             (t escaped))))
        ;; Plain ?x → char-code of x
        (char-code next))))

(defun make-elisp-readtable ()
  "Build a readtable with Elisp-specific reader macros."
  (let ((rt (copy-readtable nil)))
    (set-macro-character #\" #'elisp-string-reader nil rt)
    (set-macro-character #\? #'elisp-char-reader nil rt)
    rt))

(defun run-file (filename)
  (init-elisp-state)
  (handler-case
      (load-elisp-file filename)
    (cl:error (err)
      (cl:format *error-output* "Error during execution: ~A~%" err)
      (uiop:quit 1)))
  ;; Print captured output to standard output
  (write-string (get-output-stream-string *elisp-output*)))

(defun run-string (str)
  (init-elisp-state)
  (let ((*package* (find-package '#:holomacs))
        (*readtable* (make-elisp-readtable)))
    (with-input-from-string (stream str)
      (handler-case
          (loop
            (let ((expr (read stream nil :eof)))
              (if (eq expr :eof)
                  (return)
                  (compile-elisp-form expr))))
        (cl:error (err)
          (cl:format *error-output* "Error during execution: ~A~%" err)
          (uiop:quit 1)))))
  (write-string (get-output-stream-string *elisp-output*)))

(defun run-editor ()
  "Main entry point for running the Holomacs interactive editor in a terminal."
  (init-elisp-state)
  (with-raw-terminal
    (command-loop)))
