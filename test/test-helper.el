;;; test-helper.el --- Helper for ocl-mode tests -*- lexical-binding: t -*-

;;; Commentary:

;; Shared macros and helpers for ocl-mode's ERT test suite.

;;; Code:

(require 'ert)
(require 'ocl-mode)

(defmacro with-ocl-temp-buffer (code &rest body)
  "Insert CODE and enable `ocl-mode'.  Cursor is at beginning of buffer."
  (declare (indent 1) (debug t))
  `(with-temp-buffer
     (insert ,code)
     (goto-char (point-min))
     (ocl-mode)
     (ocl-mode--font-lock-ensure)
     ,@body))

(defun ocl-mode--font-lock-ensure ()
  "Compatibility wrapper around `font-lock-ensure'."
  (if (fboundp 'font-lock-ensure)
      (font-lock-ensure)
    (with-no-warnings
      (font-lock-fontify-buffer))))

(defun forward-cursor-on (text)
  "Move point to just after TEXT, searching forward from point."
  (goto-char (point-min))
  (search-forward text)
  (backward-char (length text)))

(defun backward-cursor-on (text)
  "Move point to just before TEXT, searching backward from point-max."
  (goto-char (point-max))
  (search-backward text))

(defun face-at-cursor-p (face)
  "Return non-nil if the face at point is FACE."
  (eq (get-text-property (point) 'face) face))

(provide 'test-helper)

;;; test-helper.el ends here
