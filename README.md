![Version](https://img.shields.io/static/v1?label=list-manager&message=1.0.0&color=brightcolor)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Emacs](https://img.shields.io/badge/Emacs-26.1+-purple.svg)](https://www.gnu.org/software/emacs/)

# List Manager

List Manager converts lists between the formats that org-mode and LaTeX
writers use every day. It turns dash lists, checklists, numbered lists,
TODO headlines, and LaTeX `\item` blocks into one another, extracts and
carries forward unchecked items, and repairs LaTeX list markup that
external tools such as 750words strip out. It is aimed at researchers and
writers who move the same content between org notes, slides, and
manuscripts.

## Features

- Convert dash, plus, asterisk, and numbered lists into LaTeX `\item`
  entries or complete `itemize` and `enumerate` environments.
- Convert freely among org dash lists, org checklists, org TODO
  headlines, and LaTeX items in every direction.
- Extract, copy, or cut the unchecked items from a mixed checklist, in
  either org or LaTeX notation.
- Carry undone TODOs and unchecked boxes forward to a "Next Week"
  heading while preserving their categories.
- Restore backslashes and newlines that 750words removes from LaTeX
  keywords, and repair `\item` lists that were flattened into one line.
- Reflow prose to one sentence per line, add missing terminal periods to
  slide bullets, and remove blank lines from a region.
- Reach every command through the `C-c x` prefix keymap.

## Requirements

- GNU Emacs 26.1 or later.
- `org` and `cl-lib`, both of which ship with Emacs.
- For the Info manual: `makeinfo` from the Texinfo package.

## Installation

List Manager is not yet on MELPA. Install it manually for now.

### Manual installation

Clone the repository:

```bash
git clone https://github.com/MooersLab/list-manager.git
```

Then add the following to your init file:

```elisp
(add-to-list 'load-path "/path/to/list-manager")
(require 'list-manager)
```

### With use-package

```elisp
(use-package list-manager
  :load-path "/path/to/list-manager")
```

## Usage

Load the package, then select a region and call a command. Most commands
act on the active region.

```elisp
;; Load the package.
(require 'list-manager)
```

Select an org dash list and convert it to LaTeX items:

```
M-x list-manager-dash-list-to-latex-items
```

The same command is available from the prefix keymap as `C-c x d`.

### Example: dash list to LaTeX items

Before:

```
- First item
- Second item
- Third item
```

After `C-c x d`:

```latex
\item First item
\item Second item
\item Third item
```

### Example: extract unchecked items

Input:

```
- [ ] Buy groceries
- [X] Call doctor
- [ ] Write report
```

After `C-c x u`, a `*Unchecked Items*` buffer opens with:

```
- [ ] Buy groceries
- [ ] Write report
```

### Example: dash list to a complete itemize environment

Before:

```
- Apple
- Banana
- Cherry
```

After `C-c x i`:

```latex
#+BEGIN_EXPORT latex
\begin{itemize}
    \item Apple
    \item Banana
    \item Cherry
\end{itemize}
#+END_EXPORT
```

## Commands and key bindings

Every command is bound under the `C-c x` prefix through the
`list-manager-map` keymap. The tables below group the commands by task.

### Unchecked item operations

| Key       | Command                                            |
|:----------|:---------------------------------------------------|
| `C-c x u` | `list-manager-extract-unchecked-items`             |
| `C-c x k` | `list-manager-extract-unchecked-items-to-kill-ring`|
| `C-c x c` | `list-manager-cut-unchecked-items`                 |
| `C-c x x` | `list-manager-cut-unchecked-items-to-kill-ring`    |

### Checklist conversions

| Key       | Command                                             |
|:----------|:----------------------------------------------------|
| `C-c x -` | `list-manager-convert-org-checklist-to-dash-list`   |
| `C-c x \` | `list-manager-convert-org-checklist-to-latex-items` |
| `C-c x [` | `list-manager-org-convert-list-in-region-to-checkboxes` |
| `C-c x ]` | `list-manager-org-convert-checkboxes-in-region-to-list` |

### Org-mode list operations

| Key       | Command                                            |
|:----------|:---------------------------------------------------|
| `C-c x m` | `list-manager-lines-in-region-to-org-list`         |
| `C-c x o` | `list-manager-org-region-to-itemized-list`         |
| `C-c x #` | `list-manager-org-convert-unordered-to-ordered-list` |
| `C-c x p` | `list-manager-org-or-latex-add-periods-to-list`    |
| `C-c x f` | `list-manager-carry-forward-todos`                 |

### Lines and dash lists to LaTeX

| Key       | Command                                              |
|:----------|:-----------------------------------------------------|
| `C-c x l` | `list-manager-lines-to-latex-items`                  |
| `C-c x U` | `list-manager-lines-to-latex-items-unchecked`        |
| `C-c x N` | `list-manager-numbered-list-to-latex-items`          |
| `C-c x d` | `list-manager-dash-list-to-latex-items`              |
| `C-c x D` | `list-manager-org-dash-list-to-latex-items`          |
| `C-c x e` | `list-manager-org-dash-list-to-latex-items-enhanced` |
| `C-c x i` | `list-manager-org-dash-list-to-latex-itemize`        |
| `C-c x C` | `list-manager-org-dash-list-to-custom-latex`         |

### LaTeX to org conversions

| Key         | Command                                             |
|:------------|:----------------------------------------------------|
| `C-c x L -` | `list-manager-convert-latex-items-to-dash-list`     |
| `C-c x L [` | `list-manager-convert-latex-items-to-org-checklist` |
| `C-c x L t` | `list-manager-convert-latex-items-to-todo-headlines`|

### TODO headline conversions

| Key         | Command                                            |
|:------------|:---------------------------------------------------|
| `C-c x t -` | `list-manager-convert-todo-headlines-to-dash-list` |
| `C-c x t [` | `list-manager-convert-todo-headlines-to-checklist` |
| `C-c x t l` | `list-manager-convert-todo-headlines-to-latex-items` |
| `C-c x T -` | `list-manager-convert-dash-list-to-todo-headlines` |
| `C-c x T [` | `list-manager-convert-checklist-to-todo-headlines` |

### LaTeX environment operations

| Key       | Command                                          |
|:----------|:-------------------------------------------------|
| `C-c x I` | `list-manager-latex-region-to-itemized-list`     |
| `C-c x ,` | `list-manager-latex-convert-csv-to-itemized-list`|

### 750words recovery

| Key       | Command                                    |
|:----------|:-------------------------------------------|
| `C-c x B` | `list-manager-add-backslashes`             |
| `C-c x n` | `list-manager-restore-newlines`            |
| `C-c x R` | `list-manager-restore-latex-formatting`    |
| `C-c x r` | `list-manager-repair-stripped-item-list`   |

### Text manipulation

| Key       | Command                                          |
|:----------|:-------------------------------------------------|
| `C-c x s` | `list-manager-split-line-by-sentences`           |
| `C-c x b` | `list-manager-remove-blank-lines-in-region`      |
| `C-c x w` | `list-manager-unwrap-to-one-sentence-per-line`   |
| `C-c x P` | `list-manager-org-list-package-functions`        |

For historical reasons a few commands also carry a direct global
binding: `C-c p` for adding periods, `C-c f` for carrying TODOs forward,
`C-c l` for the org itemized list, and `C-c C-x n` for numbering an
unordered list.

## Configuration

No configuration is required. The package works out of the box.

The prefix keymap is bound to `C-c x`. To move it, rebind the keymap in
your init file after the package loads:

```elisp
(global-set-key (kbd "C-c y") list-manager-map)
```

## Info documentation

List Manager ships a Texinfo manual for the package and a second manual
for the test suite.

Build the Info files:

```bash
make info
```

Install them into your user Info directory, which needs no root access:

```bash
make install-info-user
```

Then add the directory to your init file:

```elisp
(add-to-list 'Info-directory-list "~/.local/share/info")
```

Read the manual inside Emacs:

```
C-h i m list-manager RET
```

## Running tests

List Manager includes an ERT suite of 130 tests that covers every public
command, several bidirectional round trips, edge cases, and two
performance checks.

Run the suite from the command line:

```bash
make test
```

Run it directly:

```bash
emacs --batch -Q -L . -l list-manager.el -l list-manager-test.el \
    -f ert-run-tests-batch-and-exit
```

Run the suite interactively inside Emacs:

```
M-x ert RET t RET
```

The expected result is:

```
Ran 130 tests, 130 results as expected, 0 unexpected
```

The test suite has its own Info manual, which `make info` also builds.
Read it with `C-h i m list-manager-test RET`.

## Project structure

```
list-manager/
├── list-manager.el          # Main package
├── list-manager-test.el     # ERT test suite
├── list-manager.texi        # Texinfo manual for the package
├── list-manager-test.texi   # Texinfo manual for the test suite
├── Makefile                 # Build, test, and install automation
├── README.md                # This file
├── LICENSE                  # GPL-3.0 license text
├── CITATION.cff             # Citation metadata
├── CONTRIBUTING.md          # Contribution guidelines
└── CODE_OF_CONDUCT.md       # Contributor Covenant v2.1
```

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md)
for guidelines on how to submit issues, feature requests, and pull
requests.

## License

This project is licensed under the GNU General Public License v3.0. See
the [LICENSE](LICENSE) file for details.

## Update table

| Version | Changes                                                                                                                                            | Date         |
|:--------|:---------------------------------------------------------------------------------------------------------------------------------------------------|:-------------|
| 1.0.0   | First public release. Fixed broken commands, unified the `list-manager-` prefix, expanded the suite to 130 tests, and added the GitHub scaffolding. | 2026 July 22 |

## Sources of funding

- NIH: R01 CA242845
- NIH: R01 AI088011
- NIH: P30 CA225520 (PI: R. Mannel)
- NIH: P20 GM103640 and P30 GM145423 (PI: A. West)

## Acknowledgments

- The GNU Emacs and org-mode communities.
- The ERT regression testing framework.
- Portions of the original commands were drafted with the assistance of
  Claude.
# list-manager-el
