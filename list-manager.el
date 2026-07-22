;;; insert-checked.el --- Insert [\checked] after list item markers -*- lexical-binding: t; -*-

;; Author: Blaine Mooers
;; Version: 1.0
;; Keywords: convenience, lists, latex, org

;;; Commentary:

;; This package provides functions to manage lists in org-mode and LaTeX.
;;

;;; Code:


(defun list-manager-unwrap-to-one-sentence-per-line (&optional beg end)
  "Reflow the region, or the current paragraph, to one sentence per line.
First joins the wrapped lines of the paragraph, then inserts a newline
after each sentence so that every sentence sits on its own line.

`sentence-end-double-space' is bound to nil here so that sentences
separated by a single space are still detected; abbreviations such as
\"Fig.\" or \"e.g.\" may cause an occasional unwanted break."
  (interactive
   (if (use-region-p)
       (list (region-beginning) (region-end))
     (let ((b (bounds-of-thing-at-point 'paragraph)))
       (unless b (user-error "No paragraph at point"))
       (list (car b) (cdr b)))))
  (let ((sentence-end-double-space nil))
    (save-excursion
      (save-restriction
        (narrow-to-region beg end)
        ;; 1. Unwrap: every internal newline (with surrounding whitespace)
        ;;    becomes a single space.
        (goto-char (point-min))
        (while (re-search-forward "[ \t]*\n[ \t]*" nil t)
          (replace-match " "))
        ;; 2. Collapse any runs of spaces left behind.
        (goto-char (point-min))
        (while (re-search-forward "[ \t]\\{2,\\}" nil t)
          (replace-match " "))
        ;; 3. One newline after each sentence.
        (goto-char (point-min))
        (while (< (point) (point-max))
          (forward-sentence)
          (when (< (point) (point-max))
            (delete-horizontal-space)
            (unless (eolp) (insert "\n"))))))))


(defun list-manager-numbered-list-to-latex-items ()
  "Convert a numbered list to LaTeX \\item statements."
  (interactive)
  (save-excursion
    (save-restriction
      (narrow-to-region (region-beginning) (region-end))
      (goto-char (point-min))
      (while (re-search-forward "^\\s-*[0-9]+\\.\\s-+" nil t)
        (replace-match "\\\\item " nil nil))
      (goto-char (point-min))
      (while (re-search-forward "\\\\item\\s-+\\(.*\\)" nil t)
        (replace-match "\\\\item \\1%" nil nil))
      (goto-char (point-min))
      (while (search-forward "%" nil t)
        (replace-match "\n" nil t)))))


(defun list-manager-dash-list-to-latex-items ()
  "Convert a dash list to LaTeX \\item statements."
  (interactive)
  (save-excursion
    (save-restriction
      (narrow-to-region (region-beginning) (region-end))
      (goto-char (point-min))
      (while (re-search-forward "^\\s-*[-*+]\\s-+" nil t)
        (replace-match "\\\\item " nil nil))
      (goto-char (point-min))
      (while (re-search-forward "\\\\item\\s-+\\(.*\\)" nil t)
        (replace-match "\\\\item \\1%" nil nil))
      (goto-char (point-min))
      (while (search-forward "%" nil t)
        (replace-match "\n" nil t)))))


;; Enhanced version with more options
(defun list-manager-org-dash-list-to-latex-items-enhanced (item-format)
  "Convert org-mode dash list to LaTeX items with custom formatting.
ITEM-FORMAT should be a string like '\\\\item' or '\\\\item \\\\textbf{%s}'."
  (interactive "sItem format (use %s for content): ")
  (let ((start (if (use-region-p) (region-beginning) (point-min)))
        (end (if (use-region-p) (region-end) (point-max)))
        (format-str (if (string-match "%s" item-format)
                        item-format
                      (concat item-format " %s"))))
    (save-excursion
      (goto-char start)
      (while (re-search-forward "^\\s-*- \\(.*\\)$" end t)
        (let* ((content (match-string 1))
               (replacement (format format-str content)))
          (replace-match (concat "    " replacement))
          (setq end (+ end (- (length replacement) (length content) 1))))))))


;; Convert with full LaTeX environment wrapper
(defun list-manager-org-dash-list-to-latex-itemize ()
  "Convert org-mode dash list to complete LaTeX itemize environment."
  (interactive)
  (let ((start (if (use-region-p) (region-beginning) (point-min)))
        (end (if (use-region-p) (region-end) (point-max)))
        (items '()))
    (save-excursion
      (goto-char start)
      (while (re-search-forward "^\\s-*- \\(.*\\)$" end t)
        (push (match-string 1) items)))
    (when items
      (delete-region start end)
      (goto-char start)
      (insert "#+BEGIN_EXPORT latex\n")
      (insert "\\begin{itemize}\n")
      (dolist (item (reverse items))
        (insert (format "    \\item %s\n" item)))
      (insert "\\end{itemize}\n")
      (insert "#+END_EXPORT\n"))))


;; Convert with your specific bullet style
(defun list-manager-org-dash-list-to-custom-latex ()
  "Convert org-mode dash list to LaTeX with custom bullet formatting for beamer slideshows."
  (interactive)
  (let ((start (if (use-region-p) (region-beginning) (point-min)))
        (end (if (use-region-p) (region-end) (point-max)))
        (items '()))
    (save-excursion
      (goto-char start)
      (while (re-search-forward "^\\s-*- \\(.*\\)$" end t)
        (push (match-string 1) items)))
    (when items
      (delete-region start end)
      (goto-char start)
      (insert "#+BEGIN_EXPORT latex\n")
      (insert "\\Large{\n")
      (insert "\\begin{itemize}[font=$\\bullet$\\scshape\\bfseries]\n")
      (dolist (item (reverse items))
        (insert (format "    \\item %s\n" item)))
      (insert "\\end{itemize}\n")
      (insert "}\n")
      (insert "#+END_EXPORT\n"))))


(defun list-manager-org-list-package-functions ()
  "Return a dashed org-mode list of all functions in a package.
   Prompts the user for a package name in the minibuffer."
  (interactive)
  (let* ((package-name (intern (completing-read "Package name: "
                                               (mapcar #'symbol-name features))))
         (package-symbols (apropos-internal (concat "^" (symbol-name package-name) "-") 'fboundp))
         (buffer (get-buffer-create (format "*%s-functions*" package-name)))
         (functions-list))

    ;; Create list of function symbols in the package
    (setq functions-list
          (sort (mapcar #'symbol-name package-symbols) #'string<))

    ;; Switch to the output buffer
    (switch-to-buffer buffer)
    (erase-buffer)
    (org-mode)

    ;; Insert header
    (insert (format "* Functions in package: %s\n\n" package-name))

    ;; Insert functions as dashed list
    (if functions-list
        (dolist (func functions-list)
          (insert (format "- %s\n" func)))
      (insert "- No functions found in this package\n"))

    ;; No need for org-list-indent-item-generic, as the list is already properly formatted

    ;; Return to the beginning of the buffer
    (goto-char (point-min))

    ;; Message to user
    (message "Created org-mode list of %d functions in package %s"
             (length functions-list) package-name)))


(defun list-manager-org-dash-list-to-latex-items ()
  "Convert org-mode dash list in current region or buffer to LaTeX \\item format."
  (interactive)
  (let ((start (if (use-region-p) (region-beginning) (point-min)))
        (end (if (use-region-p) (region-end) (point-max))))
    (save-excursion
      (goto-char start)
      (while (re-search-forward "^\\s-*- \\(.*\\)$" end t)
        (replace-match "    \\\\item \\1")
        (setq end (+ end (- (length "    \\\\item ") (length "- "))))))))


(defun list-manager-extract-unchecked-items (start end)
  "Extract unchecked checklist items from region between START and END.
Supports both org-mode style (- [ ] item) and LaTeX style (\\item [ ] item).
Results are displayed in a new buffer named *Unchecked Items*."
  (interactive "r")
  (let ((region-text (buffer-substring-no-properties start end))
        (unchecked-items '())
        ;; Pattern for org-mode: - [ ] or * [ ] (not [X] or [x])
        (org-pattern "^[ \t]*[-*+][ \t]+\\[[ ]\\][ \t]+\\(.+\\)$")
        ;; Pattern for LaTeX: \item [ ] (not [X] or [x])
        (latex-pattern "^[ \t]*\\\\item[ \t]+\\[[ ]\\][ \t]+\\(.+\\)$"))
    ;; Process each line in the region
    (with-temp-buffer
      (insert region-text)
      (goto-char (point-min))
      (while (not (eobp))
        (let ((line (buffer-substring-no-properties
                     (line-beginning-position)
                     (line-end-position))))
          ;; Check for org-mode style unchecked item
          (when (string-match org-pattern line)
            (push (match-string 1 line) unchecked-items))
          ;; Check for LaTeX style unchecked item
          (when (string-match latex-pattern line)
            (push (match-string 1 line) unchecked-items)))
        (forward-line 1)))
    ;; Reverse to maintain original order
    (setq unchecked-items (nreverse unchecked-items))
    ;; Display results in a new buffer
    (if unchecked-items
        (let ((output-buffer (get-buffer-create "*Unchecked Items*")))
          (with-current-buffer output-buffer
            (erase-buffer)
            (insert "#+TITLE: Unchecked Items\n")
            (insert "#+LaTeX_HEADER: \\usepackage[margin=0.5in]{geometry}\n\n")
            (insert "* Unchecked Items\n\n")
            (dolist (item unchecked-items)
              (insert (format "- [ ] %s\n" item)))
            (org-mode))
          (pop-to-buffer output-buffer)
          (message "Found %d unchecked item(s)" (length unchecked-items)))
      (message "No unchecked items found in region"))))


(defun list-manager-extract-unchecked-items-to-kill-ring (start end)
  "Extract unchecked checklist items from region and copy to kill ring.
This is a convenience variant that places results in the kill ring
instead of a new buffer."
  (interactive "r")
  (let ((region-text (buffer-substring-no-properties start end))
        (unchecked-items '())
        (org-pattern "^[ \t]*[-*+][ \t]+\\[[ ]\\][ \t]+\\(.+\\)$")
        (latex-pattern "^[ \t]*\\\\item[ \t]+\\[[ ]\\][ \t]+\\(.+\\)$"))
    (with-temp-buffer
      (insert region-text)
      (goto-char (point-min))
      (while (not (eobp))
        (let ((line (buffer-substring-no-properties
                     (line-beginning-position)
                     (line-end-position))))
          (when (string-match org-pattern line)
            (push (match-string 1 line) unchecked-items))
          (when (string-match latex-pattern line)
            (push (match-string 1 line) unchecked-items)))
        (forward-line 1)))
    (setq unchecked-items (nreverse unchecked-items))
    (if unchecked-items
        (let ((result (mapconcat (lambda (item)
                                   (format "- [ ] %s" item))
                                 unchecked-items
                                 "\n")))
          (kill-new result)
          (message "Copied %d unchecked item(s) to kill ring"
                   (length unchecked-items)))
      (message "No unchecked items found in region"))))


(defun list-manager-extract-unchecked-items (start end)
  "Extract unchecked checklist items from region between START and END.
Supports:
- Org-mode style: - [ ] item (unchecked) vs - [X] item (checked)
- LaTeX style 1: \\item [ ] item (unchecked) vs \\item [X] item (checked)
- LaTeX style 2: \\item item (unchecked) vs \\item[\\checked] item (checked)
Results are displayed in a new buffer named *Unchecked Items*."
  (interactive "r")
  (let ((region-text (buffer-substring-no-properties start end))
        (unchecked-items '())
        ;; Pattern for org-mode: - [ ] or * [ ] (not [X] or [x])
        (org-pattern "^[ \t]*[-*+][ \t]+\\[[ ]\\][ \t]+\\(.+\\)$")
        ;; Pattern for LaTeX style 1: \item [ ] (not [X] or [x])
        (latex-pattern-1 "^[ \t]*\\\\item[ \t]+\\[[ ]\\][ \t]+\\(.+\\)$")
        ;; Pattern for LaTeX style 2: \item without [\checked] marker
        ;; Matches \item followed by content, but NOT \item[\checked]
        (latex-pattern-2 "^[ \t]*\\\\item[ \t]+\\([^[\n].+\\)$"))
    ;; Process each line in the region
    (with-temp-buffer
      (insert region-text)
      (goto-char (point-min))
      (while (not (eobp))
        (let ((line (buffer-substring-no-properties
                     (line-beginning-position)
                     (line-end-position))))
          ;; Skip lines with \checked marker
          (unless (string-match "\\\\item\\[\\\\checked\\]" line)
            ;; Check for org-mode style unchecked item
            (when (string-match org-pattern line)
              (push (match-string 1 line) unchecked-items))
            ;; Check for LaTeX style 1 unchecked item
            (when (string-match latex-pattern-1 line)
              (push (match-string 1 line) unchecked-items))
            ;; Check for LaTeX style 2 unchecked item (plain \item)
            (when (string-match latex-pattern-2 line)
              (push (match-string 1 line) unchecked-items))))
        (forward-line 1)))
    ;; Reverse to maintain original order
    (setq unchecked-items (nreverse unchecked-items))
    ;; Display results in a new buffer
    (if unchecked-items
        (let ((output-buffer (get-buffer-create "*Unchecked Items*")))
          (with-current-buffer output-buffer
            (erase-buffer)
            (insert "#+TITLE: Unchecked Items\n")
            (insert "#+LaTeX_HEADER: \\usepackage[margin=0.5in]{geometry}\n\n")
            (insert "* Unchecked Items\n\n")
            (dolist (item unchecked-items)
              (insert (format "- [ ] %s\n" item)))
            (org-mode))
          (pop-to-buffer output-buffer)
          (message "Found %d unchecked item(s)" (length unchecked-items)))
      (message "No unchecked items found in region"))))


(defun list-manager-extract-unchecked-items-to-kill-ring (start end)
  "Extract unchecked checklist items from region and copy to kill ring.
Supports:
- Org-mode style: - [ ] item (unchecked) vs - [X] item (checked)
- LaTeX style 1: \\item [ ] item (unchecked) vs \\item [X] item (checked)
- LaTeX style 2: \\item item (unchecked) vs \\item[\\checked] item (checked)
Results are copied to the kill ring for pasting elsewhere."
  (interactive "r")
  (let ((region-text (buffer-substring-no-properties start end))
        (unchecked-items '())
        (org-pattern "^[ \t]*[-*+][ \t]+\\[[ ]\\][ \t]+\\(.+\\)$")
        (latex-pattern-1 "^[ \t]*\\\\item[ \t]+\\[[ ]\\][ \t]+\\(.+\\)$")
        (latex-pattern-2 "^[ \t]*\\\\item[ \t]+\\([^[\n].+\\)$"))
    (with-temp-buffer
      (insert region-text)
      (goto-char (point-min))
      (while (not (eobp))
        (let ((line (buffer-substring-no-properties
                     (line-beginning-position)
                     (line-end-position))))
          (unless (string-match "\\\\item\\[\\\\checked\\]" line)
            (when (string-match org-pattern line)
              (push (match-string 1 line) unchecked-items))
            (when (string-match latex-pattern-1 line)
              (push (match-string 1 line) unchecked-items))
            (when (string-match latex-pattern-2 line)
              (push (match-string 1 line) unchecked-items))))
        (forward-line 1)))
    (setq unchecked-items (nreverse unchecked-items))
    (if unchecked-items
        (let ((result (mapconcat (lambda (item)
                                   (format "- [ ] %s" item))
                                 unchecked-items
                                 "\n")))
          (kill-new result)
          (message "Copied %d unchecked item(s) to kill ring"
                   (length unchecked-items)))
      (message "No unchecked items found in region"))))


(defun list-manager-cut-unchecked-items (start end)
  "Cut unchecked checklist items from region between START and END.
Supports:
- Org-mode style: - [ ] item (unchecked) vs - [X] item (checked)
- LaTeX style 1: \\item [ ] item (unchecked) vs \\item [X] item (checked)
- LaTeX style 2: \\item item (unchecked) vs \\item[\\checked] item (checked)
Unchecked items are removed from the original buffer and displayed
in a new buffer named *Unchecked Items*."
  (interactive "r")
  (let ((unchecked-items '())
        (lines-to-delete '())
        (org-pattern "^[ \t]*[-*+][ \t]+\\[[ ]\\][ \t]+\\(.+\\)$")
        (latex-pattern-1 "^[ \t]*\\\\item[ \t]+\\[[ ]\\][ \t]+\\(.+\\)$")
        (latex-pattern-2 "^[ \t]*\\\\item[ \t]+\\([^[\n].+\\)$"))
    ;; First pass: identify unchecked items and their positions
    (save-excursion
      (goto-char start)
      (while (< (point) end)
        (let ((line-start (line-beginning-position))
              (line-end (line-end-position))
              (line (buffer-substring-no-properties
                     (line-beginning-position)
                     (line-end-position))))
          (unless (string-match "\\\\item\\[\\\\checked\\]" line)
            (let ((item-text nil))
              ;; Check for org-mode style unchecked item
              (when (string-match org-pattern line)
                (setq item-text (match-string 1 line)))
              ;; Check for LaTeX style 1 unchecked item
              (when (string-match latex-pattern-1 line)
                (setq item-text (match-string 1 line)))
              ;; Check for LaTeX style 2 unchecked item (plain \item)
              (when (string-match latex-pattern-2 line)
                (setq item-text (match-string 1 line)))
              ;; If we found an unchecked item, record it
              (when item-text
                (push item-text unchecked-items)
                ;; Store line boundaries (include newline if present)
                (push (cons line-start
                            (min (1+ line-end) (point-max)))
                      lines-to-delete)))))
        (forward-line 1)))
    ;; Reverse to maintain original order for display
    (setq unchecked-items (nreverse unchecked-items))
    ;; Delete lines in reverse order to preserve positions
    (when lines-to-delete
      (dolist (line-bounds lines-to-delete)
        (delete-region (car line-bounds) (cdr line-bounds))))
    ;; Display results in a new buffer
    (if unchecked-items
        (let ((output-buffer (get-buffer-create "*Unchecked Items*")))
          (with-current-buffer output-buffer
            (erase-buffer)
            (insert "#+TITLE: Unchecked Items\n")
            (insert "#+LaTeX_HEADER: \\usepackage[margin=0.5in]{geometry}\n\n")
            (insert "* Unchecked Items\n\n")
            (dolist (item unchecked-items)
              (insert (format "- [ ] %s\n" item)))
            (org-mode))
          (pop-to-buffer output-buffer)
          (message "Cut %d unchecked item(s)" (length unchecked-items)))
      (message "No unchecked items found in region"))))


(defun list-manager-cut-unchecked-items-to-kill-ring (start end)
  "Cut unchecked checklist items from region and copy to kill ring as LaTeX items.
Supports:
- Org-mode style: - [ ] item (unchecked) vs - [X] item (checked)
- LaTeX style 1: \\item [ ] item (unchecked) vs \\item [X] item (checked)
- LaTeX style 2: \\item item (unchecked) vs \\item[\\checked] item (checked)
Unchecked items are removed from the original buffer and placed
in the kill ring as LaTeX \\item entries for pasting elsewhere."
  (interactive "r")
  (let ((unchecked-items '())
        (lines-to-delete '())
        (org-pattern "^[ \t]*[-*+][ \t]+\\[[ ]\\][ \t]+\\(.+\\)$")
        (latex-pattern-1 "^[ \t]*\\\\item[ \t]+\\[[ ]\\][ \t]+\\(.+\\)$")
        (latex-pattern-2 "^[ \t]*\\\\item[ \t]+\\([^[\n].+\\)$"))
    ;; First pass: identify unchecked items and their positions
    (save-excursion
      (goto-char start)
      (while (< (point) end)
        (let ((line-start (line-beginning-position))
              (line-end (line-end-position))
              (line (buffer-substring-no-properties
                     (line-beginning-position)
                     (line-end-position))))
          (unless (string-match "\\\\item\\[\\\\checked\\]" line)
            (let ((item-text nil))
              (when (string-match org-pattern line)
                (setq item-text (match-string 1 line)))
              (when (string-match latex-pattern-1 line)
                (setq item-text (match-string 1 line)))
              (when (string-match latex-pattern-2 line)
                (setq item-text (match-string 1 line)))
              (when item-text
                (push item-text unchecked-items)
                (push (cons line-start
                            (min (1+ line-end) (point-max)))
                      lines-to-delete)))))
        (forward-line 1)))
    ;; Reverse to maintain original order
    (setq unchecked-items (nreverse unchecked-items))
    ;; Delete lines in reverse order to preserve positions
    (when lines-to-delete
      (dolist (line-bounds lines-to-delete)
        (delete-region (car line-bounds) (cdr line-bounds))))
    ;; Copy to kill ring as LaTeX \item entries
    (if unchecked-items
        (let ((result (mapconcat (lambda (item)
                                   (format "\\item %s" item))
                                 unchecked-items
                                 "\n")))
          (kill-new result)
          (message "Cut %d unchecked item(s) to kill ring as LaTeX items"
                   (length unchecked-items)))
      (message "No unchecked items found in region"))))


(defun list-manager-repair-stripped-item-list (beg end)
  "Rebuild a LaTeX \\item list in the region BEG..END that was flattened.

Some pipelines strip a group of list items of their leading backslashes
and of the newlines between them, collapsing

    \\item Do this.
    \\item Do that.

into a single run-together line in which every marker survives only as
the bare word \"item\":

    item Do this. item Do that.

This command restores each marker to \\item and puts every item on its own
line, adding the newline at the end of each item.  A bare \"item\" counts
as a marker only when it stands as a whole word at the start of the text
or after whitespace, so an \"item\" that already carries its backslash is
left untouched (the command is safe to run twice) and words such as
\"itemize\" or \"systems\" are never split.

With an active region, operate on it; otherwise operate on the current
paragraph."
  (interactive
   (if (use-region-p)
       (list (region-beginning) (region-end))
     (list (save-excursion (start-of-paragraph-text) (point))
           (save-excursion (end-of-paragraph-text) (point)))))
  (let* ((text (buffer-substring-no-properties beg end))
         (repaired
          (with-temp-buffer
            (insert text)
            (goto-char (point-min))
            (while (re-search-forward "\\(?:\\`\\|[ \t\n]+\\)item\\b[ \t]*" nil t)
              (replace-match "\n\\item " t t))
            (string-trim (buffer-string)))))
    (delete-region beg end)
    (insert repaired)))

(defun list-manager-lines-to-latex-items (start end &optional arg)
  "Convert each line in region between START and END to a LaTeX \\item.
Empty lines are skipped by default.
With prefix ARG (C-u), wrap the items in an itemize environment."
  (interactive "r\nP")
  (let ((lines (split-string
                (buffer-substring-no-properties start end)
                "\n" t "[ \t]+"))  ; Split and trim whitespace
        (result '()))
    ;; Convert each line to \item
    (dolist (line lines)
      (unless (string-empty-p line)
        (push (format "  \\item %s" line) result)))
    ;; Reverse to maintain original order
    (setq result (nreverse result))
    ;; Build final string
    (let ((items-text (string-join result "\n")))
      (when arg
        (setq items-text
              (concat "\\begin{itemize}\n"
                      items-text
                      "\n\\end{itemize}")))
      ;; Replace region with converted text
      (delete-region start end)
      (insert items-text)
      (message "Converted %d line(s) to \\item entries"
               (length result)))))


(defun list-manager-convert-org-checklist-to-dash-list (begin end)
  "Convert org-mode checklist items to simple dash list items in the selected region.
BEGIN and END define the boundaries of the region. Generated with Claude 3.7 Sonnet May 7, 2025."
  (interactive "r")  ; "r" means the function takes region as input
  (save-excursion
    (save-restriction
      (narrow-to-region begin end)  ; Narrow to the selected region
      (goto-char (point-min))
      (while (re-search-forward "^\\(\\s-*\\)- \\[[ X]\\] " nil t)
        (replace-match "\\1- " t)))))


(defun list-manager-convert-org-checklist-to-latex-items (begin end)
  "Convert org-mode checklist items to LaTeX \\item entries in the selected region.
BEGIN and END define the boundaries of the region.
Handles both checked (- [X]) and unchecked (- [ ]) items.
The checkbox notation is removed and the item text is preserved.

Example input:
  - [ ] First unchecked item
  - [X] Second checked item
  - [ ] Third unchecked item

Example output:
  \\item First unchecked item
  \\item Second checked item
  \\item Third unchecked item"
  (interactive "r")
  (save-excursion
    (save-restriction
      (narrow-to-region begin end)
      (goto-char (point-min))
      ;; Match: optional whitespace, dash, space, checkbox, space, then content
      (while (re-search-forward "^\\(\\s-*\\)- \\[[ Xx]\\] \\(.*\\)$" nil t)
        (replace-match "\\1\\\\item \\2" t)))))


;;; ============================================================
;;; LaTeX to Org Conversions
;;; ============================================================

(defun list-manager-convert-latex-items-to-dash-list (begin end)
  "Convert LaTeX \\item entries to org-mode dash list items in the selected region.
BEGIN and END define the boundaries of the region.

Example input:
  \\item First item
  \\item Second item
  \\item Third item

Example output:
  - First item
  - Second item
  - Third item"
  (interactive "r")
  (save-excursion
    (save-restriction
      (narrow-to-region begin end)
      (goto-char (point-min))
      ;; Match: optional whitespace, \item, optional whitespace, then content
      (while (re-search-forward "^\\(\\s-*\\)\\\\item\\s-+\\(.*\\)$" nil t)
        (replace-match "\\1- \\2" t)))))


(defun list-manager-convert-latex-items-to-org-checklist (begin end)
  "Convert LaTeX \\item entries to org-mode checklist items in the selected region.
BEGIN and END define the boundaries of the region.
All items are converted to unchecked checkboxes.

Example input:
  \\item First item
  \\item Second item
  \\item Third item

Example output:
  - [ ] First item
  - [ ] Second item
  - [ ] Third item"
  (interactive "r")
  (save-excursion
    (save-restriction
      (narrow-to-region begin end)
      (goto-char (point-min))
      ;; Match: optional whitespace, \item, optional whitespace, then content
      (while (re-search-forward "^\\(\\s-*\\)\\\\item\\s-+\\(.*\\)$" nil t)
        (replace-match "\\1- [ ] \\2" t)))))


;;; ============================================================
;;; Org Dash List to TODO Headline Conversions
;;; ============================================================

(defun list-manager-convert-dash-list-to-todo-headlines (begin end)
  "Convert org-mode dash list items to TODO headlines in the selected region.
BEGIN and END define the boundaries of the region.
Each dash item becomes a level-1 TODO headline.

Example input:
  - First item
  - Second item
  - Third item

Example output:
  * TODO First item
  * TODO Second item
  * TODO Third item"
  (interactive "r")
  (save-excursion
    (save-restriction
      (narrow-to-region begin end)
      (goto-char (point-min))
      ;; Match: optional whitespace, dash, space, then content
      (while (re-search-forward "^\\s-*-\\s-+\\(.*\\)$" nil t)
        (replace-match "* TODO \\1" t)))))


;;; ============================================================
;;; Org Checklist to TODO Headline Conversions
;;; ============================================================

(defun list-manager-convert-checklist-to-todo-headlines (begin end)
  "Convert org-mode checklist items to TODO headlines in the selected region.
BEGIN and END define the boundaries of the region.
Unchecked items (- [ ]) become TODO headlines.
Checked items (- [X]) become DONE headlines.

Example input:
  - [ ] First unchecked item
  - [X] Second checked item
  - [ ] Third unchecked item

Example output:
  * TODO First unchecked item
  * DONE Second checked item
  * TODO Third unchecked item"
  (interactive "r")
  (save-excursion
    (save-restriction
      (narrow-to-region begin end)
      (goto-char (point-min))
      ;; First pass: convert checked items to DONE
      (while (re-search-forward "^\\s-*-\\s-+\\[[Xx]\\]\\s-+\\(.*\\)$" nil t)
        (replace-match "* DONE \\1" t))
      (goto-char (point-min))
      ;; Second pass: convert unchecked items to TODO
      (while (re-search-forward "^\\s-*-\\s-+\\[ \\]\\s-+\\(.*\\)$" nil t)
        (replace-match "* TODO \\1" t)))))


;;; ============================================================
;;; TODO Headline to Org List Conversions
;;; ============================================================

(defun list-manager-convert-todo-headlines-to-dash-list (begin end)
  "Convert org-mode TODO headlines to dash list items in the selected region.
BEGIN and END define the boundaries of the region.
Removes the TODO/DONE keywords and headline stars.

Example input:
  * TODO First item
  * DONE Second item
  * TODO Third item

Example output:
  - First item
  - Second item
  - Third item"
  (interactive "r")
  (save-excursion
    (save-restriction
      (narrow-to-region begin end)
      (goto-char (point-min))
      ;; Match: stars, space, TODO keyword, space, then content
      ;; Handles TODO, DONE, CANCELLED, SOMEDAY, etc.
      (while (re-search-forward "^\\*+\\s-+\\(TODO\\|DONE\\|CANCELLED\\|SOMEDAY\\|WAITING\\|NEXT\\)\\s-+\\(.*\\)$" nil t)
        (replace-match "- \\2" t)))))


(defun list-manager-convert-todo-headlines-to-checklist (begin end)
  "Convert org-mode TODO headlines to checklist items in the selected region.
BEGIN and END define the boundaries of the region.
TODO/WAITING/NEXT headlines become unchecked items.
DONE/CANCELLED headlines become checked items.

Example input:
  * TODO First item
  * DONE Second item
  * TODO Third item

Example output:
  - [ ] First item
  - [X] Second item
  - [ ] Third item"
  (interactive "r")
  (save-excursion
    (save-restriction
      (narrow-to-region begin end)
      (goto-char (point-min))
      ;; First pass: convert DONE/CANCELLED to checked items
      (while (re-search-forward "^\\*+\\s-+\\(DONE\\|CANCELLED\\)\\s-+\\(.*\\)$" nil t)
        (replace-match "- [X] \\2" t))
      (goto-char (point-min))
      ;; Second pass: convert TODO/WAITING/NEXT/SOMEDAY to unchecked items
      (while (re-search-forward "^\\*+\\s-+\\(TODO\\|WAITING\\|NEXT\\|SOMEDAY\\)\\s-+\\(.*\\)$" nil t)
        (replace-match "- [ ] \\2" t)))))


;;; ============================================================
;;; TODO Headline to LaTeX Conversions
;;; ============================================================

(defun list-manager-convert-todo-headlines-to-latex-items (begin end)
  "Convert org-mode TODO headlines to LaTeX \\item entries in the selected region.
BEGIN and END define the boundaries of the region.
Removes the TODO/DONE keywords and headline stars.

Example input:
  * TODO First item
  * DONE Second item
  * TODO Third item

Example output:
  \\item First item
  \\item Second item
  \\item Third item"
  (interactive "r")
  (save-excursion
    (save-restriction
      (narrow-to-region begin end)
      (goto-char (point-min))
      ;; Match: stars, space, TODO keyword, space, then content
      (while (re-search-forward "^\\*+\\s-+\\(TODO\\|DONE\\|CANCELLED\\|SOMEDAY\\|WAITING\\|NEXT\\)\\s-+\\(.*\\)$" nil t)
        (replace-match "\\\\item \\2" t)))))


;;; ============================================================
;;; LaTeX to TODO Headline Conversions
;;; ============================================================

(defun list-manager-convert-latex-items-to-todo-headlines (begin end)
  "Convert LaTeX \\item entries to org-mode TODO headlines in the selected region.
BEGIN and END define the boundaries of the region.
All items become level-1 TODO headlines.

Example input:
  \\item First item
  \\item Second item
  \\item Third item

Example output:
  * TODO First item
  * TODO Second item
  * TODO Third item"
  (interactive "r")
  (save-excursion
    (save-restriction
      (narrow-to-region begin end)
      (goto-char (point-min))
      ;; Match: optional whitespace, \item, optional whitespace, then content
      (while (re-search-forward "^\\s-*\\\\item\\s-+\\(.*\\)$" nil t)
        (replace-match "* TODO \\1" t)))))


        (defun mooerslab-org-add-periods-to-list-items (begin end)
          "Add periods to the end of all items in the selected org-mode list if missing.
        It operates only in the selected region between BEGIN and END.
        Preserves both checked and unchecked checkboxes and the initial dash.
        Suitable for preparing bullet lists for slides."
          (interactive "r")
          (save-excursion
            (save-restriction
              (narrow-to-region begin end)
              (goto-char (point-min))
              (while (re-search-forward "^\\([ \t]*-[ \t]+\\(?:\\[[ X]\\][ \t]+\\)?\\)\\([^.\n]+\\)\\([^.]\n\\|$\\)" nil t)
                (replace-match "\\1\\2." nil nil)))))


;;; add-periods-to-list
(defun list-manager-org-or-latex-add-periods-to-list ()
  "Add a period to the end of each line in the current list if missing.
Designed to work in both org and latex files.
This is a massive problem with lists in slideshows.
The absence of periods will upset some audience members.
Works with:
- org-mode lists (-, *, numbers)
- org-mode checklists (- [ ], * [ ])
https://github.com/cursorless-everywhere/emacs-cursorless/issues- LaTeX \\item lists
- LaTeX \\item checklists (\\item [ ])

Usage: Place cursor anywhere in list. Enter M-x org-or-latex-add-periods-to-list or C-c p.
Developed with the help of Claude 3.5 Sonnet."
  (interactive)
  (save-excursion
    (let ((list-end (save-excursion
                      (end-of-list)
                      (point))))
      (beginning-of-list)
      (while (< (point) list-end)
        (end-of-line)
        (when (and (not (looking-back "[.!?]\\|[.!?]\"\\|[.!?]''" (line-beginning-position)))
                   (not (looking-at-p "^\\s-*$")) ; Skip empty lines
                   (save-excursion
                     (beginning-of-line)
                     (looking-at-p "^\\s-*\\([-*]\\(?: \\[[ X-]\\]\\)?\\|[0-9]+[.)]\\|\\\\item\\(?: \\[[ X-]\\]\\)?\\)")))
          (insert "."))
        (forward-line)))))
(global-set-key (kbd "C-c p") 'list-manager-org-or-latex-add-periods-to-list)


(defun list-manager-beginning-of-list ()
  "Move to beginning of the current list.
Handles org-mode lists, checklists, and LaTeX lists."
  (while (and (not (bobp))
              (save-excursion
                (beginning-of-line)
                (looking-at-p "^\\s-*\\([-*]\\(?: \\[[ X-]\\]\\)?\\|[0-9]+[.)]\\|\\\\item\\(?: \\[[ X-]\\]\\)?\\)")))
    (forward-line -1))
  (forward-line 1))


(defun list-manager-end-of-list ()
  "Move to end of the current list.
Handles org-mode lists, checklists, and LaTeX lists."
  (while (and (not (eobp))
              (save-excursion
                (beginning-of-line)
                (looking-at-p "^\\s-*\\([-*]\\(?: \\[[ X-]\\]\\)?\\|[0-9]+[.)]\\|\\\\item\\(?: \\[[ X-]\\]\\)?\\)")))
    (forward-line 1)))


;;; carry-forward-todos
;; When planning daily in org, moving the unfinished items forward manually is a pain.
;; The manual cutting and pasting for five categories per day or week can take a long time.
;; I know that org-agenda can do something like this.
;; I want more control.
(defun list-manager-carry-forward-todos ()
"Carry forward undone TODOs and unchecked items to Next Week while preserving categories."
(interactive)
(save-excursion
  (let ((todos-to-move '())
        (current-level (org-outline-level))
        (category-order '()))

    ;; Store the current week's position
    (let ((current-week-pos (point)))

      ;; First, collect category order
      (org-map-entries
       (lambda ()
         (when (= (org-outline-level) (1+ current-level))
           (push (org-get-heading t t t t) category-order)))
       t 'tree)
      (setq category-order (reverse category-order))

      ;; Collect TODOs and checklist items from each category
      (org-map-entries
       (lambda ()
         (when (= (org-outline-level) (1+ current-level))
           (let ((category (org-get-heading t t t t))
                 (end-of-subtree (save-excursion
                                 (org-end-of-subtree)
                                 (point))))
             ;; Collect TODOs
             (save-excursion
               (while (re-search-forward org-todo-regexp end-of-subtree t)
                 (let ((todo-state (match-string 1)))
                   (when (and todo-state
                            (not (member todo-state '("DONE" "CANCELLED" "SOMEDAY"))))
                     (push (cons category
                               (concat "   "
                                      (buffer-substring-no-properties
                                       (line-beginning-position)
                                       (1+ (line-end-position)))))
                           todos-to-move)))))
             ;; Collect unchecked boxes
             (save-excursion
               (goto-char (line-beginning-position))
               (while (re-search-forward "^\\([ \t]*\\)\\([-+*]\\) \\[ \\]" end-of-subtree t)
                 (let ((indent (match-string 1))
                       (bullet (match-string 2)))
                   (push (cons category
                             (concat "   " indent bullet " [ ] "
                                    (buffer-substring-no-properties
                                     (match-end 0)
                                     (line-end-position))
                                    "\n"))
                         todos-to-move)))))))
       t 'tree)

      ;; Find or create Next Week heading
      (goto-char (point-min))
      (let ((next-week-marker (concat "^\\*\\{" (number-to-string current-level) "\\} Next Week")))
        (unless (re-search-forward next-week-marker nil t)
          (goto-char (point-max))
          (insert "\n" (make-string current-level ?*) " Next Week\n")))

      ;; Insert collected items under appropriate categories
      (dolist (category category-order)
        (when (cl-remove-if-not
               (lambda (x) (string= (car x) category))
               todos-to-move)
          ;; Create or find category heading
          (let ((category-marker (concat "^\\*\\{" (number-to-string (1+ current-level)) "\\} "
                                       (regexp-quote category))))
            (unless (re-search-forward category-marker nil t)
              (insert "\n" (make-string (1+ current-level) ?*) " " category "\n"))
            ;; Insert todos for this category
            (dolist (todo (reverse (cl-remove-if-not
                                  (lambda (x) (string= (car x) category))
                                  todos-to-move)))
              (insert (cdr todo))))))

      ;; Go back and mark original items as done
      (goto-char current-week-pos)
      (org-map-entries
       (lambda ()
         (when (org-entry-is-todo-p)
           (let ((todo-state (org-get-todo-state)))
             (when (and todo-state
                       (not (member todo-state '("DONE" "CANCELED"))))
               (org-todo "DONE")))))
       t 'tree)

      ;; Mark all checkboxes as done
      (goto-char current-week-pos)
      (org-map-entries
       (lambda ()
         (save-excursion
           (while (re-search-forward "^[ \t]*[-+*] \\[ \\]"
                                   (save-excursion (outline-next-heading) (point))
                                   t)
             (replace-match "\\1[X]" nil nil))))
       t 'tree)))))
(global-set-key (kbd "C-c f") 'list-manager-carry-forward-todos)


;;; lines in region to list in org
(defun list-manager-lines-in-region-to-org-list (marker)
  "Convert lines in region to an org list with specified MARKER (-, +, *)."
  (interactive "sMarker (e.g. -, +, *): ")
  (if (region-active-p)
      (let ((begin (region-beginning))
            (end (region-end))
            (marker (concat marker " ")))
        (save-excursion
          (goto-char begin)
          (beginning-of-line)
          (while (and (<= (point) end)
                      (not (eobp)))
            (insert marker)
            ;; Adjust the end position as we add text
            (setq end (+ end (length marker)))
            (forward-line 1))))
    (message "No region selected")))


;;; region-to-itemized-list-in-org
(defun list-manager-org-region-to-itemized-list ()
  "Convert the lines in a selected region into an itemized list."
  (interactive)
  (let ((start (region-beginning))
        (end (region-end))
        (lines ())
        (str ""))
    (save-excursion
      (goto-char start)
      (while (< (point) end)
        (setq lines (cons (buffer-substring (point) (progn (end-of-line) (point))) lines)))
    (doloist (line lines)
      (setq str (concat str (format "- %s\n" line))))
    (delete-region start end)
    (insert str))))
(global-set-key (kbd "C-c l") 'region-to-itemized-list)


(defun list-manager-remove-blank-lines-in-region (start end)
  "Remove all blank lines in the region between START and END."
  (interactive "r")
  (save-excursion
    (save-restriction
      (narrow-to-region start end)
      (goto-char (point-min))
      (flush-lines "^$"))))


(defun list-manager-org-convert-unordered-to-ordered-list (start end)
  "Convert unnumbered list items to numbered list items in the marked region."
  (interactive "r")
  (save-excursion
    (save-restriction
      (narrow-to-region start end)
      (goto-char (point-min))
      (let ((counter 1))
        (while (re-search-forward "^\\([ \t]*\\)\\(-\\|+\\|\\*\\)\\([ \t]+\\)" nil t)
          (replace-match (format "\\1%d.\\3" counter) t)
          (setq counter (1+ counter)))))))

(global-set-key (kbd "C-c C-x n") 'list-manager-org-convert-unordered-to-ordered-list)


(defun list-manager-org-convert-list-in-region-to-checkboxes (start end)
  "Convert a dash/hyphen bullet list to org-mode checkboxes in region from START to END."
  (interactive "r")
  (save-excursion
    (narrow-to-region start end)
    (goto-char (point-min))
    (while (re-search-forward "^\\s-*-\\s-+" nil t)
      (replace-match "- [ ] " t nil))
    (widen)))


(defun list-manager-org-convert-checkboxes-in-region-to-list (start end)
  "Convert org-mode checkboxes to a regular dash/hyphen bullet list in region from START to END."
  (interactive "r")
  (save-excursion
    (narrow-to-region start end)
    (goto-char (point-min))
    ;; Match checkbox patterns like "- [ ]", "- [X]", "- [x]" with any whitespace
    (while (re-search-forward "^\\(\\s-*\\)- \\[[xX ]\\]\\s-+" nil t)
      (let ((indent (match-string 1)))
        (replace-match (concat indent "- ") t nil)))
    (widen)))


(defun list-manager-lines-to-latex-items-unchecked (start end &optional arg)
  "Convert each line in region to a LaTeX \\item with unchecked box.
Uses the format: \\item text (for use with \\checked/\\unchecked system).
Empty lines are skipped.
With prefix ARG (C-u), wrap in itemize environment with label=\\unchecked."
  (interactive "r\nP")
  (let ((lines (split-string
                (buffer-substring-no-properties start end)
                "\n" t "[ \t]+"))
        (result '()))
    (dolist (line lines)
      (unless (string-empty-p line)
        (push (format "  \\item %s" line) result)))
    (setq result (nreverse result))
    (let ((items-text (string-join result "\n")))
      (when arg
        (setq items-text
              (concat "\\begin{itemize}[label=\\unchecked]\n"
                      items-text
                      "\n\\end{itemize}")))
      (delete-region start end)
      (insert items-text)
      (message "Converted %d line(s) to unchecked \\item entries"
               (length result)))))


(defun mooerslab-org-convert-lines-to-org-checklist (beg end)
  "Convert lines in region to org-mode checklist items.
Preserves existing checkboxes, indentation, and empty lines.
If no region is active, operate on the current buffer."
  (interactive (if (use-region-p)
                   (list (region-beginning) (region-end))
                 (list (point-min) (point-max))))

  (let ((lines (split-string (buffer-substring-no-properties beg end) "\n"))
        (result ""))

    (dolist (line lines)
      (cond
       ;; Empty line - keep as is
       ((string-match-p "^\\s-*$" line)
        (setq result (concat result line "\n")))

       ;; Already has a proper checkbox
       ((string-match-p "^\\(\\s-*\\)-\\s-*\\[[ xX-]\\]\\s-+" line)
        (setq result (concat result line "\n")))

       ;; Already a list item (dash) without checkbox
       ((string-match "^\\(\\s-*\\)-\\s-+\\(.*\\)$" line)
        (let ((indent (match-string 1 line))
              (content (match-string 2 line)))
          (setq result (concat result indent "- [ ] " content "\n"))))

       ;; Regular line with possible indentation
       ((string-match "^\\(\\s-*\\)\\(.*\\)$" line)
        (let ((indent (match-string 1 line))
              (content (match-string 2 line)))
          (when (not (string-empty-p content))
            (setq result (concat result indent "- [ ] " content "\n")))))))

    (delete-region beg end)
    (insert result)))


(defun mooerslab-string-to-org-checklist (text)
  "Convert string TEXT to org-mode checklist format.
Preserves existing checkboxes, indentation, and empty lines."
  (with-temp-buffer
    (insert text)
    (convert-to-org-checklist (point-min) (point-max))
    (buffer-string)))


(defun mooerslab-org-checklist-from-kill-ring ()
  "Convert the latest kill-ring entry to org checklist format and put it back in the kill ring."
  (interactive)
  (when kill-ring
    (let ((converted (string-to-org-checklist (car kill-ring))))
      (kill-new converted)
      (message "Converted text to org checklist and placed in kill ring"))))


(defun list-manager-remove-blank-lines-in-region (start end)
  "Remove all blank lines in region between START and END.
Blank lines include empty lines and lines containing only whitespace."
  (interactive "r")
  (let ((lines (split-string
                (buffer-substring-no-properties start end)
                "\n"))
        (non-blank-lines '())
        (blank-count 0))
    ;; Filter out blank lines
    (dolist (line lines)
      (if (string-match-p "^[ \t]*$" line)
          (setq blank-count (1+ blank-count))
        (push line non-blank-lines)))
    ;; Reverse to maintain original order
    (setq non-blank-lines (nreverse non-blank-lines))
    ;; Replace region with non-blank lines
    (delete-region start end)
    (insert (string-join non-blank-lines "\n"))
    (message "Removed %d blank line(s)" blank-count)))


(defun list-manager-add-backslashes (&optional start end)
  "Add backslashes in front of LaTeX keywords that 750words strips.

When called with an active region, operate only on that region.
Otherwise, operate on the entire buffer.

Keywords restored: chapter, section, subsection, subsubsection,
include, begin, end, index, label, and item."
  (interactive
   (if (use-region-p)
       (list (region-beginning) (region-end))
     (list (point-min) (point-max))))
  (let ((latex-keywords '("chapter"
                          "section"
                          "subsection"
                          "subsubsection"
                          "include"
                          "begin"
                          "end"
                          "index"
                          "label"
                          "item"))
        (count 0))
    (save-excursion
      (dolist (keyword latex-keywords)
        ;; Match keyword at word boundary, not already preceded by backslash
        (let ((pattern (concat "\\(?:^\\|[^\\\\]\\)\\<\\(" keyword "\\)\\>")))
          (goto-char start)
          (while (re-search-forward pattern end t)
            ;; Check if the character before the match is not a backslash
            (let ((match-start (match-beginning 1)))
              (goto-char match-start)
              (when (or (= match-start (point-min))
                        (not (eq (char-before) ?\\)))
                (insert "\\")
                (setq end (1+ end))  ; Adjust end position
                (setq count (1+ count))))))))
    (message "Added %d backslashes to LaTeX keywords." count)))


(defun list-manager-restore-newlines (&optional start end)
  "Restore newlines before LaTeX list keywords that 750words strips.

When called with an active region, operate only on that region.
Otherwise, operate on the entire buffer.

Inserts a newline before: \\item, \\begin, and \\end when they
are not already at the beginning of a line."
  (interactive
   (if (use-region-p)
       (list (region-beginning) (region-end))
     (list (point-min) (point-max))))
  (let ((keywords '("\\\\item" "\\\\begin" "\\\\end"))
        (count 0))
    (save-excursion
      (dolist (keyword keywords)
        (goto-char start)
        (while (re-search-forward keyword end t)
          (goto-char (match-beginning 0))
          ;; Check if not already at beginning of line (ignoring whitespace)
          (unless (save-excursion
                    (skip-chars-backward " \t")
                    (bolp))
            ;; Insert newline before the keyword
            (insert "\n")
            (setq end (1+ end))  ; Adjust end position
            (setq count (1+ count)))
          ;; Move past the match to avoid infinite loop
          (goto-char (1+ (point))))))
    (message "Restored %d newlines before LaTeX list keywords." count)))


;;; region-to-itemized-in-latex
(defun list-manager-latex-region-to-itemized-list (start end)
  "Converts the region between START and END to an itemized list in LaTeX"
  (interactive "r")  ; Use "r" to read region bounds automatically
  (let* ((text (buffer-substring-no-properties start end))
         (lines (split-string text "\n"))
         (latex-string "\\begin{itemize}\n"))
    (dolist (line lines)
      (if (string-empty-p (string-trim line))
          (setq latex-string (concat latex-string "\\item\n"))
        (setq latex-string (concat latex-string "\\item " (string-trim line) "\n"))))
    (setq latex-string (concat latex-string "\\end{itemize}\n"))
    (delete-region start end)
    (goto-char start)
    (insert latex-string)))


;;; region of csv list to latex
(defun list-manager-latex-convert-csv-to-itemized-list (start end)
  "Convert a comma-separated list in the selected region to a LaTeX itemized list."
  (interactive "r")
  (let ((csv-text (buffer-substring-no-properties start end)))
    (delete-region start end)
    (insert "\\begin{itemize}\n")
    (dolist (item (split-string csv-text ","))
      (insert (format "  \\item %s\n" (string-trim item))))
    (insert "\\end{itemize}\n")))



(defun list-manager-restore-latex-formatting (&optional start end)
  "Restore both backslashes and newlines stripped by 750words.

Runs `list-add-backslashes' followed by `list-restore-newlines'
on the buffer or active region."
  (interactive
   (if (use-region-p)
       (list (region-beginning) (region-end))
     (list (point-min) (point-max))))
  (list-add-backslashes start end)
  ;; Recalculate end because backslashes were added
  (let ((new-end (if (use-region-p) (region-end) (point-max))))
    (list-restore-newlines start new-end))
  (message "Restored LaTeX formatting (backslashes and newlines)."))


;;; Split long lines into one line per sentence.
;% The function is priceless when working with transripts from whisper-file.
(defun list-manager-split-line-by-sentences (start end)
  "Move each sentence in the region to its own line, ignoring common titles and abbreviations."
  (interactive "r")
  (save-excursion
    (goto-char start)
    ;; First, temporarily mark abbreviations
    (let ((case-fold-search nil))  ; make search case-sensitive
      ;; Mark abbreviations with a special character (¶)
      (goto-char start)
      (while (re-search-forward "\\(Dr\\|Drs\\|Mr\\|Mrs\\|Ph\\.D\\|M\\.S\\)\\." end t)
        (replace-match "\\1¶"))

      ;; Now split on actual sentence endings
      (goto-char start)
      (while (re-search-forward "\\([.!?]\\)\\s-+" end t)
        (replace-match "\\1\n"))

      ;; Restore the original periods in abbreviations
      (goto-char start)
      (while (re-search-forward "¶" end t)
        (replace-match ".")))))


(define-prefix-command 'list-manager-map)
(global-set-key (kbd "C-c x") 'list-manager-map)



;; Unchecked item operations
(define-key list-manager-map (kbd "u") 'list-manager-extract-unchecked-items)
(define-key list-manager-map (kbd "k") 'list-manager-extract-unchecked-items-to-kill-ring)
(define-key list-manager-map (kbd "c") 'list-manager-cut-unchecked-items)
(define-key list-manager-map (kbd "x") 'list-manager-cut-unchecked-items-to-kill-ring)

;; Checklist conversions
(define-key list-manager-map (kbd "-") 'list-manager-convert-org-checklist-to-dash-list)
(define-key list-manager-map (kbd "\\") 'list-manager-convert-org-checklist-to-latex-items)
(define-key list-manager-map (kbd "[") 'list-manager-org-convert-list-in-region-to-checkboxes)
(define-key list-manager-map (kbd "]") 'list-manager-org-convert-checkboxes-in-region-to-list)

;; Org-mode list operations
(define-key list-manager-map (kbd "m") 'list-manager-lines-in-region-to-org-list)
(define-key list-manager-map (kbd "o") 'list-manager-org-region-to-itemized-list)
(define-key list-manager-map (kbd "#") 'list-manager-org-convert-unordered-to-ordered-list)
(define-key list-manager-map (kbd "p") 'list-manager-org-or-latex-add-periods-to-list)
(define-key list-manager-map (kbd "f") 'list-manager-carry-forward-todos)

;; Lines to LaTeX item conversions
(define-key list-manager-map (kbd "l") 'list-manager-lines-to-latex-items)
(define-key list-manager-map (kbd "U") 'list-manager-lines-to-latex-items-unchecked)
(define-key list-manager-map (kbd "N") 'list-manager-numbered-list-to-latex-items)
(define-key list-manager-map (kbd "d") 'list-manager-dash-list-to-latex-items)

;; Org dash list to LaTeX conversions
(define-key list-manager-map (kbd "D") 'list-manager-org-dash-list-to-latex-items)
(define-key list-manager-map (kbd "e") 'list-manager-org-dash-list-to-latex-items-enhanced)
(define-key list-manager-map (kbd "i") 'list-manager-org-dash-list-to-latex-itemize)
(define-key list-manager-map (kbd "C") 'list-manager-org-dash-list-to-custom-latex)

;; LaTeX to Org conversions (NEW)
(define-key list-manager-map (kbd "L -") 'list-manager-convert-latex-items-to-dash-list)
(define-key list-manager-map (kbd "L [") 'list-manager-convert-latex-items-to-org-checklist)
(define-key list-manager-map (kbd "L t") 'list-manager-convert-latex-items-to-todo-headlines)

;; TODO headline conversions (NEW)
(define-key list-manager-map (kbd "t -") 'list-manager-convert-todo-headlines-to-dash-list)
(define-key list-manager-map (kbd "t [") 'list-manager-convert-todo-headlines-to-checklist)
(define-key list-manager-map (kbd "t l") 'list-manager-convert-todo-headlines-to-latex-items)

;; To TODO headline conversions (NEW)
(define-key list-manager-map (kbd "T -") 'list-manager-convert-dash-list-to-todo-headlines)
(define-key list-manager-map (kbd "T [") 'list-manager-convert-checklist-to-todo-headlines)

;; LaTeX environment operations
(define-key list-manager-map (kbd "I") 'list-manager-latex-region-to-itemized-list)
(define-key list-manager-map (kbd ",") 'list-manager-latex-convert-csv-to-itemized-list)

;; LaTeX formatting restoration (750words recovery)
(define-key list-manager-map (kbd "B") 'list-manager-add-backslashes)
(define-key list-manager-map (kbd "n") 'list-manager-restore-newlines)
(define-key list-manager-map (kbd "R") 'list-manager-restore-latex-formatting)

;; Text manipulation
(define-key list-manager-map (kbd "s") 'list-manager-split-line-by-sentences)
(define-key list-manager-map (kbd "b") 'list-manager-remove-blank-lines-in-region)
(define-key list-manager-map (kbd "w") 'list-manager-unwrap-to-one-sentence-per-line)

;; Package introspection
(define-key list-manager-map (kbd "P") 'list-manager-org-list-package-functions)

(provide 'list-manager)

;;; insert-checked.el ends here
