;;; demo_command_loop.el --- Test interactive command loop and keymap routing

;; 1. unread-command-char roundtrip
(message "=== 1. Key Primitives ===")

;; Push ?a into the unread queue and read it back
(setq unread-command-char ?a)
(print (read-char))
(print unread-command-char)

;; Push ?x and confirm read-char returns it
(setq unread-command-char ?x)
(print (read-char))
(print unread-command-char)

;; read-char consumes unread-command-char
(setq unread-command-char ?b)
(print (read-char))

;; 2. Command registrations
(message "=== 2. Command Registration ===")
(defun test-cmd-a ()
  (interactive)
  (insert "A"))

(defun test-cmd-b ()
  (interactive)
  (insert "B"))

(print (commandp 'test-cmd-a))
(print (commandp 'test-cmd-b))
(print (commandp 'self-insert-command))
(print (commandp 'car))

;; Bind keys
(define-key global-map "a" 'test-cmd-a)
(define-key global-map "b" 'test-cmd-b)
(define-key global-map "c" 'self-insert-command)

(use-global-map global-map)

;; 3. Command execution simulation
(message "=== 3. Command Loop ===")
(command-execute 'test-cmd-a)
(command-execute 'test-cmd-b)
(command-execute 'test-cmd-a)
