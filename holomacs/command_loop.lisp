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
                      (cl:string= (string-upcase (symbol-name key)) "INTERACTIVE"))
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
            (cl:error "End of input stream in read-char")
            (char-code char)))))

(register-primitive 'read-char #'read-char)

(defun read-event ()
  (read-char))

(register-primitive 'read-event #'read-event)

(defun self-insert-command ()
  (insert (char-to-string (char-code (aref *this-command-keys* 0)))))

(setf (get 'self-insert-command :interactive) t)
(register-primitive 'self-insert-command #'self-insert-command)

(defun call-interactively (cmd &optional recordkeys keys)
  (declare (cl:ignore recordkeys keys))
  (let* ((func (if (symbolp cmd) (symbol-function cmd) cmd))
         (interactive-prop (and (symbolp cmd) (nth-value 1 (get-interactive-prop cmd)))))
    (cond
      ((null interactive-prop)
       (cl:error "Wrong type argument: commandp ~A" cmd))
      ((or (eq interactive-prop t) (eq interactive-prop :user-interactive))
       ;; No arguments
       (funcall func))
      ((stringp interactive-prop)
       ;; Parse interactive specification string
       (let ((args nil)
             (spec-str interactive-prop)
             (start 0)
             (len (cl:length interactive-prop)))
         (loop while (< start len) do
               (let* ((code (char spec-str start))
                      (nl-pos (position #\Newline spec-str :start (1+ start)))
                      (end (or nl-pos len))
                      (prompt (subseq spec-str (1+ start) end)))
                 (setq start (if nl-pos (1+ nl-pos) len))
                 (case code
                   (#\r
                    ;; Region: start & end (min & max of point & mark)
                    (let ((pt (buffer-point *current-buffer*))
                          (mk (or (buffer-mark *current-buffer*)
                                  (signal-elisp-error 'mark-inactive))))
                      (push (min pt mk) args)
                      (push (max pt mk) args)))
                   (#\P
                    ;; Raw prefix arg
                    (push (elisp-symbol-value 'current-prefix-arg) args))
                   ((#\s #\f #\B)
                    ;; Read string or prompt from stdin
                    (unless (and (elisp-variable-boundp 'noninteractive)
                                 (elisp-symbol-value 'noninteractive))
                      (cl:format *error-output* "~A" prompt)
                      (force-output *error-output*))
                    (let ((val (cl:read-line *standard-input* nil nil)))
                      ;; strip trailing return if any (windows line endings)
                      (when (and val (> (cl:length val) 0) (char= (char val (1- (cl:length val))) #\Return))
                        (setf val (subseq val 0 (1- (cl:length val)))))
                      (push (or val "") args)))
                   (t
                    (cl:error "Unsupported interactive code ~S" code)))))
         (apply func (nreverse args))))
      (t
       (cl:error "Invalid interactive property ~S" interactive-prop)))))

(register-primitive 'call-interactively #'call-interactively)

(defun command-execute (cmd &optional record)
  (declare (cl:ignore record))
  (let ((prev this-command))
    (setq this-command cmd)
    (if (commandp cmd)
        (call-interactively cmd)
        (let ((func (if (symbolp cmd)
                         (symbol-function cmd)
                         cmd)))
          (funcall func)))
    (setq last-command prev))
  nil)

(register-primitive 'command-execute #'command-execute)


(defun read-key-sequence (map)
  "Recursively read keys and resolve prefix keymaps. (PrefixKeymapReq)"
  (let* ((char (read-char))
         (key-str (char-to-string char))
         (binding (lookup-key map key-str)))
    (cond
      ((null binding)
       (values nil key-str))
      ((and (consp binding) (eq (car binding) 'keymap))
       (multiple-value-bind (cmd sub-seq) (read-key-sequence binding)
         (values cmd (concat key-str sub-seq))))
      (t
       (values binding key-str)))))

(defun command-loop ()
  (handler-case
      (loop
        (multiple-value-bind (cmd key-seq) (read-key-sequence global-map)
          ;; Track full key sequence (KeySequenceTrackingReq)
          (setq *this-command-keys* key-seq)
          (if cmd
              (command-execute cmd)
              (cl:error "Unbound key: ~A" key-seq))))
    (cl:error (err)
      (unless (search "End of input stream" (cl:format nil "~A" err))
        (cl:error err)))))

(register-primitive 'command-loop #'command-loop)

