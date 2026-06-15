(in-package #:holomacs)

;;; =========================================================================
;;; Redisplay formatting and primitives  (RedisplayPrimitiveReq, RedisplayFormattingReq)
;;; =========================================================================

(defun render-buffer-screen (buf)
  "Render the contents of a buffer with its point highlighted using reverse video."
  (let* ((contents (buffer-contents buf))
         (pt (buffer-point buf))
         (len (cl:length contents))
         (out (make-string-output-stream)))
    ;; Print header / top border
    (cl:format out "=== BUFFER: ~A ===~%" (buffer-name buf))
    ;; Print contents character by character, highlighting the cursor point
    (loop for i from 0 to len do
          (cond
            ((= i (1- pt))
             ;; Point location
             (if (< i len)
                 (cl:format out "~C[7m~C~C[0m" #\Esc (aref contents i) #\Esc)
                 (cl:format out "~C[7m ~C[0m" #\Esc #\Esc)))
            ((< i len)
             (write-char (aref contents i) out))))
    (terpri out)
    ;; Print modeline / status bar at the bottom
    (cl:format out "--- ~A (Fundamental) --- Point: ~A ---~%" (buffer-name buf) pt)
    (get-output-stream-string out)))

(defun redisplay ()
  "Redisplay primitive. Clears the screen and draws the current buffer."
  (unless (and (elisp-variable-boundp 'noninteractive)
               (elisp-symbol-value 'noninteractive))
    (let ((screen (render-buffer-screen *current-buffer*)))
      ;; Clear terminal and print screen
      (cl:format *standard-output* "~C[H~C[2J" #\Esc #\Esc)
      (write-string screen *standard-output*)
      (force-output *standard-output*)))
  nil)

(register-primitive 'redisplay #'redisplay)

;;; =========================================================================
;;; Terminal Raw Mode  (TerminalRawModeReq)
;;; =========================================================================

(defun enter-raw-mode ()
  "Put the terminal in raw mode: disable buffering and character echo."
  (uiop:run-program "stty raw -echo" :ignore-error-status t))

(defun exit-raw-mode ()
  "Restore the terminal to normal (sane) echo mode."
  (uiop:run-program "stty sane" :ignore-error-status t))

(defmacro with-raw-terminal-fns ((enter-fn exit-fn) &body body)
  "Execute body, ensuring raw terminal entry and exit functions are run via unwind-protect."
  (let ((g-enter (gensym "ENTER"))
        (g-exit (gensym "EXIT")))
    `(let ((,g-enter ,enter-fn)
           (,g-exit ,exit-fn))
       (funcall ,g-enter)
       (unwind-protect
            (progn ,@body)
         (funcall ,g-exit)))))

(defmacro with-raw-terminal (&body body)
  "Wrapper macro to execute body inside raw terminal mode safely."
  `(with-raw-terminal-fns (#'enter-raw-mode #'exit-raw-mode)
     ,@body))
