# Contributing to List Manager

Thank you for considering a contribution to **List Manager**! The
following guidelines help keep the process smooth for everyone.

## Reporting bugs

If you find a bug, please open an issue using the
[bug report template](https://github.com/MooersLab/list-manager/issues/new?template=bug_report.md).

Include:

- A clear, descriptive title.
- Steps to reproduce the problem, ideally with a short buffer sample.
- Expected and actual behavior.
- Your environment (operating system, Emacs version, package version).

## Suggesting features

Feature ideas are welcome. Please open an issue using the
[feature request template](https://github.com/MooersLab/list-manager/issues/new?template=feature_request.md).

Describe the problem you want to solve, your proposed solution, and any
alternatives you considered.

## Development setup

1. Fork and clone the repository:

   ```bash
   git clone https://github.com/<your-fork>/list-manager.git
   cd list-manager
   ```

2. Confirm the prerequisites. The package needs only GNU Emacs 26.1 or
   later, because `org` and `cl-lib` ship with Emacs. The Info manual
   also needs `makeinfo` from Texinfo.

3. Byte-compile the sources to check for warnings:

   ```bash
   make compile
   ```

4. Run the tests:

   ```bash
   make test
   ```

## Pull request process

1. Create a feature branch from `main`:

   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes in small, focused commits.

3. Write or update ERT tests to cover your changes. Every public command
   should have at least one test.

4. Run the full test suite and confirm it passes with no unexpected
   results.

5. Byte-compile with `make compile` and confirm there are no new
   warnings.

6. Update the documentation (README.md and the `.texi` manuals) when you
   add or rename a command.

7. Push your branch and open a pull request against `main`.

8. Fill in the pull request template completely.

## Commit message conventions

Use the following format:

```
<type>: <short summary>

<optional body explaining the "why">
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`.

## Code style

- Follow standard Emacs Lisp conventions.
- Prefix every public function and variable with `list-manager-`.
- Give every function a docstring whose first line fits within 80
  columns.
- Byte-compile cleanly before submitting:

  ```bash
  make compile
  ```

## Code of conduct

This project follows the
[Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By
participating, you agree to uphold this code. Please report unacceptable
behavior to blaine-mooers@ou.edu.
