;;; test-command.el --- Tests for ocl-mode navigation commands -*- lexical-binding: t -*-

;;; Commentary:

;; ERT tests for `ocl-beginning-of-defun' / `ocl-end-of-defun'.

;;; Code:

(require 'test-helper)

(ert-deftest ocl-test-beginning-of-defun ()
  (with-ocl-temp-buffer "step \"A\" {\n    name = \"x\"\n}\nstep \"B\" {\n    name = \"y\"\n}\n"
    (goto-char (point-max))
    (ocl-beginning-of-defun 1)
    (should (looking-at-p "step \"B\" {"))
    (ocl-beginning-of-defun 1)
    (should (looking-at-p "step \"A\" {"))))

(ert-deftest ocl-test-beginning-of-defun-with-count ()
  (with-ocl-temp-buffer "step \"A\" {\n    name = \"x\"\n}\nstep \"B\" {\n    name = \"y\"\n}\n"
    (goto-char (point-max))
    (ocl-beginning-of-defun 2)
    (should (looking-at-p "step \"A\" {"))))

(ert-deftest ocl-test-end-of-defun ()
  (with-ocl-temp-buffer "step \"A\" {\n    name = \"x\"\n}\nstep \"B\" {\n    name = \"y\"\n}\n"
    (goto-char (point-min))
    (ocl-end-of-defun 1)
    (should (= (point) (save-excursion
                          (goto-char (point-min))
                          (forward-line 3)
                          (point))))))

(ert-deftest ocl-test-end-of-defun-nested ()
  (with-ocl-temp-buffer "step \"A\" {\n    packages {\n        id = 1\n    }\n}\n"
    (goto-char (point-min))
    (ocl-end-of-defun 1)
    (should (= (point) (point-max)))))

(provide 'test-command)

;;; test-command.el ends here
