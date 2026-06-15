(in-package #:holomacs)

(defvar this-command nil)
(defvar last-command nil)
(defvar unread-command-char -1)
(defvar *this-command-keys* "")

(declaim (special this-command last-command unread-command-char *this-command-keys*))

(defun this-command-keys ()
  *this-command-keys*)

(register-primitive 'this-command-keys #'this-command-keys)

(defun get-interactive-prop (sym)
  (let ((plist (symbol-plist sym))
        (found-key nil)
        (found-val nil))
    (loop while plist
          for key = (first plist)
          for val = (second plist)
          do (if (and (symbolp key)
                      (string= (string-upcase (symbol-name key)) "INTERACTIVE"))
                 (progn (setf found-key key
                              found-val val)
                        (return))
                 (setf plist (cddr plist))))
    (values found-key found-val)))

(defun commandp (symbol)
  (multiple-value-bind (pkey spec) (and (symbolp symbol) (get-interactive-prop symbol))
    (when pkey
      ;; Built-in commands store t; user defun commands store :user-interactive or a spec
      (cond
        ((eq spec t) t)
        ((eq spec :user-interactive) (list pkey))
        (t (list pkey spec))))))

(register-primitive 'commandp #'commandp)

(defun read-char ()
  (if (and (integerp unread-command-char) (>= unread-command-char 0))
      (let ((val unread-command-char))
        (setq unread-command-char -1)
        val)
      (let ((char (cl:read-char *standard-input* nil :eof)))
        (if (eq char :eof)
            (error "End of input stream in read-char")
            (char-code char)))))

(register-primitive 'read-char #'read-char)

(defun read-event ()
  (read-char))

(register-primitive 'read-event #'read-event)

(defun self-insert-command ()
  (insert (char-to-string (char-code (aref *this-command-keys* 0)))))

(setf (get 'self-insert-command :interactive) t)
(register-primitive 'self-insert-command #'self-insert-command)

(defun command-execute (cmd &optional record)
  (declare (ignore record))
  (let ((prev this-command))
    (setq this-command cmd)
    (let ((func (if (symbolp cmd)
                     (symbol-function cmd)
                     cmd)))
      (funcall func))
    (setq last-command prev))
  nil)

(register-primitive 'command-execute #'command-execute)

(defun command-loop ()
  (handler-case
      (loop
        (let* ((char (read-char))
               (key-str (char-to-string char))
               (cmd (lookup-key global-map key-str)))
          (setq *this-command-keys* key-str)
          (if cmd
              (command-execute cmd)
              (error "Unbound key: ~A" key-str))))
    (error (err)
      (unless (search "End of input stream" (format nil "~A" err))
        (error err)))))

(register-primitive 'command-loop #'command-loop)
