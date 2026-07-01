EMACS ?= emacs
BATCH_W_ERROR = -batch --eval "(setq byte-compile-error-on-warn t)"
INIT_PACKAGES = "(progn \
  (require 'package) \
  (push '(\"melpa\" . \"https://melpa.org/packages/\") package-archives) \
  (package-initialize) \
  (unless (package-installed-p 'package-lint) \
    (package-refresh-contents) \
    (package-install 'package-lint)))"

SRC = ocl-mode.el
TESTS = test/test-helper.el test/test-command.el test/test-highlighting.el test/test-indentation.el
ELCS = $(SRC:.el=.elc)
TESTS-ELC = $(TESTS:.el=.elc)

.PHONY: all compile-tests test package-lint clean-elc clean

all: compile-tests test package-lint clean-elc

%.elc: %.el
	$(EMACS) -Q -L . -L test $(BATCH_W_ERROR) -f batch-byte-compile $<

compile-tests: $(ELCS) $(TESTS-ELC)

test:
	$(EMACS) -Q -L . -L test -batch \
		-l test/test-helper.el \
		-l test/test-command.el \
		-l test/test-highlighting.el \
		-l test/test-indentation.el \
		-f ert-run-tests-batch-and-exit

package-lint:
	$(EMACS) -Q --eval $(INIT_PACKAGES) $(BATCH_W_ERROR) -f package-lint-batch-and-exit $(SRC)

clean-elc:
	rm -f $(ELCS) $(TESTS-ELC)

clean: clean-elc
