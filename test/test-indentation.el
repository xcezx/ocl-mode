;;; test-indentation.el --- Tests for ocl-mode indentation -*- lexical-binding: t -*-

;;; Commentary:

;; ERT tests for `ocl-indent-line' / `ocl-calculate-indentation'.

;;; Code:

(require 'test-helper)

(defun ocl-test--indentation-of (line-number)
  "Return the indentation of LINE-NUMBER (1-indexed) after `indent-region'."
  (indent-region (point-min) (point-max))
  (save-excursion
    (goto-char (point-min))
    (forward-line (1- line-number))
    (current-indentation)))

(ert-deftest ocl-test-no-indentation-at-top-level ()
  (with-ocl-temp-buffer "name = \"x\"\n"
    (should (= (ocl-test--indentation-of 1) 0))))

(ert-deftest ocl-test-indentation-into-block ()
  (with-ocl-temp-buffer "step \"A\" {\nname = \"x\"\n}\n"
    (should (= (ocl-test--indentation-of 2) ocl-indent-level))
    (should (= (ocl-test--indentation-of 3) 0))))

(ert-deftest ocl-test-indentation-nested-block ()
  (with-ocl-temp-buffer "step \"A\" {\npackages {\nid = 1\n}\n}\n"
    (should (= (ocl-test--indentation-of 2) ocl-indent-level))
    (should (= (ocl-test--indentation-of 3) (* 2 ocl-indent-level)))
    (should (= (ocl-test--indentation-of 4) ocl-indent-level))
    (should (= (ocl-test--indentation-of 5) 0))))

(ert-deftest ocl-test-indentation-uses-spaces-not-tabs ()
  (with-ocl-temp-buffer "step \"A\" {\nname = \"x\"\n}\n"
    (indent-region (point-min) (point-max))
    (save-excursion
      (goto-char (point-min))
      (forward-line 1)
      (should (looking-at-p " \\{4\\}[^ \t]")))))

(ert-deftest ocl-test-array-indentation ()
  (with-ocl-temp-buffer "values = [\n1,\n2,\n]\n"
    (should (= (ocl-test--indentation-of 2) ocl-indent-level))
    (should (= (ocl-test--indentation-of 3) ocl-indent-level))
    (should (= (ocl-test--indentation-of 4) 0))))

(ert-deftest ocl-test-map-indentation ()
  (with-ocl-temp-buffer "properties = {\nkey = \"value\"\n}\n"
    (should (= (ocl-test--indentation-of 2) ocl-indent-level))
    (should (= (ocl-test--indentation-of 3) 0))))

(ert-deftest ocl-test-no-indentation-with-empty-line ()
  (with-ocl-temp-buffer "step \"A\" {\nname = \"x\"\n\nvalue = \"y\"\n}\n"
    (should (= (ocl-test--indentation-of 4) ocl-indent-level))))

(ert-deftest ocl-test-no-reindentation-inside-heredoc ()
  "Heredoc bodies must be left untouched by indentation."
  (with-ocl-temp-buffer "body = <<-EOT\n    keep this indentation\nEOT\n"
    (indent-region (point-min) (point-max))
    (save-excursion
      (goto-char (point-min))
      (forward-line 1)
      (should (looking-at-p "    keep this indentation")))))

(provide 'test-indentation)

;;; test-indentation.el ends here
