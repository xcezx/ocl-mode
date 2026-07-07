;;; test-highlighting.el --- Tests for ocl-mode font-lock -*- lexical-binding: t -*-

;;; Commentary:

;; ERT tests for `ocl-font-lock-keywords'.

;;; Code:

(require 'test-helper)

(ert-deftest ocl-test-highlight-attribute-name ()
  (with-ocl-temp-buffer "name = \"web\"\n"
    (forward-cursor-on "name")
    (should (face-at-cursor-p 'font-lock-variable-name-face))))

(ert-deftest ocl-test-highlight-dotted-attribute-name ()
  (with-ocl-temp-buffer "Octopus.Action.Script.ScriptBody = \"x\"\n"
    (forward-cursor-on "Octopus.Action.Script.ScriptBody")
    (should (face-at-cursor-p 'font-lock-variable-name-face))
    (forward-cursor-on "Action")
    (should (face-at-cursor-p 'font-lock-variable-name-face))))

(ert-deftest ocl-test-highlight-block-without-label ()
  (with-ocl-temp-buffer "packages {\n    id = 1\n}\n"
    (forward-cursor-on "packages")
    (should (face-at-cursor-p 'font-lock-type-face))))

(ert-deftest ocl-test-highlight-block-with-label ()
  (with-ocl-temp-buffer "step \"Deploy\" {\n    name = \"x\"\n}\n"
    (forward-cursor-on "step")
    (should (face-at-cursor-p 'font-lock-type-face))))

(ert-deftest ocl-test-highlight-block-with-multiple-labels ()
  (with-ocl-temp-buffer "resource \"aws\" \"web\" {\n    id = 1\n}\n"
    (forward-cursor-on "resource")
    (should (face-at-cursor-p 'font-lock-type-face))))

(ert-deftest ocl-test-object-assignment-is-not-a-block ()
  "`foo = {' is an object assignment; the key stays a variable name."
  (with-ocl-temp-buffer "foo = {\n    id = 1\n}\n"
    (forward-cursor-on "foo")
    (should (face-at-cursor-p 'font-lock-variable-name-face))))

(ert-deftest ocl-test-highlight-boolean-true ()
  (with-ocl-temp-buffer "is_required = true\n"
    (forward-cursor-on "true")
    (should (face-at-cursor-p 'font-lock-constant-face))))

(ert-deftest ocl-test-highlight-boolean-false ()
  (with-ocl-temp-buffer "is_disabled = false\n"
    (forward-cursor-on "false")
    (should (face-at-cursor-p 'font-lock-constant-face))))

(ert-deftest ocl-test-highlight-null ()
  (with-ocl-temp-buffer "value = null\n"
    (forward-cursor-on "null")
    (should (face-at-cursor-p 'font-lock-constant-face))))

(ert-deftest ocl-test-highlight-integer ()
  (with-ocl-temp-buffer "count = 42\n"
    (forward-cursor-on "42")
    (should (face-at-cursor-p 'font-lock-constant-face))))

(ert-deftest ocl-test-highlight-negative-integer ()
  (with-ocl-temp-buffer "count = -42\n"
    (forward-cursor-on "-42")
    (should (face-at-cursor-p 'font-lock-constant-face))))

(ert-deftest ocl-test-highlight-decimal ()
  (with-ocl-temp-buffer "ratio = 1.5\n"
    (forward-cursor-on "1.5")
    (should (face-at-cursor-p 'font-lock-constant-face))))

(ert-deftest ocl-test-highlight-string ()
  (with-ocl-temp-buffer "name = \"web\"\n"
    (forward-cursor-on "web")
    (should (face-at-cursor-p 'font-lock-string-face))))

(ert-deftest ocl-test-highlight-array-strings ()
  (with-ocl-temp-buffer "channels = [\"default\", \"pre-release\"]\n"
    (forward-cursor-on "default")
    (should (face-at-cursor-p 'font-lock-string-face))
    (forward-cursor-on "pre-release")
    (should (face-at-cursor-p 'font-lock-string-face))))

(ert-deftest ocl-test-highlight-heredoc-body ()
  (with-ocl-temp-buffer "body = <<-EOT\n    echo hello\nEOT\n"
    (forward-cursor-on "echo hello")
    (should (face-at-cursor-p 'font-lock-string-face))))

(ert-deftest ocl-test-highlight-plain-heredoc-body ()
  "A plain `<<EOT' heredoc body is a string, closed at a column-0 tag."
  (with-ocl-temp-buffer "body = <<EOT\necho hello\nEOT\nname = \"x\"\n"
    (forward-cursor-on "echo hello")
    (should (face-at-cursor-p 'font-lock-string-face))
    ;; The heredoc closed, so the following attribute highlights normally.
    (forward-cursor-on "name")
    (should (face-at-cursor-p 'font-lock-variable-name-face))))

(ert-deftest ocl-test-plain-heredoc-not-closed-by-indented-tag ()
  "For plain `<<EOT', an indented line equal to the tag must not close it."
  (with-ocl-temp-buffer "body = <<EOT\n    EOT\nreally hello\nEOT\n"
    (forward-cursor-on "really hello")
    (should (face-at-cursor-p 'font-lock-string-face))))

(ert-deftest ocl-test-no-comment-highlighting ()
  "OCL has no comment syntax; `#' must not be treated specially."
  (with-ocl-temp-buffer "# not a comment\nname = \"x\"\n"
    (forward-cursor-on "not a comment")
    (should-not (face-at-cursor-p 'font-lock-comment-face))))

(ert-deftest ocl-test-no-slash-comment-highlighting ()
  "OCL has no comment syntax; `//' must not be treated specially."
  (with-ocl-temp-buffer "// not a comment\nname = \"x\"\n"
    (forward-cursor-on "not a comment")
    (should-not (face-at-cursor-p 'font-lock-comment-face))))

(provide 'test-highlighting)

;;; test-highlighting.el ends here
