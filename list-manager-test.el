;;; list-manager-test.el --- Tests for list-manager.el -*- lexical-binding: t; -*-

;; Author: Blaine Mooers <blaine-mooers@ou.edu>
;; Keywords: test, ert

;;; Commentary:

;; This file contains ERT (Emacs Lisp Regression Testing) tests for the
;; list-manager.el package.  The tests cover both unit tests for individual
;; functions and integration tests for workflows involving multiple functions.
;;
;; To run all tests:
;;   M-x ert RET t RET
;;
;; To run tests matching a pattern:
;;   M-x ert RET "list-manager" RET
;;
;; To run a specific test:
;;   M-x ert RET list-manager-test-numbered-list-to-latex-items RET

;;; Code:

(require 'ert)
(require 'cl-lib)

;; Load the package under test.  When run through the Makefile the package
;; is already loaded with -l, so this is only a fallback that lets the suite
;; run from a clean checkout or directly from an editor.  It loads the
;; list-manager.el sitting next to this file, wherever the checkout lives.
(unless (featurep 'list-manager)
  (let* ((here (or load-file-name buffer-file-name default-directory))
         (pkg (expand-file-name "list-manager.el" (file-name-directory here))))
    (if (file-exists-p pkg)
        (load pkg nil t)
      (require 'list-manager))))

;;; ============================================================================
;;; Test Helper Macros
;;; ============================================================================

(defmacro list-manager-test-with-temp-buffer (initial-content &rest body)
  "Execute BODY in a temp buffer with INITIAL-CONTENT.
Returns the buffer contents after executing BODY."
  (declare (indent 1))
  `(with-temp-buffer
     (insert ,initial-content)
     ,@body
     (buffer-string)))

(defmacro list-manager-test-with-region (initial-content &rest body)
  "Execute BODY in a temp buffer holding INITIAL-CONTENT.
The entire buffer is selected as the active region first.
Returns the buffer contents after executing BODY."
  (declare (indent 1))
  `(with-temp-buffer
     (insert ,initial-content)
     (goto-char (point-min))
     (push-mark (point-max) t t)
     ,@body
     (buffer-string)))

;;; ============================================================================
;;; Unit Tests: Numbered List to LaTeX Items
;;; ============================================================================

(ert-deftest list-manager-test-numbered-list-to-latex-items-basic ()
  "Test basic conversion of numbered list to LaTeX items."
  (let ((result (list-manager-test-with-region "1. First item
2. Second item
3. Third item"
                  (list-manager-numbered-list-to-latex-items))))
    (should (string-match-p "\\\\item First item" result))
    (should (string-match-p "\\\\item Second item" result))
    (should (string-match-p "\\\\item Third item" result))))

(ert-deftest list-manager-test-numbered-list-to-latex-items-with-leading-spaces ()
  "Test conversion with leading whitespace in numbered list."
  (let ((result (list-manager-test-with-region "  1. Indented item
  2. Another indented"
                  (list-manager-numbered-list-to-latex-items))))
    (should (string-match-p "\\\\item Indented item" result))
    (should (string-match-p "\\\\item Another indented" result))))

(ert-deftest list-manager-test-numbered-list-to-latex-items-double-digits ()
  "Test conversion with double-digit numbers."
  (let ((result (list-manager-test-with-region "10. Item ten
11. Item eleven"
                  (list-manager-numbered-list-to-latex-items))))
    (should (string-match-p "\\\\item Item ten" result))
    (should (string-match-p "\\\\item Item eleven" result))))

;;; ============================================================================
;;; Unit Tests: Dash List to LaTeX Items
;;; ============================================================================

(ert-deftest list-manager-test-dash-list-to-latex-items-basic ()
  "Test basic conversion of dash list to LaTeX items."
  (let ((result (list-manager-test-with-region "- First item
- Second item
- Third item"
                  (list-manager-dash-list-to-latex-items))))
    (should (string-match-p "\\\\item First item" result))
    (should (string-match-p "\\\\item Second item" result))
    (should (string-match-p "\\\\item Third item" result))))

(ert-deftest list-manager-test-dash-list-to-latex-items-asterisk ()
  "Test conversion of asterisk list to LaTeX items."
  (let ((result (list-manager-test-with-region "* First item
* Second item"
                  (list-manager-dash-list-to-latex-items))))
    (should (string-match-p "\\\\item First item" result))
    (should (string-match-p "\\\\item Second item" result))))

(ert-deftest list-manager-test-dash-list-to-latex-items-plus ()
  "Test conversion of plus list to LaTeX items."
  (let ((result (list-manager-test-with-region "+ First item
+ Second item"
                  (list-manager-dash-list-to-latex-items))))
    (should (string-match-p "\\\\item First item" result))
    (should (string-match-p "\\\\item Second item" result))))

;;; ============================================================================
;;; Unit Tests: Org Dash List to LaTeX Items
;;; ============================================================================

(ert-deftest list-manager-test-org-dash-list-to-latex-items-basic ()
  "Test basic org dash list to LaTeX items conversion."
  (let ((result (list-manager-test-with-region "- First item
- Second item"
                  (list-manager-org-dash-list-to-latex-items))))
    (should (string-match-p "\\\\item First item" result))
    (should (string-match-p "\\\\item Second item" result))))

(ert-deftest list-manager-test-org-dash-list-to-latex-items-indentation ()
  "Test that org dash list conversion adds proper indentation."
  (let ((result (list-manager-test-with-region "- Item one"
                  (list-manager-org-dash-list-to-latex-items))))
    (should (string-match-p "^    \\\\item" result))))

;;; ============================================================================
;;; Unit Tests: Org Dash List to LaTeX Itemize Environment
;;; ============================================================================

(ert-deftest list-manager-test-org-dash-list-to-latex-itemize ()
  "Test conversion to complete LaTeX itemize environment."
  (let ((result (list-manager-test-with-region "- First
- Second"
                  (list-manager-org-dash-list-to-latex-itemize))))
    (should (string-match-p "\\\\begin{itemize}" result))
    (should (string-match-p "\\\\end{itemize}" result))
    (should (string-match-p "#\\+BEGIN_EXPORT latex" result))
    (should (string-match-p "#\\+END_EXPORT" result))
    (should (string-match-p "\\\\item First" result))
    (should (string-match-p "\\\\item Second" result))))

(ert-deftest list-manager-test-org-dash-list-to-latex-itemize-empty ()
  "Test itemize conversion with empty region."
  (let ((result (list-manager-test-with-region "no list here"
                  (list-manager-org-dash-list-to-latex-itemize))))
    ;; Should not modify buffer if no items found
    (should (string= result "no list here"))))

;;; ============================================================================
;;; Unit Tests: Custom LaTeX (Beamer Style)
;;; ============================================================================

(ert-deftest list-manager-test-org-dash-list-to-custom-latex ()
  "Test conversion to custom LaTeX format for Beamer."
  (let ((result (list-manager-test-with-region "- Item one
- Item two"
                  (list-manager-org-dash-list-to-custom-latex))))
    (should (string-match-p "\\\\Large{" result))
    (should (string-match-p "\\\\begin{itemize}\\[font=\\$\\\\bullet\\$" result))
    (should (string-match-p "\\\\item Item one" result))
    (should (string-match-p "\\\\item Item two" result))
    (should (string-match-p "\\\\end{itemize}" result))
    (should (string-match-p "#\\+BEGIN_EXPORT latex" result))))

;;; ============================================================================
;;; Unit Tests: Extract Unchecked Items
;;; ============================================================================

(ert-deftest list-manager-test-extract-unchecked-org-style ()
  "Test extraction of unchecked org-mode style items."
  (with-temp-buffer
    (insert "- [ ] Unchecked item one
- [X] Checked item
- [ ] Unchecked item two")
    (list-manager-extract-unchecked-items (point-min) (point-max))
    (let ((output-buffer (get-buffer "*Unchecked Items*")))
      (should output-buffer)
      (with-current-buffer output-buffer
        (let ((content (buffer-string)))
          (should (string-match-p "Unchecked item one" content))
          (should (string-match-p "Unchecked item two" content))
          ;; The word "Checked" appears in "Unchecked" in the title, so check for the full phrase
          (should-not (string-match-p "- \\[ \\] Checked item$" content))))
      (kill-buffer output-buffer))))

(ert-deftest list-manager-test-extract-unchecked-latex-style-1 ()
  "Test extraction of unchecked LaTeX style 1 items."
  (with-temp-buffer
    (insert "\\item [ ] Unchecked latex item
\\item[\\checked] Checked latex item")
    (list-manager-extract-unchecked-items (point-min) (point-max))
    (let ((output-buffer (get-buffer "*Unchecked Items*")))
      (should output-buffer)
      (with-current-buffer output-buffer
        (should (string-match-p "Unchecked latex item" (buffer-string))))
      (kill-buffer output-buffer))))

(ert-deftest list-manager-test-extract-unchecked-latex-style-2 ()
  "Test extraction of unchecked LaTeX style 2 items (without checkbox)."
  (with-temp-buffer
    (insert "\\item Regular unchecked item
\\item[\\checked] Checked item with marker")
    (list-manager-extract-unchecked-items (point-min) (point-max))
    (let ((output-buffer (get-buffer "*Unchecked Items*")))
      (should output-buffer)
      (with-current-buffer output-buffer
        (should (string-match-p "Regular unchecked item" (buffer-string)))
        (should-not (string-match-p "Checked item with marker" (buffer-string))))
      (kill-buffer output-buffer))))

(ert-deftest list-manager-test-extract-unchecked-no-items ()
  "Test extraction when no unchecked items exist."
  (with-temp-buffer
    (insert "- [X] All checked
- [X] This too")
    (list-manager-extract-unchecked-items (point-min) (point-max))
    ;; Should just display message, no buffer created or empty
    (let ((output-buffer (get-buffer "*Unchecked Items*")))
      (when output-buffer
        (kill-buffer output-buffer)))))

;;; ============================================================================
;;; Unit Tests: Extract Unchecked Items to Kill Ring
;;; ============================================================================

(ert-deftest list-manager-test-extract-unchecked-to-kill-ring ()
  "Test extraction of unchecked items to kill ring."
  (with-temp-buffer
    (insert "- [ ] Task one
- [X] Done task
- [ ] Task two")
    (list-manager-extract-unchecked-items-to-kill-ring (point-min) (point-max))
    (let ((killed (car kill-ring)))
      (should (string-match-p "Task one" killed))
      (should (string-match-p "Task two" killed))
      (should-not (string-match-p "Done task" killed)))))

;;; ============================================================================
;;; Unit Tests: Cut Unchecked Items
;;; ============================================================================

(ert-deftest list-manager-test-cut-unchecked-items ()
  "Test cutting unchecked items removes them from buffer."
  (let ((test-buffer (generate-new-buffer "*test-cut*")))
    (with-current-buffer test-buffer
      (insert "- [ ] Unchecked one
- [X] Checked
- [ ] Unchecked two")
      (list-manager-cut-unchecked-items (point-min) (point-max)))
    ;; After cut, check the original test buffer content
    (with-current-buffer test-buffer
      (should (string-match-p "\\[X\\] Checked" (buffer-string))))
    ;; Unchecked items should be in output buffer
    (let ((output-buffer (get-buffer "*Unchecked Items*")))
      (should output-buffer)
      (with-current-buffer output-buffer
        (should (string-match-p "Unchecked one" (buffer-string)))
        (should (string-match-p "Unchecked two" (buffer-string))))
      (kill-buffer output-buffer))
    (kill-buffer test-buffer)))

;;; ============================================================================
;;; Unit Tests: Cut Unchecked Items to Kill Ring
;;; ============================================================================

(ert-deftest list-manager-test-cut-unchecked-to-kill-ring ()
  "Test cutting unchecked items to kill ring."
  (with-temp-buffer
    (insert "- [ ] To cut
- [X] Keep this")
    (list-manager-cut-unchecked-items-to-kill-ring (point-min) (point-max))
    ;; Original buffer should not have unchecked item
    (should-not (string-match-p "To cut" (buffer-string)))
    ;; Kill ring should have the item in LaTeX format
    (should (string-match-p "\\\\item To cut" (car kill-ring)))))

(ert-deftest list-manager-test-cut-unchecked-to-kill-ring-latex-format ()
  "Test that cut items are in LaTeX format, not org format."
  (with-temp-buffer
    (insert "- [ ] First task
- [ ] Second task
- [X] Done task")
    (list-manager-cut-unchecked-items-to-kill-ring (point-min) (point-max))
    (let ((killed (car kill-ring)))
      ;; Should be LaTeX format
      (should (string-match-p "\\\\item First task" killed))
      (should (string-match-p "\\\\item Second task" killed))
      ;; Should NOT be org format
      (should-not (string-match-p "- \\[ \\]" killed)))))

;;; ============================================================================
;;; Unit Tests: Lines to LaTeX Items
;;; ============================================================================

(ert-deftest list-manager-test-lines-to-latex-items-basic ()
  "Test converting plain lines to LaTeX items."
  (let ((result (list-manager-test-with-region "First line
Second line
Third line"
                  (list-manager-lines-to-latex-items (point-min) (point-max)))))
    (should (string-match-p "\\\\item First line" result))
    (should (string-match-p "\\\\item Second line" result))
    (should (string-match-p "\\\\item Third line" result))))

(ert-deftest list-manager-test-lines-to-latex-items-with-env ()
  "Test converting lines to LaTeX items with itemize environment."
  (let ((result (list-manager-test-with-region "First line
Second line"
                  (list-manager-lines-to-latex-items (point-min) (point-max) t))))
    (should (string-match-p "\\\\begin{itemize}" result))
    (should (string-match-p "\\\\end{itemize}" result))
    (should (string-match-p "\\\\item First line" result))))

(ert-deftest list-manager-test-lines-to-latex-items-skip-empty ()
  "Test that empty lines are skipped."
  (let ((result (list-manager-test-with-region "Line one

Line two"
                  (list-manager-lines-to-latex-items (point-min) (point-max)))))
    (should (string-match-p "\\\\item Line one" result))
    (should (string-match-p "\\\\item Line two" result))
    ;; Should have exactly 2 items
    (should (= 2 (cl-count-if (lambda (c) (string-match-p "\\\\item" c))
                              (split-string result "\n"))))))

;;; ============================================================================
;;; Unit Tests: Lines to LaTeX Items Unchecked
;;; ============================================================================

(ert-deftest list-manager-test-lines-to-latex-items-unchecked-basic ()
  "Test converting lines to unchecked LaTeX items."
  (let ((result (list-manager-test-with-region "Task one
Task two"
                  (list-manager-lines-to-latex-items-unchecked (point-min) (point-max)))))
    (should (string-match-p "\\\\item Task one" result))
    (should (string-match-p "\\\\item Task two" result))))

(ert-deftest list-manager-test-lines-to-latex-items-unchecked-with-env ()
  "Test converting lines to unchecked items with environment."
  (let ((result (list-manager-test-with-region "Task"
                  (list-manager-lines-to-latex-items-unchecked (point-min) (point-max) t))))
    (should (string-match-p "\\\\begin{itemize}\\[label=\\\\unchecked\\]" result))
    (should (string-match-p "\\\\end{itemize}" result))))

;;; ============================================================================
;;; Unit Tests: Convert Org Checklist to Dash List
;;; ============================================================================

(ert-deftest list-manager-test-convert-checklist-to-dash-unchecked ()
  "Test converting unchecked checklist items to dash list."
  (let ((result (list-manager-test-with-region "- [ ] Item one
- [ ] Item two"
                  (list-manager-convert-org-checklist-to-dash-list (point-min) (point-max)))))
    (should (string-match-p "^- Item one" result))
    (should (string-match-p "^- Item two" result))
    (should-not (string-match-p "\\[ \\]" result))))

(ert-deftest list-manager-test-convert-checklist-to-dash-checked ()
  "Test converting checked checklist items to dash list."
  (let ((result (list-manager-test-with-region "- [X] Done item
- [ ] Undone item"
                  (list-manager-convert-org-checklist-to-dash-list (point-min) (point-max)))))
    (should (string-match-p "^- Done item" result))
    (should (string-match-p "^- Undone item" result))
    (should-not (string-match-p "\\[X\\]" result))
    (should-not (string-match-p "\\[ \\]" result))))

(ert-deftest list-manager-test-convert-checklist-to-dash-preserve-indent ()
  "Test that indentation is preserved during conversion."
  (let ((result (list-manager-test-with-region "  - [ ] Indented item"
                  (list-manager-convert-org-checklist-to-dash-list (point-min) (point-max)))))
    (should (string-match-p "^  - Indented item" result))))

;;; ============================================================================
;;; Unit Tests: Convert Org Checklist to LaTeX Items
;;; ============================================================================

(ert-deftest list-manager-test-convert-checklist-to-latex-basic ()
  "Test converting org checklist to LaTeX items."
  (let ((result (list-manager-test-with-region "- [ ] First item
- [X] Second item
- [ ] Third item"
                  (list-manager-convert-org-checklist-to-latex-items (point-min) (point-max)))))
    (should (string-match-p "\\\\item First item" result))
    (should (string-match-p "\\\\item Second item" result))
    (should (string-match-p "\\\\item Third item" result))
    ;; Should not have checkbox notation
    (should-not (string-match-p "\\[" result))))

(ert-deftest list-manager-test-convert-checklist-to-latex-lowercase-x ()
  "Test converting checklist with lowercase x."
  (let ((result (list-manager-test-with-region "- [x] Done item"
                  (list-manager-convert-org-checklist-to-latex-items (point-min) (point-max)))))
    (should (string-match-p "\\\\item Done item" result))))

(ert-deftest list-manager-test-convert-checklist-to-latex-preserve-indent ()
  "Test that indentation is preserved."
  (let ((result (list-manager-test-with-region "  - [ ] Indented"
                  (list-manager-convert-org-checklist-to-latex-items (point-min) (point-max)))))
    (should (string-match-p "^  \\\\item Indented" result))))

;;; ============================================================================
;;; Unit Tests: Convert LaTeX Items to Dash List (NEW)
;;; ============================================================================

(ert-deftest list-manager-test-latex-to-dash-basic ()
  "Test converting LaTeX items to dash list."
  (let ((result (list-manager-test-with-region "\\item First item
\\item Second item
\\item Third item"
                  (list-manager-convert-latex-items-to-dash-list (point-min) (point-max)))))
    (should (string-match-p "^- First item" result))
    (should (string-match-p "^- Second item" result))
    (should (string-match-p "^- Third item" result))
    ;; Should not have \item
    (should-not (string-match-p "\\\\item" result))))

(ert-deftest list-manager-test-latex-to-dash-with-indentation ()
  "Test converting indented LaTeX items."
  (let ((result (list-manager-test-with-region "  \\item Indented item"
                  (list-manager-convert-latex-items-to-dash-list (point-min) (point-max)))))
    (should (string-match-p "^  - Indented item" result))))

(ert-deftest list-manager-test-latex-to-dash-mixed-content ()
  "Test that non-item lines are preserved."
  (let ((result (list-manager-test-with-region "Some text
\\item An item
More text"
                  (list-manager-convert-latex-items-to-dash-list (point-min) (point-max)))))
    (should (string-match-p "Some text" result))
    (should (string-match-p "^- An item" result))
    (should (string-match-p "More text" result))))

;;; ============================================================================
;;; Unit Tests: Convert LaTeX Items to Org Checklist (NEW)
;;; ============================================================================

(ert-deftest list-manager-test-latex-to-checklist-basic ()
  "Test converting LaTeX items to org checklist."
  (let ((result (list-manager-test-with-region "\\item First item
\\item Second item
\\item Third item"
                  (list-manager-convert-latex-items-to-org-checklist (point-min) (point-max)))))
    (should (string-match-p "^- \\[ \\] First item" result))
    (should (string-match-p "^- \\[ \\] Second item" result))
    (should (string-match-p "^- \\[ \\] Third item" result))))

(ert-deftest list-manager-test-latex-to-checklist-with-indentation ()
  "Test converting indented LaTeX items to checklist."
  (let ((result (list-manager-test-with-region "  \\item Indented"
                  (list-manager-convert-latex-items-to-org-checklist (point-min) (point-max)))))
    (should (string-match-p "^  - \\[ \\] Indented" result))))

(ert-deftest list-manager-test-latex-to-checklist-all-unchecked ()
  "Test that all items become unchecked."
  (let ((result (list-manager-test-with-region "\\item Task one
\\item Task two"
                  (list-manager-convert-latex-items-to-org-checklist (point-min) (point-max)))))
    ;; All should be unchecked
    (should (= 2 (cl-count-if (lambda (line) (string-match-p "- \\[ \\]" line))
                              (split-string result "\n"))))))

;;; ============================================================================
;;; Unit Tests: Convert LaTeX Items to TODO Headlines (NEW)
;;; ============================================================================

(ert-deftest list-manager-test-latex-to-todo-basic ()
  "Test converting LaTeX items to TODO headlines."
  (let ((result (list-manager-test-with-region "\\item First task
\\item Second task
\\item Third task"
                  (list-manager-convert-latex-items-to-todo-headlines (point-min) (point-max)))))
    (should (string-match-p "^\\* TODO First task" result))
    (should (string-match-p "^\\* TODO Second task" result))
    (should (string-match-p "^\\* TODO Third task" result))))

(ert-deftest list-manager-test-latex-to-todo-strips-indentation ()
  "Test that indentation is removed for headlines."
  (let ((result (list-manager-test-with-region "  \\item Indented task"
                  (list-manager-convert-latex-items-to-todo-headlines (point-min) (point-max)))))
    (should (string-match-p "^\\* TODO Indented task" result))))

;;; ============================================================================
;;; Unit Tests: Convert Dash List to TODO Headlines (NEW)
;;; ============================================================================

(ert-deftest list-manager-test-dash-to-todo-basic ()
  "Test converting dash list to TODO headlines."
  (let ((result (list-manager-test-with-region "- First item
- Second item
- Third item"
                  (list-manager-convert-dash-list-to-todo-headlines (point-min) (point-max)))))
    (should (string-match-p "^\\* TODO First item" result))
    (should (string-match-p "^\\* TODO Second item" result))
    (should (string-match-p "^\\* TODO Third item" result))))

(ert-deftest list-manager-test-dash-to-todo-strips-indentation ()
  "Test that indentation is removed."
  (let ((result (list-manager-test-with-region "  - Indented item"
                  (list-manager-convert-dash-list-to-todo-headlines (point-min) (point-max)))))
    (should (string-match-p "^\\* TODO Indented item" result))))

(ert-deftest list-manager-test-dash-to-todo-no-dash ()
  "Test that dash is removed."
  (let ((result (list-manager-test-with-region "- Item"
                  (list-manager-convert-dash-list-to-todo-headlines (point-min) (point-max)))))
    (should-not (string-match-p "^\\* TODO - Item" result))
    (should (string-match-p "^\\* TODO Item" result))))

;;; ============================================================================
;;; Unit Tests: Convert Checklist to TODO Headlines (NEW)
;;; ============================================================================

(ert-deftest list-manager-test-checklist-to-todo-unchecked ()
  "Test converting unchecked items to TODO headlines."
  (let ((result (list-manager-test-with-region "- [ ] Unchecked task"
                  (list-manager-convert-checklist-to-todo-headlines (point-min) (point-max)))))
    (should (string-match-p "^\\* TODO Unchecked task" result))))

(ert-deftest list-manager-test-checklist-to-todo-checked ()
  "Test converting checked items to DONE headlines."
  (let ((result (list-manager-test-with-region "- [X] Checked task"
                  (list-manager-convert-checklist-to-todo-headlines (point-min) (point-max)))))
    (should (string-match-p "^\\* DONE Checked task" result))))

(ert-deftest list-manager-test-checklist-to-todo-mixed ()
  "Test converting mixed checklist to TODO/DONE headlines."
  (let ((result (list-manager-test-with-region "- [ ] Unchecked one
- [X] Checked one
- [ ] Unchecked two
- [x] Checked two lowercase"
                  (list-manager-convert-checklist-to-todo-headlines (point-min) (point-max)))))
    (should (string-match-p "\\* TODO Unchecked one" result))
    (should (string-match-p "\\* DONE Checked one" result))
    (should (string-match-p "\\* TODO Unchecked two" result))
    (should (string-match-p "\\* DONE Checked two lowercase" result))))

;;; ============================================================================
;;; Unit Tests: Convert TODO Headlines to Dash List (NEW)
;;; ============================================================================

(ert-deftest list-manager-test-todo-to-dash-basic ()
  "Test converting TODO headlines to dash list."
  (let ((result (list-manager-test-with-region "* TODO First task
* TODO Second task"
                  (list-manager-convert-todo-headlines-to-dash-list (point-min) (point-max)))))
    (should (string-match-p "^- First task" result))
    (should (string-match-p "^- Second task" result))))

(ert-deftest list-manager-test-todo-to-dash-done ()
  "Test converting DONE headlines to dash list."
  (let ((result (list-manager-test-with-region "* DONE Completed task"
                  (list-manager-convert-todo-headlines-to-dash-list (point-min) (point-max)))))
    (should (string-match-p "^- Completed task" result))))

(ert-deftest list-manager-test-todo-to-dash-various-keywords ()
  "Test converting various TODO keywords to dash list."
  (let ((result (list-manager-test-with-region "* TODO Active
* DONE Completed
* WAITING Blocked
* CANCELLED Dropped
* SOMEDAY Maybe
* NEXT Priority"
                  (list-manager-convert-todo-headlines-to-dash-list (point-min) (point-max)))))
    (should (string-match-p "^- Active" result))
    (should (string-match-p "^- Completed" result))
    (should (string-match-p "^- Blocked" result))
    (should (string-match-p "^- Dropped" result))
    (should (string-match-p "^- Maybe" result))
    (should (string-match-p "^- Priority" result))))

(ert-deftest list-manager-test-todo-to-dash-multi-level ()
  "Test converting multi-level TODO headlines."
  (let ((result (list-manager-test-with-region "** TODO Nested task"
                  (list-manager-convert-todo-headlines-to-dash-list (point-min) (point-max)))))
    (should (string-match-p "^- Nested task" result))))

;;; ============================================================================
;;; Unit Tests: Convert TODO Headlines to Checklist (NEW)
;;; ============================================================================

(ert-deftest list-manager-test-todo-to-checklist-todo ()
  "Test converting TODO headlines to unchecked items."
  (let ((result (list-manager-test-with-region "* TODO Active task"
                  (list-manager-convert-todo-headlines-to-checklist (point-min) (point-max)))))
    (should (string-match-p "^- \\[ \\] Active task" result))))

(ert-deftest list-manager-test-todo-to-checklist-done ()
  "Test converting DONE headlines to checked items."
  (let ((result (list-manager-test-with-region "* DONE Completed task"
                  (list-manager-convert-todo-headlines-to-checklist (point-min) (point-max)))))
    (should (string-match-p "^- \\[X\\] Completed task" result))))

(ert-deftest list-manager-test-todo-to-checklist-cancelled ()
  "Test converting CANCELLED headlines to checked items."
  (let ((result (list-manager-test-with-region "* CANCELLED Dropped task"
                  (list-manager-convert-todo-headlines-to-checklist (point-min) (point-max)))))
    (should (string-match-p "^- \\[X\\] Dropped task" result))))

(ert-deftest list-manager-test-todo-to-checklist-mixed ()
  "Test converting mixed headlines to checklist."
  (let ((result (list-manager-test-with-region "* TODO Active
* DONE Completed
* WAITING Blocked
* NEXT Priority"
                  (list-manager-convert-todo-headlines-to-checklist (point-min) (point-max)))))
    (should (string-match-p "- \\[ \\] Active" result))
    (should (string-match-p "- \\[X\\] Completed" result))
    (should (string-match-p "- \\[ \\] Blocked" result))
    (should (string-match-p "- \\[ \\] Priority" result))))

;;; ============================================================================
;;; Unit Tests: Convert TODO Headlines to LaTeX Items (NEW)
;;; ============================================================================

(ert-deftest list-manager-test-todo-to-latex-basic ()
  "Test converting TODO headlines to LaTeX items."
  (let ((result (list-manager-test-with-region "* TODO First task
* TODO Second task"
                  (list-manager-convert-todo-headlines-to-latex-items (point-min) (point-max)))))
    (should (string-match-p "^\\\\item First task" result))
    (should (string-match-p "^\\\\item Second task" result))))

(ert-deftest list-manager-test-todo-to-latex-done ()
  "Test converting DONE headlines to LaTeX items."
  (let ((result (list-manager-test-with-region "* DONE Completed"
                  (list-manager-convert-todo-headlines-to-latex-items (point-min) (point-max)))))
    (should (string-match-p "^\\\\item Completed" result))))

(ert-deftest list-manager-test-todo-to-latex-various ()
  "Test converting various TODO keywords to LaTeX items."
  (let ((result (list-manager-test-with-region "* TODO Active
* DONE Completed
* WAITING Blocked"
                  (list-manager-convert-todo-headlines-to-latex-items (point-min) (point-max)))))
    (should (string-match-p "\\\\item Active" result))
    (should (string-match-p "\\\\item Completed" result))
    (should (string-match-p "\\\\item Blocked" result))
    ;; Should not contain any TODO keywords
    (should-not (string-match-p "TODO" result))
    (should-not (string-match-p "DONE" result))
    (should-not (string-match-p "WAITING" result))))

;;; ============================================================================
;;; Unit Tests: Convert List to Checkboxes
;;; ============================================================================

(ert-deftest list-manager-test-convert-list-to-checkboxes ()
  "Test converting dash list to checkboxes."
  (let ((result (list-manager-test-with-region "- Item one
- Item two"
                  (list-manager-org-convert-list-in-region-to-checkboxes (point-min) (point-max)))))
    (should (string-match-p "- \\[ \\] Item one" result))
    (should (string-match-p "- \\[ \\] Item two" result))))

;;; ============================================================================
;;; Unit Tests: Convert Checkboxes to List
;;; ============================================================================

(ert-deftest list-manager-test-convert-checkboxes-to-list ()
  "Test converting checkboxes back to dash list."
  (let ((result (list-manager-test-with-region "- [ ] Unchecked
- [X] Checked"
                  (list-manager-org-convert-checkboxes-in-region-to-list (point-min) (point-max)))))
    (should (string-match-p "^- Unchecked" result))
    (should (string-match-p "^- Checked" result))
    (should-not (string-match-p "\\[" result))))

;;; ============================================================================
;;; Unit Tests: Convert Unordered to Ordered List
;;; ============================================================================

(ert-deftest list-manager-test-unordered-to-ordered-dash ()
  "Test converting dash list to numbered list."
  (let ((result (list-manager-test-with-region "- First
- Second
- Third"
                  (list-manager-org-convert-unordered-to-ordered-list (point-min) (point-max)))))
    (should (string-match-p "^1\\. First" result))
    (should (string-match-p "^2\\. Second" result))
    (should (string-match-p "^3\\. Third" result))))

(ert-deftest list-manager-test-unordered-to-ordered-asterisk ()
  "Test converting asterisk list to numbered list."
  (let ((result (list-manager-test-with-region "* First
* Second"
                  (list-manager-org-convert-unordered-to-ordered-list (point-min) (point-max)))))
    (should (string-match-p "^1\\. First" result))
    (should (string-match-p "^2\\. Second" result))))

(ert-deftest list-manager-test-unordered-to-ordered-plus ()
  "Test converting plus list to numbered list."
  (let ((result (list-manager-test-with-region "+ First
+ Second"
                  (list-manager-org-convert-unordered-to-ordered-list (point-min) (point-max)))))
    (should (string-match-p "^1\\. First" result))
    (should (string-match-p "^2\\. Second" result))))

;;; ============================================================================
;;; Unit Tests: Lines in Region to Org List
;;; ============================================================================

(ert-deftest list-manager-test-lines-to-org-list-dash ()
  "Test converting lines to org list with dash marker."
  (with-temp-buffer
    (insert "Line one
Line two")
    (goto-char (point-min))
    (push-mark (point-max) t t)
    (activate-mark)  ; Ensure region is active
    (list-manager-lines-in-region-to-org-list "-")
    (should (string-match-p "^- Line one" (buffer-string)))
    (should (string-match-p "^- Line two" (buffer-string)))))

(ert-deftest list-manager-test-lines-to-org-list-plus ()
  "Test converting lines to org list with plus marker."
  (with-temp-buffer
    (insert "Line one
Line two")
    (goto-char (point-min))
    (push-mark (point-max) t t)
    (activate-mark)  ; Ensure region is active
    (list-manager-lines-in-region-to-org-list "+")
    (should (string-match-p "^\\+ Line one" (buffer-string)))
    (should (string-match-p "^\\+ Line two" (buffer-string)))))

;;; ============================================================================
;;; Unit Tests: Remove Blank Lines
;;; ============================================================================

(ert-deftest list-manager-test-remove-blank-lines ()
  "Test removing blank lines from region."
  (let ((result (list-manager-test-with-region "Line one

Line two

Line three"
                  (list-manager-remove-blank-lines-in-region (point-min) (point-max)))))
    (should (string= result "Line one\nLine two\nLine three"))))

(ert-deftest list-manager-test-remove-blank-lines-whitespace-only ()
  "Test removing lines with only whitespace."
  (let ((result (list-manager-test-with-region "Line one
   
Line two"
                  (list-manager-remove-blank-lines-in-region (point-min) (point-max)))))
    (should (string= result "Line one\nLine two"))))

;;; ============================================================================
;;; Unit Tests: LaTeX Region to Itemized List
;;; ============================================================================

(ert-deftest list-manager-test-latex-region-to-itemized-list ()
  "Test converting region to LaTeX itemized list."
  (let ((result (list-manager-test-with-region "First item
Second item
Third item"
                  (list-manager-latex-region-to-itemized-list (point-min) (point-max)))))
    (should (string-match-p "\\\\begin{itemize}" result))
    (should (string-match-p "\\\\end{itemize}" result))
    (should (string-match-p "\\\\item First item" result))
    (should (string-match-p "\\\\item Second item" result))
    (should (string-match-p "\\\\item Third item" result))))

(ert-deftest list-manager-test-latex-region-to-itemized-list-empty-lines ()
  "Test that empty lines become empty items."
  (let ((result (list-manager-test-with-region "First

Third"
                  (list-manager-latex-region-to-itemized-list (point-min) (point-max)))))
    (should (string-match-p "\\\\begin{itemize}" result))
    ;; Empty line should produce just \item
    (should (string-match-p "\\\\item\n" result))))

;;; ============================================================================
;;; Unit Tests: CSV to LaTeX Itemized List
;;; ============================================================================

(ert-deftest list-manager-test-csv-to-latex-itemized ()
  "Test converting CSV to LaTeX itemized list."
  (let ((result (list-manager-test-with-region "apple, banana, cherry"
                  (list-manager-latex-convert-csv-to-itemized-list (point-min) (point-max)))))
    (should (string-match-p "\\\\begin{itemize}" result))
    (should (string-match-p "\\\\end{itemize}" result))
    (should (string-match-p "\\\\item apple" result))
    (should (string-match-p "\\\\item banana" result))
    (should (string-match-p "\\\\item cherry" result))))

(ert-deftest list-manager-test-csv-to-latex-itemized-trim ()
  "Test that CSV items are trimmed."
  (let ((result (list-manager-test-with-region "  item one  ,  item two  "
                  (list-manager-latex-convert-csv-to-itemized-list (point-min) (point-max)))))
    (should (string-match-p "\\\\item item one\n" result))
    (should (string-match-p "\\\\item item two\n" result))))

;;; ============================================================================
;;; Unit Tests: Add Backslashes to LaTeX Keywords
;;; ============================================================================

(ert-deftest list-manager-test-add-backslashes-section ()
  "Test adding backslash to section keyword."
  (let ((result (list-manager-test-with-temp-buffer "section{Introduction}"
                  (list-manager-add-backslashes (point-min) (point-max)))))
    (should (string-match-p "\\\\section{Introduction}" result))))

(ert-deftest list-manager-test-add-backslashes-multiple ()
  "Test adding backslashes to multiple keywords."
  (let ((result (list-manager-test-with-temp-buffer "section{Intro}
subsection{Details}
item First"
                  (list-manager-add-backslashes (point-min) (point-max)))))
    (should (string-match-p "\\\\section" result))
    (should (string-match-p "\\\\subsection" result))
    (should (string-match-p "\\\\item" result))))

(ert-deftest list-manager-test-add-backslashes-already-escaped ()
  "Test that already escaped keywords are not double-escaped."
  (let ((result (list-manager-test-with-temp-buffer "\\section{Already escaped}"
                  (list-manager-add-backslashes (point-min) (point-max)))))
    ;; Should still have single backslash, not double
    (should (string-match-p "\\\\section" result))
    (should-not (string-match-p "\\\\\\\\section" result))))

(ert-deftest list-manager-test-add-backslashes-begin-end ()
  "Test adding backslashes to begin and end keywords."
  (let ((result (list-manager-test-with-temp-buffer "begin{itemize}
end{itemize}"
                  (list-manager-add-backslashes (point-min) (point-max)))))
    (should (string-match-p "\\\\begin{itemize}" result))
    (should (string-match-p "\\\\end{itemize}" result))))

;;; ============================================================================
;;; Unit Tests: Restore Newlines
;;; ============================================================================

(ert-deftest list-manager-test-restore-newlines-item ()
  "Test restoring newlines before item keyword."
  (let ((result (list-manager-test-with-temp-buffer "text \\item First"
                  (list-manager-restore-newlines (point-min) (point-max)))))
    ;; The function inserts newline before \item but may leave the trailing space
    (should (string-match-p "text.*\n\\\\item First" result))))

(ert-deftest list-manager-test-restore-newlines-begin ()
  "Test restoring newlines before begin keyword."
  (let ((result (list-manager-test-with-temp-buffer "some text \\begin{itemize}"
                  (list-manager-restore-newlines (point-min) (point-max)))))
    ;; The function inserts newline before \begin but may leave trailing space
    (should (string-match-p "text.*\n\\\\begin{itemize}" result))))

(ert-deftest list-manager-test-restore-newlines-already-at-bol ()
  "Test that newlines are not added when keyword is already at beginning of line."
  (let ((result (list-manager-test-with-temp-buffer "\\item Already at BOL"
                  (list-manager-restore-newlines (point-min) (point-max)))))
    (should (string= result "\\item Already at BOL"))))

;;; ============================================================================
;;; Unit Tests: Split Line by Sentences
;;; ============================================================================

(ert-deftest list-manager-test-split-by-sentences-basic ()
  "Test splitting text by sentences."
  (let ((result (list-manager-test-with-region "First sentence. Second sentence. Third sentence."
                  (list-manager-split-line-by-sentences (point-min) (point-max)))))
    (should (string-match-p "First sentence\\.\n" result))
    (should (string-match-p "Second sentence\\.\n" result))))

(ert-deftest list-manager-test-split-by-sentences-abbreviations ()
  "Test that abbreviations are preserved."
  (let ((result (list-manager-test-with-region "Dr. Smith said hello. Mr. Jones agreed."
                  (list-manager-split-line-by-sentences (point-min) (point-max)))))
    ;; Dr. should not cause a split
    (should (string-match-p "Dr\\. Smith" result))
    ;; Mr. should not cause a split
    (should (string-match-p "Mr\\. Jones" result))))

(ert-deftest list-manager-test-split-by-sentences-exclamation ()
  "Test splitting on exclamation marks."
  (let ((result (list-manager-test-with-region "Hello! How are you?"
                  (list-manager-split-line-by-sentences (point-min) (point-max)))))
    (should (string-match-p "Hello!\n" result))))

(ert-deftest list-manager-test-split-by-sentences-question ()
  "Test splitting on question marks."
  (let ((result (list-manager-test-with-region "What is this? It is a test."
                  (list-manager-split-line-by-sentences (point-min) (point-max)))))
    (should (string-match-p "What is this\\?\n" result))))

;;; ============================================================================
;;; Unit Tests: Beginning and End of List
;;; ============================================================================

(ert-deftest list-manager-test-beginning-of-list ()
  "Test moving to beginning of list."
  (with-temp-buffer
    (insert "Some text

- Item one
- Item two
- Item three

More text")
    (goto-char (point-min))
    (search-forward "Item two")
    (beginning-of-line)
    (list-manager-beginning-of-list)
    (let ((current-line (buffer-substring-no-properties
                         (line-beginning-position)
                         (line-end-position))))
      (should (or (string= current-line "")
                  (string-match-p "- Item one" current-line))))))

(ert-deftest list-manager-test-end-of-list ()
  "Test moving to end of list."
  (with-temp-buffer
    (insert "- Item one
- Item two
- Item three
Some text after")
    (goto-char (point-min))
    (list-manager-end-of-list)
    (should (looking-at-p "Some text after"))))

;;; ============================================================================
;;; Integration Tests: Bidirectional Conversions
;;; ============================================================================

(ert-deftest list-manager-integration-test-dash-to-checklist-roundtrip ()
  "Integration test: dash list -> checklist -> dash list."
  (let* ((original "- Item one
- Item two
- Item three")
         (result (list-manager-test-with-region original
                   (list-manager-org-convert-list-in-region-to-checkboxes (point-min) (point-max))
                   (list-manager-convert-org-checklist-to-dash-list (point-min) (point-max)))))
    (should (string-match-p "^- Item one" result))
    (should (string-match-p "^- Item two" result))
    (should (string-match-p "^- Item three" result))
    (should-not (string-match-p "\\[" result))))

(ert-deftest list-manager-integration-test-dash-to-latex-roundtrip ()
  "Integration test: dash list -> LaTeX -> dash list.
Note: The roundtrip preserves indentation added during LaTeX conversion."
  (let* ((result (list-manager-test-with-region "- First
- Second
- Third"
                   (list-manager-org-dash-list-to-latex-items)
                   (list-manager-convert-latex-items-to-dash-list (point-min) (point-max)))))
    ;; The roundtrip adds indentation because org-dash-list-to-latex-items
    ;; produces "    \item" which converts back to "    -"
    (should (string-match-p "- First" result))
    (should (string-match-p "- Second" result))
    (should (string-match-p "- Third" result))))

(ert-deftest list-manager-integration-test-checklist-to-latex-roundtrip ()
  "Integration test: checklist -> LaTeX -> checklist."
  (let* ((result (list-manager-test-with-region "- [ ] Task one
- [ ] Task two"
                   (list-manager-convert-org-checklist-to-latex-items (point-min) (point-max))
                   (list-manager-convert-latex-items-to-org-checklist (point-min) (point-max)))))
    (should (string-match-p "- \\[ \\] Task one" result))
    (should (string-match-p "- \\[ \\] Task two" result))))

(ert-deftest list-manager-integration-test-dash-to-todo-roundtrip ()
  "Integration test: dash list -> TODO -> dash list."
  (let* ((result (list-manager-test-with-region "- Task one
- Task two"
                   (list-manager-convert-dash-list-to-todo-headlines (point-min) (point-max))
                   (list-manager-convert-todo-headlines-to-dash-list (point-min) (point-max)))))
    (should (string-match-p "^- Task one" result))
    (should (string-match-p "^- Task two" result))))

(ert-deftest list-manager-integration-test-checklist-to-todo-roundtrip ()
  "Integration test: checklist -> TODO -> checklist (preserving state)."
  (let* ((result (list-manager-test-with-region "- [ ] Unchecked
- [X] Checked"
                   (list-manager-convert-checklist-to-todo-headlines (point-min) (point-max))
                   (list-manager-convert-todo-headlines-to-checklist (point-min) (point-max)))))
    (should (string-match-p "- \\[ \\] Unchecked" result))
    (should (string-match-p "- \\[X\\] Checked" result))))

(ert-deftest list-manager-integration-test-latex-to-todo-roundtrip ()
  "Integration test: LaTeX -> TODO -> LaTeX."
  (let* ((result (list-manager-test-with-region "\\item First
\\item Second"
                   (list-manager-convert-latex-items-to-todo-headlines (point-min) (point-max))
                   (list-manager-convert-todo-headlines-to-latex-items (point-min) (point-max)))))
    (should (string-match-p "\\\\item First" result))
    (should (string-match-p "\\\\item Second" result))))

;;; ============================================================================
;;; Integration Tests: Multi-Step Workflows
;;; ============================================================================

(ert-deftest list-manager-integration-test-lines-to-todo-via-dash ()
  "Integration test: plain lines -> dash list -> TODO headlines."
  (with-temp-buffer
    (insert "Task one
Task two
Task three")
    (goto-char (point-min))
    (push-mark (point-max) t t)
    (activate-mark)
    (list-manager-lines-in-region-to-org-list "-")
    (list-manager-convert-dash-list-to-todo-headlines (point-min) (point-max))
    (should (string-match-p "\\* TODO Task one" (buffer-string)))
    (should (string-match-p "\\* TODO Task two" (buffer-string)))
    (should (string-match-p "\\* TODO Task three" (buffer-string)))))

(ert-deftest list-manager-integration-test-todo-to-latex-env ()
  "Integration test: TODO headlines -> LaTeX items with environment."
  (let ((result (list-manager-test-with-region "* TODO First
* DONE Second
* TODO Third"
                  (list-manager-convert-todo-headlines-to-latex-items (point-min) (point-max))
                  (goto-char (point-min))
                  (insert "\\begin{itemize}\n")
                  (goto-char (point-max))
                  (insert "\n\\end{itemize}"))))
    (should (string-match-p "\\\\begin{itemize}" result))
    (should (string-match-p "\\\\item First" result))
    (should (string-match-p "\\\\item Second" result))
    (should (string-match-p "\\\\item Third" result))
    (should (string-match-p "\\\\end{itemize}" result))))

(ert-deftest list-manager-integration-test-org-to-latex-workflow ()
  "Integration test: org list -> checkboxes -> LaTeX items."
  (with-temp-buffer
    (insert "Task one
Task two
Task three")
    (goto-char (point-min))
    (push-mark (point-max) t t)
    (activate-mark)
    ;; Convert to org list
    (list-manager-lines-in-region-to-org-list "-")
    (should (string-match-p "^- Task one" (buffer-string)))
    ;; Convert to checkboxes
    (list-manager-org-convert-list-in-region-to-checkboxes (point-min) (point-max))
    (should (string-match-p "- \\[ \\] Task one" (buffer-string)))
    ;; Convert back to dash list
    (list-manager-convert-org-checklist-to-dash-list (point-min) (point-max))
    (should (string-match-p "^- Task one" (buffer-string)))
    (should-not (string-match-p "\\[ \\]" (buffer-string)))))

(ert-deftest list-manager-integration-test-latex-formatting-recovery ()
  "Integration test: recover LaTeX formatting stripped by 750words."
  (let ((result (list-manager-test-with-temp-buffer "section{Intro} begin{itemize} item First item Second end{itemize}"
                  (list-manager-add-backslashes (point-min) (point-max))
                  (list-manager-restore-newlines (point-min) (point-max)))))
    ;; All keywords should have backslashes
    (should (string-match-p "\\\\section" result))
    (should (string-match-p "\\\\begin{itemize}" result))
    (should (string-match-p "\\\\item" result))
    (should (string-match-p "\\\\end{itemize}" result))
    ;; Items should be on separate lines
    (should (string-match-p "\n\\\\item First" result))))

(ert-deftest list-manager-integration-test-extract-and-cut-workflow ()
  "Integration test: extract unchecked, verify, then cut."
  (with-temp-buffer
    (insert "- [ ] Task A
- [X] Task B (done)
- [ ] Task C
- [X] Task D (done)")
    ;; First extract to see what would be affected
    (list-manager-extract-unchecked-items-to-kill-ring (point-min) (point-max))
    (let ((extracted (car kill-ring)))
      (should (string-match-p "Task A" extracted))
      (should (string-match-p "Task C" extracted))
      (should-not (string-match-p "Task B" extracted))
      (should-not (string-match-p "Task D" extracted)))
    ;; Now cut the unchecked items
    (list-manager-cut-unchecked-items-to-kill-ring (point-min) (point-max))
    ;; Original buffer should only have completed items
    (should (string-match-p "Task B" (buffer-string)))
    (should (string-match-p "Task D" (buffer-string)))
    (should-not (string-match-p "Task A" (buffer-string)))
    (should-not (string-match-p "Task C" (buffer-string)))))

(ert-deftest list-manager-integration-test-numbered-to-latex-env ()
  "Integration test: numbered list to complete LaTeX environment."
  (let ((result (list-manager-test-with-region "1. First point
2. Second point
3. Third point"
                  (list-manager-numbered-list-to-latex-items)
                  (goto-char (point-min))
                  (insert "\\begin{enumerate}\n")
                  (goto-char (point-max))
                  (insert "\\end{enumerate}\n"))))
    (should (string-match-p "\\\\begin{enumerate}" result))
    (should (string-match-p "\\\\item First point" result))
    (should (string-match-p "\\\\item Second point" result))
    (should (string-match-p "\\\\item Third point" result))
    (should (string-match-p "\\\\end{enumerate}" result))))

(ert-deftest list-manager-integration-test-csv-cleanup-workflow ()
  "Integration test: CSV to LaTeX with blank line removal."
  (let ((result (list-manager-test-with-region "apple

banana

cherry"
                  ;; First remove blank lines
                  (list-manager-remove-blank-lines-in-region (point-min) (point-max))
                  ;; Then convert remaining text to items
                  (list-manager-lines-to-latex-items (point-min) (point-max)))))
    (should (string-match-p "\\\\item apple" result))
    (should (string-match-p "\\\\item banana" result))
    (should (string-match-p "\\\\item cherry" result))))

(ert-deftest list-manager-integration-test-mixed-list-types ()
  "Integration test: handle mixed list markers."
  (let ((result-dash (list-manager-test-with-region "- Item"
                       (list-manager-dash-list-to-latex-items)))
        (result-asterisk (list-manager-test-with-region "* Item"
                           (list-manager-dash-list-to-latex-items)))
        (result-plus (list-manager-test-with-region "+ Item"
                       (list-manager-dash-list-to-latex-items))))
    ;; All should produce the same LaTeX output
    (should (string-match-p "\\\\item Item" result-dash))
    (should (string-match-p "\\\\item Item" result-asterisk))
    (should (string-match-p "\\\\item Item" result-plus))))

;;; ============================================================================
;;; Integration Tests: Full Conversion Matrix
;;; ============================================================================

(ert-deftest list-manager-integration-test-full-matrix-from-dash ()
  "Test all conversions starting from dash list."
  (let ((original "- Task A
- Task B"))
    ;; Dash -> Checklist
    (let ((result (list-manager-test-with-region original
                    (list-manager-org-convert-list-in-region-to-checkboxes (point-min) (point-max)))))
      (should (string-match-p "- \\[ \\] Task A" result)))
    ;; Dash -> TODO
    (let ((result (list-manager-test-with-region original
                    (list-manager-convert-dash-list-to-todo-headlines (point-min) (point-max)))))
      (should (string-match-p "\\* TODO Task A" result)))
    ;; Dash -> LaTeX
    (let ((result (list-manager-test-with-region original
                    (list-manager-org-dash-list-to-latex-items))))
      (should (string-match-p "\\\\item Task A" result)))))

(ert-deftest list-manager-integration-test-full-matrix-from-checklist ()
  "Test all conversions starting from checklist."
  (let ((original "- [ ] Task A
- [X] Task B"))
    ;; Checklist -> Dash
    (let ((result (list-manager-test-with-region original
                    (list-manager-convert-org-checklist-to-dash-list (point-min) (point-max)))))
      (should (string-match-p "^- Task A" result))
      (should-not (string-match-p "\\[" result)))
    ;; Checklist -> TODO
    (let ((result (list-manager-test-with-region original
                    (list-manager-convert-checklist-to-todo-headlines (point-min) (point-max)))))
      (should (string-match-p "\\* TODO Task A" result))
      (should (string-match-p "\\* DONE Task B" result)))
    ;; Checklist -> LaTeX
    (let ((result (list-manager-test-with-region original
                    (list-manager-convert-org-checklist-to-latex-items (point-min) (point-max)))))
      (should (string-match-p "\\\\item Task A" result)))))

(ert-deftest list-manager-integration-test-full-matrix-from-todo ()
  "Test all conversions starting from TODO headlines."
  (let ((original "* TODO Task A
* DONE Task B"))
    ;; TODO -> Dash
    (let ((result (list-manager-test-with-region original
                    (list-manager-convert-todo-headlines-to-dash-list (point-min) (point-max)))))
      (should (string-match-p "^- Task A" result)))
    ;; TODO -> Checklist
    (let ((result (list-manager-test-with-region original
                    (list-manager-convert-todo-headlines-to-checklist (point-min) (point-max)))))
      (should (string-match-p "- \\[ \\] Task A" result))
      (should (string-match-p "- \\[X\\] Task B" result)))
    ;; TODO -> LaTeX
    (let ((result (list-manager-test-with-region original
                    (list-manager-convert-todo-headlines-to-latex-items (point-min) (point-max)))))
      (should (string-match-p "\\\\item Task A" result)))))

(ert-deftest list-manager-integration-test-full-matrix-from-latex ()
  "Test all conversions starting from LaTeX items."
  (let ((original "\\item Task A
\\item Task B"))
    ;; LaTeX -> Dash
    (let ((result (list-manager-test-with-region original
                    (list-manager-convert-latex-items-to-dash-list (point-min) (point-max)))))
      (should (string-match-p "^- Task A" result)))
    ;; LaTeX -> Checklist
    (let ((result (list-manager-test-with-region original
                    (list-manager-convert-latex-items-to-org-checklist (point-min) (point-max)))))
      (should (string-match-p "- \\[ \\] Task A" result)))
    ;; LaTeX -> TODO
    (let ((result (list-manager-test-with-region original
                    (list-manager-convert-latex-items-to-todo-headlines (point-min) (point-max)))))
      (should (string-match-p "\\* TODO Task A" result)))))

;;; ============================================================================
;;; Edge Case Tests
;;; ============================================================================

(ert-deftest list-manager-test-edge-empty-buffer ()
  "Test behavior with empty buffer."
  (let ((result (list-manager-test-with-region ""
                  (list-manager-remove-blank-lines-in-region (point-min) (point-max)))))
    (should (string= result ""))))

(ert-deftest list-manager-test-edge-single-item ()
  "Test behavior with single item list."
  (let ((result (list-manager-test-with-region "- Single item"
                  (list-manager-dash-list-to-latex-items))))
    (should (string-match-p "\\\\item Single item" result))))

(ert-deftest list-manager-test-edge-special-characters ()
  "Test that special characters in list items are preserved."
  (let ((result (list-manager-test-with-region "- Item with $math$ and &ampersand"
                  (list-manager-dash-list-to-latex-items))))
    (should (string-match-p "\\$math\\$" result))
    (should (string-match-p "&ampersand" result))))

(ert-deftest list-manager-test-edge-unicode ()
  "Test that unicode characters are preserved."
  (let ((result (list-manager-test-with-region "- Café résumé naïve"
                  (list-manager-dash-list-to-latex-items))))
    (should (string-match-p "Café résumé naïve" result))))

(ert-deftest list-manager-test-edge-very-long-item ()
  "Test handling of very long list items."
  (let* ((long-text (make-string 500 ?x))
         (input (format "- %s" long-text))
         (result (list-manager-test-with-region input
                   (list-manager-dash-list-to-latex-items))))
    (should (string-match-p (concat "\\\\item " long-text) result))))

(ert-deftest list-manager-test-edge-nested-brackets ()
  "Test items with nested brackets."
  (let ((result (list-manager-test-with-region "- Item [with [nested] brackets]"
                  (list-manager-dash-list-to-latex-items))))
    (should (string-match-p "\\\\item Item \\[with \\[nested\\] brackets\\]" result))))

(ert-deftest list-manager-test-edge-checkbox-variations ()
  "Test various checkbox styles."
  (with-temp-buffer
    (insert "- [ ] Unchecked space
- [x] Checked lowercase
- [X] Checked uppercase
- [-] Partially done")
    (list-manager-extract-unchecked-items (point-min) (point-max))
    (let ((output-buffer (get-buffer "*Unchecked Items*")))
      (when output-buffer
        (with-current-buffer output-buffer
          ;; Only the space checkbox should be extracted as unchecked
          (should (string-match-p "Unchecked space" (buffer-string))))
        (kill-buffer output-buffer)))))

(ert-deftest list-manager-test-edge-empty-todo ()
  "Test conversion with no matching TODO items."
  (let ((result (list-manager-test-with-region "Regular text
Not a TODO item"
                  (list-manager-convert-todo-headlines-to-dash-list (point-min) (point-max)))))
    ;; Should be unchanged
    (should (string= result "Regular text\nNot a TODO item"))))

(ert-deftest list-manager-test-edge-empty-latex ()
  "Test conversion with no matching LaTeX items."
  (let ((result (list-manager-test-with-region "Regular text
Not a latex item"
                  (list-manager-convert-latex-items-to-dash-list (point-min) (point-max)))))
    ;; Should be unchanged
    (should (string= result "Regular text\nNot a latex item"))))

;;; ============================================================================
;;; Regression Tests
;;; ============================================================================

(ert-deftest list-manager-regression-test-preserve-trailing-content ()
  "Regression test: ensure content after list is preserved."
  (let ((result (list-manager-test-with-region "- Item one
- Item two
This text should remain"
                  (narrow-to-region (point-min) (- (point-max) 24))
                  (list-manager-dash-list-to-latex-items)
                  (widen))))
    (should (string-match-p "This text should remain" result))))

(ert-deftest list-manager-regression-test-indentation-consistency ()
  "Regression test: ensure consistent indentation in output."
  (let ((result (list-manager-test-with-region "- Item one
  - Nested item
- Item two"
                  (list-manager-dash-list-to-latex-items))))
    ;; All items should be converted, nested ones too
    (should (string-match-p "\\\\item Item one" result))
    (should (string-match-p "\\\\item Nested item" result))
    (should (string-match-p "\\\\item Item two" result))))

(ert-deftest list-manager-regression-test-cut-latex-format ()
  "Regression test: cut items should be in LaTeX format."
  (with-temp-buffer
    (insert "- [ ] Task to cut")
    (list-manager-cut-unchecked-items-to-kill-ring (point-min) (point-max))
    (let ((killed (car kill-ring)))
      ;; Must be LaTeX format, not org format
      (should (string-match-p "\\\\item" killed))
      (should-not (string-match-p "^- \\[ \\]" killed)))))

;;; ============================================================================
;;; Unit Tests: Enhanced Org Dash List to LaTeX Items
;;; ============================================================================

(ert-deftest list-manager-test-enhanced-plain-item ()
  "Test enhanced conversion with a plain \\item format.
Regression: backslashes in the format must be inserted literally."
  (let ((result (list-manager-test-with-region "- Apple
- Banana"
                  (list-manager-org-dash-list-to-latex-items-enhanced "\\item"))))
    (should (string-match-p "^    \\\\item Apple" result))
    (should (string-match-p "^    \\\\item Banana" result))))

(ert-deftest list-manager-test-enhanced-format-placeholder ()
  "Test enhanced conversion with a %s placeholder in the format."
  (let ((result (list-manager-test-with-region "- Apple"
                  (list-manager-org-dash-list-to-latex-items-enhanced "\\item \\textbf{%s}"))))
    (should (string-match-p "\\\\item \\\\textbf{Apple}" result))))

(ert-deftest list-manager-test-enhanced-all-items-converted ()
  "Regression: every item is converted, not just the first."
  (let ((result (list-manager-test-with-region "- One
- Two
- Three"
                  (list-manager-org-dash-list-to-latex-items-enhanced "\\item"))))
    (should (= 3 (cl-count-if (lambda (l) (string-match-p "\\\\item" l))
                              (split-string result "\n"))))))

;;; ============================================================================
;;; Unit Tests: Repair Stripped Item List
;;; ============================================================================

(ert-deftest list-manager-test-repair-stripped-item-list ()
  "Test rebuilding a flattened LaTeX \\item list."
  (let ((result (list-manager-test-with-region "item Do this. item Do that."
                  (list-manager-repair-stripped-item-list (point-min) (point-max)))))
    (should (string-match-p "^\\\\item Do this\\." result))
    (should (string-match-p "^\\\\item Do that\\." result))))

(ert-deftest list-manager-test-repair-stripped-item-list-idempotent ()
  "Test that repair is safe to run twice and leaves proper markers intact."
  (let ((result (list-manager-test-with-region "\\item Do this.
\\item Do that."
                  (list-manager-repair-stripped-item-list (point-min) (point-max)))))
    (should (string-match-p "\\\\item Do this\\." result))
    (should (string-match-p "\\\\item Do that\\." result))
    ;; No doubled backslashes introduced.
    (should-not (string-match-p "\\\\\\\\item" result))))

(ert-deftest list-manager-test-repair-stripped-item-list-preserves-itemize ()
  "Regression: a bare word like `itemize' must not be split."
  (let ((result (list-manager-test-with-region "\\item Use itemize here."
                  (list-manager-repair-stripped-item-list (point-min) (point-max)))))
    (should (string-match-p "Use itemize here\\." result))
    (should-not (string-match-p "item ize" result))))

;;; ============================================================================
;;; Unit Tests: Add Periods to List Items
;;; ============================================================================

(ert-deftest list-manager-test-org-add-periods-to-list-items ()
  "Test adding periods to org dash list items."
  (let ((result (list-manager-test-with-region "- First item
- Second item"
                  (list-manager-org-add-periods-to-list-items (point-min) (point-max)))))
    (should (string-match-p "- First item\\." result))
    (should (string-match-p "- Second item\\." result))))

(ert-deftest list-manager-test-org-add-periods-preserves-checkboxes ()
  "Test that checkboxes are preserved when adding periods."
  (let ((result (list-manager-test-with-region "- [ ] First
- [X] Second"
                  (list-manager-org-add-periods-to-list-items (point-min) (point-max)))))
    (should (string-match-p "- \\[ \\] First\\." result))
    (should (string-match-p "- \\[X\\] Second\\." result))))

(ert-deftest list-manager-test-org-or-latex-add-periods-org ()
  "Test add-periods on an org dash list starting at point-min.
Regression: the first item must also receive a period."
  (with-temp-buffer
    (insert "- First item
- Second item
")
    (goto-char (point-min))
    (list-manager-org-or-latex-add-periods-to-list)
    (should (string-match-p "- First item\\." (buffer-string)))
    (should (string-match-p "- Second item\\." (buffer-string)))))

(ert-deftest list-manager-test-org-or-latex-add-periods-latex ()
  "Test add-periods on a LaTeX \\item list."
  (with-temp-buffer
    (insert "\\item First
\\item Second
")
    (goto-char (point-min))
    (list-manager-org-or-latex-add-periods-to-list)
    (should (string-match-p "\\\\item First\\." (buffer-string)))
    (should (string-match-p "\\\\item Second\\." (buffer-string)))))

(ert-deftest list-manager-test-org-or-latex-add-periods-idempotent ()
  "Test that items already ending in a period are not doubled."
  (with-temp-buffer
    (insert "- First item.
- Second item.
")
    (goto-char (point-min))
    (list-manager-org-or-latex-add-periods-to-list)
    (should-not (string-match-p "\\.\\." (buffer-string)))))

;;; ============================================================================
;;; Unit Tests: Beginning of List at Buffer Start
;;; ============================================================================

(ert-deftest list-manager-test-beginning-of-list-at-bob ()
  "Regression: beginning-of-list lands on the first item when the
list is the very first thing in the buffer (no overshoot)."
  (with-temp-buffer
    (insert "- Item one
- Item two
- Item three
After")
    (goto-char (point-min))
    (search-forward "Item two")
    (beginning-of-line)
    (list-manager-beginning-of-list)
    (should (string-match-p "^- Item one"
                            (buffer-substring-no-properties
                             (line-beginning-position)
                             (line-end-position))))))

;;; ============================================================================
;;; Unit Tests: Lines / Strings to Org Checklist
;;; ============================================================================

(ert-deftest list-manager-test-convert-lines-to-org-checklist ()
  "Test converting mixed lines to an org checklist."
  (let ((result (list-manager-test-with-region "First line
- Already dash
- [ ] Already box"
                  (list-manager-org-convert-lines-to-org-checklist (point-min) (point-max)))))
    (should (string-match-p "^- \\[ \\] First line" result))
    (should (string-match-p "^- \\[ \\] Already dash" result))
    ;; An existing checkbox is preserved, not doubled.
    (should (string-match-p "^- \\[ \\] Already box" result))
    (should-not (string-match-p "\\[ \\] \\[ \\]" result))))

(ert-deftest list-manager-test-string-to-org-checklist ()
  "Test converting a plain string to org checklist format."
  (let ((result (list-manager-string-to-org-checklist "Task one
Task two")))
    (should (string-match-p "^- \\[ \\] Task one" result))
    (should (string-match-p "^- \\[ \\] Task two" result))))

(ert-deftest list-manager-test-org-checklist-from-kill-ring ()
  "Test converting the latest kill-ring entry to an org checklist."
  (kill-new "Buy milk
Call mom")
  (list-manager-org-checklist-from-kill-ring)
  (let ((converted (car kill-ring)))
    (should (string-match-p "^- \\[ \\] Buy milk" converted))
    (should (string-match-p "^- \\[ \\] Call mom" converted))))

;;; ============================================================================
;;; Unit Tests: Unwrap to One Sentence Per Line
;;; ============================================================================

(ert-deftest list-manager-test-unwrap-one-sentence-per-line ()
  "Test that wrapped lines are joined and split one sentence per line."
  (let ((result (list-manager-test-with-region "This sentence is
wrapped across lines. Second one here."
                  (list-manager-unwrap-to-one-sentence-per-line (point-min) (point-max)))))
    (should (string-match-p "This sentence is wrapped across lines\\.\n" result))
    (should (string-match-p "Second one here\\." result))))

;;; ============================================================================
;;; Unit Tests: Restore LaTeX Formatting (Combined 750words Recovery)
;;; ============================================================================

(ert-deftest list-manager-test-restore-latex-formatting ()
  "Test the combined backslash + newline recovery.
Regression: the wrapper must call the list-manager- helpers, not the
old list- names, so it should not error."
  (let ((result (list-manager-test-with-temp-buffer "section{Intro} item First item Second"
                  (list-manager-restore-latex-formatting (point-min) (point-max)))))
    (should (string-match-p "\\\\section{Intro}" result))
    (should (string-match-p "\\\\item First" result))
    (should (string-match-p "\\\\item Second" result))
    ;; Items land on their own lines.
    (should (string-match-p "\n\\\\item Second" result))))

;;; ============================================================================
;;; Performance Tests (Optional)
;;; ============================================================================

(ert-deftest list-manager-performance-test-large-list ()
  "Performance test: handle large lists efficiently."
  :tags '(:slow)
  (let* ((item-count 1000)
         (items (mapconcat (lambda (n) (format "- Item %d" n))
                           (number-sequence 1 item-count)
                           "\n"))
         (start-time (current-time)))
    (list-manager-test-with-region items
      (list-manager-dash-list-to-latex-items))
    (let ((elapsed (float-time (time-subtract (current-time) start-time))))
      ;; Should complete in under 5 seconds
      (should (< elapsed 5.0)))))

(ert-deftest list-manager-performance-test-large-todo-conversion ()
  "Performance test: handle large TODO list conversion."
  :tags '(:slow)
  (let* ((item-count 500)
         (items (mapconcat (lambda (n) (format "* TODO Task %d" n))
                           (number-sequence 1 item-count)
                           "\n"))
         (start-time (current-time)))
    (list-manager-test-with-region items
      (list-manager-convert-todo-headlines-to-latex-items (point-min) (point-max)))
    (let ((elapsed (float-time (time-subtract (current-time) start-time))))
      (should (< elapsed 5.0)))))

;;; ============================================================================
;;; Provide
;;; ============================================================================

(provide 'list-manager-test)

;;; list-manager-test.el ends here
