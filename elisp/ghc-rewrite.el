;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; ghc-rewrite.el
;;;

;; Author:  Alejandro Serrano <trupill@gmail.com>
;; Created: Jun 17, 2014

;;; Code:

(require 'ghc-func)
(require 'ghc-process)

;; Common code for case splitting and refinement

(defun ghc-perform-rewriting (info)
  "Replace code with new string obtained from ghc-mod"
  (let* ((current-line    (line-number-at-pos))
	 (begin-line      (ghc-sinfo-get-beg-line info))
	 (begin-line-diff (+ 1 (- begin-line current-line)))
	 (begin-line-pos  (line-beginning-position begin-line-diff))
	 (begin-pos       (- (+ begin-line-pos (ghc-sinfo-get-beg-column info)) 1))
	 (end-line        (ghc-sinfo-get-end-line info))
	 (end-line-diff   (+ 1 (- end-line current-line)))
	 (end-line-pos    (line-beginning-position end-line-diff))
	 (end-pos         (- (+ end-line-pos (ghc-sinfo-get-end-column info)) 1)) )
    (delete-region begin-pos end-pos)
    (insert (ghc-sinfo-get-info info)) )
  )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Case splitting
;;;

(ghc-defstruct sinfo beg-line beg-column end-line end-column info)

(defun ghc-case-split ()
  "Split the variable at point into its possible constructors"
  (interactive)
  (let ((info (ghc-obtain-case-split)))
    (if (null info)
	(message "Cannot split in cases")
        (ghc-perform-rewriting info)) ))

(defun ghc-obtain-case-split ()
  (let* ((ln (int-to-string (line-number-at-pos)))
	 (cn (int-to-string (1+ (current-column))))
	 (file (buffer-file-name))
	 (cmd (format "split %s %s %s\n" file ln cn)))
    (ghc-sync-process cmd)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Refinement
;;;

(defun ghc-refine ()
  "Refine a hole using a user-specified function"
  (interactive)
  (let ((info (ghc-obtain-refine (read-string "Refine with: "))))
    (if (null info)
	(message "Cannot refine")
	(ghc-perform-rewriting info)) ))

(defun ghc-obtain-refine (expr)
  (let* ((ln (int-to-string (line-number-at-pos)))
	 (cn (int-to-string (1+ (current-column))))
	 (file (buffer-file-name))
	 (cmd (format "refine %s %s %s %s\n" file ln cn expr)))
    (ghc-sync-process cmd)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Auto
;;;

(defun ghc-perform-rewriting-auto (info)
  "Replace code with new string obtained from ghc-mod from auto mode"
  (let* ((current-line    (line-number-at-pos))
	 (begin-line      (ghc-sinfo-get-beg-line info))
	 (begin-line-diff (+ 1 (- begin-line current-line)))
	 (begin-line-pos  (line-beginning-position begin-line-diff))
	 (begin-pos       (- (+ begin-line-pos (ghc-sinfo-get-beg-column info)) 1))
	 (end-line        (ghc-sinfo-get-end-line info))
	 (end-line-diff   (+ 1 (- end-line current-line)))
	 (end-line-pos    (line-beginning-position end-line-diff))
	 (end-pos         (- (+ end-line-pos (ghc-sinfo-get-end-column info)) 1)) )
    (delete-region begin-pos end-pos)
    (insert (first (ghc-sinfo-get-info info))) )
  )

(defun ghc-show-auto-messages (msgs)
  (ghc-display-with-name nil
    (lambda ()
      (insert "Possible completions:\n")
      (mapc (lambda (x) (insert "- " x "\n")) msgs))
    "*Djinn completions*"))

(defun ghc-auto ()
  "Try to automatically fill the contents of a hole"
  (interactive)
  (let ((info (ghc-obtain-auto)))
    (if (null info)
	(message "No automatic completions found")
        (if (= (length (ghc-sinfo-get-info info)) 1)
            (ghc-perform-rewriting-auto info)
            (ghc-show-auto-messages (ghc-sinfo-get-info info))))))

(defun ghc-obtain-auto ()
  (let* ((ln (int-to-string (line-number-at-pos)))
	 (cn (int-to-string (1+ (current-column))))
	 (file (buffer-file-name))
	 (cmd (format "auto %s %s %s\n" file ln cn)))
    (ghc-sync-process cmd)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Initial code from signature
;;;

(ghc-defstruct icsinfo sort pos fns)

(defun ghc-initial-code-from-signature ()
  "Include initial code from a function signature or instance declaration"
  (interactive)
  (let ((info (ghc-obtain-initial-code-from-signature)))
    (if (null info)
	(message "Cannot obtain initial code")
	(let* ((ln-current (line-number-at-pos))
	       (sort (ghc-icsinfo-get-sort info))
	       (pos (ghc-icsinfo-get-pos info))
	       (ln-end (ghc-sinfo-get-end-line pos))
	       (ln-diff (+ 1 (- ln-end ln-current)))
	       (fns-to-insert (ghc-icsinfo-get-fns info)))
	  (goto-char (line-end-position ln-diff))
	  (dolist (fn-to-insert fns-to-insert)
	    (if (equal sort "function")
		(newline)
	        (newline-and-indent))
	    (insert fn-to-insert))))))

(defun ghc-obtain-initial-code-from-signature ()
  (let* ((ln (int-to-string (line-number-at-pos)))
	 (cn (int-to-string (1+ (current-column))))
	 (file (buffer-file-name))
	 (cmd (format "sig %s %s %s\n" file ln cn)))
    (ghc-sync-process cmd)))

(provide 'ghc-rewrite)
