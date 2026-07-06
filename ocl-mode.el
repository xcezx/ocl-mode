;;; ocl-mode.el --- Major mode for Octopus Configuration Language -*- lexical-binding: t -*-

;; Copyright (C) 2026 xcezx

;; Author: xcezx
;; URL: https://github.com/xcezx/ocl-mode
;; Version: 0.01
;; Package-Requires: ((emacs "27.1"))
;; Keywords: languages

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; ocl-mode provides a major-mode for editing Octopus Configuration
;; Language (OCL) files.  OCL is a subset of HashiCorp Configuration
;; Language (HCL) used by Octopus Deploy for Configuration as Code.
;;
;; OCL files use the `.ocl' extension.  Notably, OCL has no comment
;; syntax, no string interpolation, no expressions/functions, and no
;; exponential number notation -- all of which HCL has.  This mode
;; intentionally does not invent any of those, to stay faithful to
;; what the official OCL parser actually accepts.
;;
;; See:
;;   https://octopus.com/docs/projects/version-control/ocl-file-format
;;   https://octopus.com/docs/projects/version-control/config-as-code-reference
;;   https://github.com/OctopusDeploy/Ocl

;;; Code:

(require 'cl-lib)
(require 'rx)
(require 'smie)

(defgroup ocl nil
  "Major mode for editing Octopus Configuration Language files."
  :prefix "ocl-"
  :group 'languages)

(defcustom ocl-indent-level 4
  "The tab width to use when indenting."
  :type 'integer
  :group 'ocl)

;;; Syntax table

(defvar ocl-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?_ "_" table)
    ;; Attribute/property keys are frequently dotted, e.g.
    ;; `Octopus.Action.Script.ScriptBody'.  Treat `.' as part of the
    ;; symbol so such keys are matched as a single identifier.
    (modify-syntax-entry ?. "_" table)
    (modify-syntax-entry ?= "." table)
    ;; OCL has no comment syntax at all -- do not register any
    ;; comment delimiters here.  See Commentary above.
    table)
  "Syntax table for `ocl-mode'.")

;;; Font-lock

(defconst ocl--block-regexp "^\\s-*[^{]+{")

(defconst ocl--identifier-regexp
  "\\_<\\(\\sw+\\(?:\\s_+\\sw+\\)*\\)\\_>")

(defconst ocl--assignment-regexp
  (concat ocl--identifier-regexp "\\s-*=\\(?:[^>=]\\)"))

(defconst ocl--map-regexp
  (concat ocl--identifier-regexp "\\s-*{"))

(defconst ocl--constant-regexp
  (concat "\\_<" (regexp-opt '("true" "false" "null") t) "\\_>"))

(defconst ocl--number-regexp
  "\\_<-?[0-9]+\\(?:\\.[0-9]+\\)?\\_>")

(defconst ocl-font-lock-keywords
  `((,ocl--assignment-regexp 1 font-lock-variable-name-face)
    (,ocl--constant-regexp . font-lock-constant-face)
    (,ocl--number-regexp . font-lock-constant-face)
    (,ocl--map-regexp 1 font-lock-type-face))
  "Font-lock keywords for `ocl-mode'.")

;;; Syntax-ppss helpers

(defsubst ocl--paren-level ()
  (car (syntax-ppss)))

(defsubst ocl--in-string-or-comment-p ()
  (nth 8 (syntax-ppss)))

;;; Heredoc support via syntax-propertize

(eval-and-compile
  (defconst ocl--here-doc-beg-re
    "[^<]<<-?\\s-*\\\\?\\(\\(?:['\"][^'\"]+['\"]\\|\\sw\\|[-/~._]\\)+\\)\\(\n\\)"))

(defun ocl--font-lock-open-heredoc (start string eol)
  "Determine the syntax of the heredoc starting at START.
STRING is the heredoc tag matched.  EOL is the position of the
newline that ends the heredoc opening line."
  (unless (or (memq (char-before start) '(?< ?>))
              (save-excursion
                (goto-char start)
                (ocl--in-string-or-comment-p)))
    (let ((str (replace-regexp-in-string "['\"]" "" string)))
      (put-text-property eol (1+ eol) 'ocl-here-doc-marker str)
      (prog1 (string-to-syntax "|")
        (goto-char (+ 2 start))))))

(defun ocl--syntax-propertize-heredoc (end)
  "Propertize the heredoc body up to END, if point is inside one."
  (let ((ppss (syntax-ppss)))
    (when (eq t (nth 3 ppss))
      (let ((key (get-text-property (nth 8 ppss) 'ocl-here-doc-marker))
            (case-fold-search nil))
        (when (and key
                   (re-search-forward
                    (concat "^\\(?:[ \t]*\\)" (regexp-quote key) "\\(\n\\)")
                    end 'move))
          (let ((eol (match-beginning 1)))
            (put-text-property eol (1+ eol)
                                'syntax-table (string-to-syntax "|"))))))))

(defun ocl--syntax-propertize-function (start end)
  "Syntax-propertize heredocs between START and END."
  (goto-char start)
  (ocl--syntax-propertize-heredoc end)
  (funcall
   (syntax-propertize-rules
    (ocl--here-doc-beg-re
     (2 (ocl--font-lock-open-heredoc
         (match-beginning 0) (match-string 1) (match-beginning 2))))
    ("\\s|" (0 (prog1 nil (ocl--syntax-propertize-heredoc end)))))
   (point) end))

;;; Indentation

(defconst ocl--smie-grammar
  (smie-prec2->grammar
   (smie-bnf->prec2
    '((expr ("{" expr "}")
            ("[" expr "]")
            (expr "," expr)
            (expr "=" expr)))
    '((assoc ",")
      (assoc "="))))
  "SMIE grammar for `ocl-mode'.")

(defun ocl--smie-forward-token ()
  "Move forward across one OCL token for SMIE."
  (skip-chars-forward " \t\n")
  (cond
   ((eobp) nil)
   ((looking-at "[][{}=,]")
    (prog1 (match-string-no-properties 0)
      (goto-char (match-end 0))))
   (t
    (condition-case nil
        (progn
          (forward-sexp 1)
          "id")
      (scan-error
       (goto-char (min (point-max) (1+ (point))))
       "id")))))

(defun ocl--smie-backward-token ()
  "Move backward across one OCL token for SMIE."
  (skip-chars-backward " \t\n")
  (cond
   ((bobp) nil)
   ((memq (char-before) '(?\] ?\[ ?\} ?\{ ?= ?,))
    (backward-char)
    (string (char-after)))
   (t
    (condition-case nil
        (progn
          (backward-sexp 1)
          "id")
      (scan-error
       (goto-char (max (point-min) (1- (point))))
       "id")))))

(defun ocl--containing-list-indentation ()
  "Return the indentation of the line that opens the current list."
  (save-excursion
    (condition-case nil
        (progn
          (backward-up-list)
          (current-indentation))
      (scan-error nil))))

(defun ocl--smie-rules (method arg)
  "Return SMIE indentation rule for METHOD and ARG."
  (pcase (cons method arg)
    (`(:elem . basic) ocl-indent-level)
    (`(:after . ,(or "{" "["))
     `(column . ,(+ (current-indentation) ocl-indent-level)))
    (`(:before . ,(or "}" "]"))
     `(column . ,(or (ocl--containing-list-indentation) 0)))))

(defun ocl--smie-indent-inside-list ()
  "Indent an OCL line within braces or brackets."
  (save-excursion
    (back-to-indentation)
    (unless (or (looking-at-p "[]}]")
                (ocl--in-string-or-comment-p))
      (when-let ((indent (ocl--containing-list-indentation)))
        (+ indent ocl-indent-level)))))

(defun ocl-calculate-indentation ()
  "Calculate indentation for the current OCL line using SMIE."
  (save-excursion
    (forward-line 0)
    (skip-chars-forward " \t")
    (or (smie-indent-calculate) 0)))

(defun ocl-indent-line ()
  "Indent current line as OCL configuration."
  (interactive)
  (if (save-excursion
        (back-to-indentation)
        (ocl--in-string-or-comment-p))
      nil
    (smie-indent-line)))

;;; Navigation

(defun ocl-beginning-of-defun (&optional count)
  "Move backward to the beginning of a block, COUNT times."
  (interactive "p")
  (setq count (or count 1))
  (let ((match 0) finish)
    (while (and (not finish)
                (re-search-backward ocl--block-regexp nil t))
      (unless (ocl--in-string-or-comment-p)
        (cl-incf match)
        (when (= match count)
          (setq finish t))))))

(defun ocl-end-of-defun (&optional count)
  "Move forward to the end of a block, COUNT times."
  (interactive "p")
  (setq count (or count 1))
  (let ((paren-level (ocl--paren-level)))
    (when (or (and (looking-at-p "}") (= paren-level 1))
              (= paren-level 0))
      (re-search-forward ocl--block-regexp nil t)))
  (dotimes (_i count)
    (when (looking-at-p ocl--block-regexp)
      (goto-char (line-end-position)))
    (ocl-beginning-of-defun 1)
    (skip-chars-forward "^{")
    (forward-char 1)
    (let ((orig-level (ocl--paren-level)))
      (while (and (>= (ocl--paren-level) orig-level)
                  (< (point) (point-max)))
        (skip-chars-forward "^}")
        (forward-line +1)))))

;;; Keymap

(defvar ocl-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-M-a") 'ocl-beginning-of-defun)
    (define-key map (kbd "C-M-e") 'ocl-end-of-defun)
    map)
  "Keymap for `ocl-mode'.")

;;; Mode definition

;;;###autoload
(define-derived-mode ocl-mode prog-mode "OCL"
  "Major mode for editing Octopus Configuration Language files.

OCL is a subset of HCL used by Octopus Deploy for Configuration
as Code.  Unlike HCL, OCL has no comment syntax, no string
interpolation, and no expressions or functions -- this mode does
not add any of those.

\\{ocl-mode-map}"
  :syntax-table ocl-mode-syntax-table
  (setq font-lock-defaults '((ocl-font-lock-keywords)))

  (make-local-variable 'ocl-indent-level)
  (smie-setup ocl--smie-grammar #'ocl--smie-rules
              :forward-token #'ocl--smie-forward-token
              :backward-token #'ocl--smie-backward-token)
  (setq-local smie-indent-functions
              (cons #'ocl--smie-indent-inside-list
                    (remove #'smie-indent-close smie-indent-functions)))
  (setq-local indent-line-function 'ocl-indent-line)
  ;; SMIE asks Emacs to normalize comment variables during indentation.
  ;; OCL still has no comment syntax; this only prevents an interactive prompt.
  (setq-local comment-start "")
  ;; Default to 4 spaces per indent level, never tabs.
  (setq-local indent-tabs-mode nil)

  (setq-local beginning-of-defun-function #'ocl-beginning-of-defun)
  (setq-local end-of-defun-function #'ocl-end-of-defun)

  (setq-local syntax-propertize-function #'ocl--syntax-propertize-function)

  (setq-local electric-indent-chars (append "{}[]" electric-indent-chars)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.ocl\\'" . ocl-mode))

(provide 'ocl-mode)

;;; ocl-mode.el ends here
