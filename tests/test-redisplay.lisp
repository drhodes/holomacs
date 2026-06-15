(in-package #:holomacs/tests)

;;; =========================================================================
;;; Redisplay Primitive  (RedisplayPrimitiveReq)
;;; =========================================================================

(define-test redisplay-noninteractive-noop
  "In noninteractive mode, redisplay should return nil and do nothing."
  (h:init-elisp-state)
  ;; Set noninteractive variable (in holomacs package) to t
  (h:elisp-set-variable 'h::noninteractive t)
  (let ((out (with-output-to-string (*standard-output*)
               (h:redisplay))))
    (is string= "" out)))

;;; =========================================================================
;;; Redisplay Formatting  (RedisplayFormattingReq)
;;; =========================================================================

(define-test redisplay-formatting-cursor-at-char
  "Cursor highlighting when point is at a character in the buffer."
  (h:init-elisp-state)
  (h:elisp-set-variable 'h::noninteractive nil)
  (h:insert "hello")
  ;; Set point to 1 (at 'h')
  (h::elisp-goto-char 1)
  (let ((screen (h::render-buffer-screen h::*current-buffer*)))
    ;; Check that it contains highlighted 'h': ESC [7m h ESC [0m
    (is eq t (not (null (search (format nil "~C[7mh~C[0m" #\Esc #\Esc) screen))))
    ;; Check that it contains buffer name
    (is eq t (not (null (search "*scratch*" screen))))))

(define-test redisplay-formatting-cursor-at-end
  "Cursor highlighting when point is at the end of the buffer (empty space)."
  (h:init-elisp-state)
  (h:elisp-set-variable 'h::noninteractive nil)
  (h:insert "abc")
  (h::elisp-goto-char 4)
  (let ((screen (h::render-buffer-screen h::*current-buffer*)))
    ;; Check that it contains highlighted space: ESC [7m space ESC [0m
    (is eq t (not (null (search (format nil "~C[7m ~C[0m" #\Esc #\Esc) screen))))))

;;; =========================================================================
;;; Terminal Raw Mode  (TerminalRawModeReq)
;;; =========================================================================

(define-test terminal-raw-mode-unwind-protect
  "Terminal raw mode wrapper restores settings even if body throws an error."
  (let ((restored nil)
        (raw-entered nil))
    (flet ((enter-raw () (setf raw-entered t))
           (exit-raw () (setf restored t)))
      ;; Wrap raw execution with a mock wrapper
      (h:init-elisp-state)
      (fail
        (h::with-raw-terminal-fns (#'enter-raw #'exit-raw)
          (is eq t raw-entered)
          (error "Simulated error in raw mode body")))
      (is eq t restored))))
