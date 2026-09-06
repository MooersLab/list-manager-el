# Makefile for list-manager.el
#
# This Makefile provides targets for:
# - Building Info documentation from Texinfo sources
# - Installing Info files to the system or user directory
# - Running tests
# - Byte-compiling Emacs Lisp files
# - Cleaning generated files
#
# Usage:
#   make info          - Build Info files from .texi sources
#   make install-info  - Install Info files (may require sudo)
#   make install-info-user - Install to user's info directory
#   make test          - Run ERT tests
#   make compile       - Byte-compile .el files
#   make clean         - Remove generated files
#   make all           - Build everything

EMACS ?= emacs
MAKEINFO ?= makeinfo
INSTALL_INFO ?= install-info
TEXI2PDF ?= texi2pdf

# Package information
PACKAGE = list-manager
VERSION = 1.0.0

# Source files
EL_FILES = list-manager.el
TEST_FILES = list-manager-test.el
TEXI_FILES = list-manager.texi list-manager-test.texi

# Generated files
INFO_FILES = list-manager.info list-manager-test.info
ELC_FILES = $(EL_FILES:.el=.elc) $(TEST_FILES:.el=.elc)
PDF_FILES = $(TEXI_FILES:.texi=.pdf)

# Installation directories
# System-wide (requires root)
INFO_DIR ?= /usr/local/share/info
# User-specific (no root required)
USER_INFO_DIR ?= $(HOME)/.local/share/info

# Emacs batch flags
EMACS_BATCH = $(EMACS) --batch -Q

.PHONY: all info pdf compile test clean install-info install-info-user \
        uninstall-info uninstall-info-user help check-deps

# Default target
all: info compile

# Help target
help:
	@echo "List Manager Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  all              - Build info files and byte-compile"
	@echo "  info             - Build Info files from Texinfo sources"
	@echo "  pdf              - Build PDF documentation (requires texi2pdf)"
	@echo "  compile          - Byte-compile Emacs Lisp files"
	@echo "  test             - Run ERT test suite"
	@echo "  clean            - Remove generated files"
	@echo "  install-info     - Install Info files system-wide (may need sudo)"
	@echo "  install-info-user - Install Info files to user directory"
	@echo "  uninstall-info   - Remove Info files from system directory"
	@echo "  uninstall-info-user - Remove Info files from user directory"
	@echo "  check-deps       - Check for required dependencies"
	@echo ""
	@echo "Variables:"
	@echo "  EMACS=$(EMACS)"
	@echo "  INFO_DIR=$(INFO_DIR)"
	@echo "  USER_INFO_DIR=$(USER_INFO_DIR)"

# Check dependencies
check-deps:
	@echo "Checking dependencies..."
	@which $(EMACS) > /dev/null || (echo "ERROR: emacs not found"; exit 1)
	@which $(MAKEINFO) > /dev/null || (echo "ERROR: makeinfo not found (install texinfo)"; exit 1)
	@echo "All dependencies found."

# Build Info files
info: $(INFO_FILES)

list-manager.info: list-manager.texi
	$(MAKEINFO) --no-split $< -o $@

list-manager-test.info: list-manager-test.texi
	$(MAKEINFO) --no-split $< -o $@

# Build PDF documentation (optional)
pdf: $(PDF_FILES)

%.pdf: %.texi
	$(TEXI2PDF) $<

# Byte-compile Emacs Lisp files
compile: $(ELC_FILES)

list-manager.elc: list-manager.el
	$(EMACS_BATCH) -L . -f batch-byte-compile $<

# The test file references the package, so load it before compiling to
# avoid spurious "not known to be defined" warnings.
list-manager-test.elc: list-manager-test.el list-manager.elc
	$(EMACS_BATCH) -L . -l list-manager.el -f batch-byte-compile $<

# Run tests
test: $(EL_FILES) $(TEST_FILES)
	$(EMACS_BATCH) \
		-L . \
		-l list-manager.el \
		-l list-manager-test.el \
		-f ert-run-tests-batch-and-exit

# Run tests with verbose output
test-verbose: $(EL_FILES) $(TEST_FILES)
	$(EMACS_BATCH) \
		-L . \
		-l list-manager.el \
		-l list-manager-test.el \
		--eval "(ert-run-tests-batch-and-exit '(tag :verbose))"

# Install Info files system-wide
install-info: $(INFO_FILES)
	@echo "Installing Info files to $(INFO_DIR)..."
	@mkdir -p $(INFO_DIR)
	@for file in $(INFO_FILES); do \
		install -m 644 $$file $(INFO_DIR)/$$file; \
		$(INSTALL_INFO) --info-dir=$(INFO_DIR) $(INFO_DIR)/$$file 2>/dev/null || true; \
	done
	@echo "Done. You may need to run 'sudo make install-info' if permission denied."

# Install Info files to user directory
install-info-user: $(INFO_FILES)
	@echo "Installing Info files to $(USER_INFO_DIR)..."
	@mkdir -p $(USER_INFO_DIR)
	@for file in $(INFO_FILES); do \
		install -m 644 $$file $(USER_INFO_DIR)/$$file; \
	done
	@# Create or update user's dir file
	@if [ ! -f $(USER_INFO_DIR)/dir ]; then \
		echo "Creating $(USER_INFO_DIR)/dir..."; \
		echo "This is the file .../info/dir, which contains the" > $(USER_INFO_DIR)/dir; \
		echo "topmost node of the Info hierarchy, called (dir)Top." >> $(USER_INFO_DIR)/dir; \
		echo "The first time you invoke Info you start off looking at this node." >> $(USER_INFO_DIR)/dir; \
		echo "" >> $(USER_INFO_DIR)/dir; \
		echo "File: dir,	Node: Top	This is the top of the INFO tree" >> $(USER_INFO_DIR)/dir; \
		echo "" >> $(USER_INFO_DIR)/dir; \
		echo "  This (the Directory node) gives a menu of major topics." >> $(USER_INFO_DIR)/dir; \
		echo "" >> $(USER_INFO_DIR)/dir; \
		echo "* Menu:" >> $(USER_INFO_DIR)/dir; \
		echo "" >> $(USER_INFO_DIR)/dir; \
	fi
	@for file in $(INFO_FILES); do \
		$(INSTALL_INFO) --info-dir=$(USER_INFO_DIR) $(USER_INFO_DIR)/$$file 2>/dev/null || true; \
	done
	@echo "Done."
	@echo ""
	@echo "Add this to your init.el to use the user info directory:"
	@echo '  (add-to-list '\''Info-directory-list "$(USER_INFO_DIR)")'

# Uninstall from system directory
uninstall-info:
	@echo "Removing Info files from $(INFO_DIR)..."
	@for file in $(INFO_FILES); do \
		$(INSTALL_INFO) --delete --info-dir=$(INFO_DIR) $(INFO_DIR)/$$file 2>/dev/null || true; \
		rm -f $(INFO_DIR)/$$file; \
	done
	@echo "Done."

# Uninstall from user directory
uninstall-info-user:
	@echo "Removing Info files from $(USER_INFO_DIR)..."
	@for file in $(INFO_FILES); do \
		$(INSTALL_INFO) --delete --info-dir=$(USER_INFO_DIR) $(USER_INFO_DIR)/$$file 2>/dev/null || true; \
		rm -f $(USER_INFO_DIR)/$$file; \
	done
	@echo "Done."

# Generate dir file entry (for manual inclusion)
dir-entry:
	@echo "Add these entries to your Info dir file:"
	@echo ""
	@echo "Emacs"
	@echo "* List Manager: (list-manager).  Manage lists in org-mode and LaTeX."
	@echo "* List Manager Tests: (list-manager-test).  Test suite for List Manager."

# Clean generated files
clean:
	rm -f $(INFO_FILES)
	rm -f $(ELC_FILES)
	rm -f $(PDF_FILES)
	rm -f *.aux *.cp *.cps *.fn *.fns *.ky *.log *.pg *.toc *.tp *.vr *.vrs

# Distribution target
DIST_FILES = $(EL_FILES) $(TEST_FILES) $(TEXI_FILES) Makefile README.md \
             LICENSE CITATION.cff CONTRIBUTING.md CODE_OF_CONDUCT.md

dist: clean
	mkdir -p $(PACKAGE)-$(VERSION)
	cp $(DIST_FILES) $(PACKAGE)-$(VERSION)/
	tar czf $(PACKAGE)-$(VERSION).tar.gz $(PACKAGE)-$(VERSION)
	rm -rf $(PACKAGE)-$(VERSION)
	@echo "Created $(PACKAGE)-$(VERSION).tar.gz"

# MELPA package-lint check
lint:
	$(EMACS_BATCH) \
		-L . \
		--eval "(require 'package)" \
		--eval "(push '(\"melpa\" . \"https://melpa.org/packages/\") package-archives)" \
		--eval "(package-initialize)" \
		--eval "(package-refresh-contents)" \
		--eval "(package-install 'package-lint)" \
		-l package-lint \
		-f package-lint-batch-and-exit $(EL_FILES)
