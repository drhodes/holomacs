'''
Holomacs Common Lisp Unit Test Suite Specifications

This spec covers the introduction of a native CL test suite using the
Parachute framework. Tests live in `tests/` and are a separate ASDF system
(:holomacs/tests). They complement the existing oracle-comparison harness
(test_harness.py) by testing CL internals directly, without Emacs.

Test philosophy
---------------
- The oracle harness (test_harness.py) is the *integration* layer:
  does our Elisp surface match real Emacs output?
- The Parachute suite is the *unit* layer:
  do individual CL primitives, the reader, and the transpiler behave correctly
  in isolation?
- Both layers must stay green. `make test` runs both.
'''

from .err import Feat, Req


# ---------------------------------------------------------------------------
# Infrastructure
# ---------------------------------------------------------------------------

class ParachuteDepReq(Req):
    '''Parachute must be declared as a dependency of the test system.

    - `holomacs.asd` gains a secondary system definition:
        (defsystem "holomacs/tests"
          :depends-on ("holomacs" "parachute")
          :components ((:file "tests/package")
                       (:file "tests/test-reader")
                       (:file "tests/test-primitives")
                       (:file "tests/test-transpiler")
                       (:file "tests/test-command-loop"))
          :perform (test-op (op c)
                    (symbol-call :parachute :test :holomacs/tests)))
    - The dependency is fetched via Quicklisp when not already present.
    - No external tooling (Qlot, Roswell) is required; plain `sbcl` +
      Quicklisp is sufficient.
    '''

class TestPackageReq(Req):
    '''A dedicated package `holomacs/tests` must exist for all test forms.

    - Defined in `tests/package.lisp`.
    - Uses `(:use :cl :parachute)` and imports holomacs internals
      with `(:local-nicknames (:h :holomacs))`.
    - No test symbols leak into the `:holomacs` package.
    '''

class MakefileTestTargetReq(Req):
    '''The Makefile must provide a `test` target that runs both layers.

    - `make test` must:
        1. Run `python3 test_harness.py demos/*.el`  (oracle layer).
        2. Run `sbcl --load run_tests.lisp`          (Parachute layer).
    - A non-zero exit code from either layer fails the target.
    - The existing `make run-demos` alias is preserved.
    '''

class RunTestsEntrypointReq(Req):
    '''A `run_tests.lisp` script at project root must load and run the suite.

    It must:
    - Load Quicklisp (`~/quicklisp/setup.lisp`) if not already loaded.
    - `(ql:quickload :parachute)` to ensure the framework is present.
    - `(asdf:load-system :holomacs/tests)` to compile and load test files.
    - `(parachute:test :holomacs/tests)` to execute all tests.
    - Exit 0 on success, non-zero on any failure.
    '''


# ---------------------------------------------------------------------------
# Reader Tests
# ---------------------------------------------------------------------------

class ReaderCharLiteralTestReq(Req):
    '''The test suite must verify Elisp `?x` character literal reading.

    Tests must cover:
    - `?a`  => 97  (lowercase ASCII)
    - `?Z`  => 90  (uppercase ASCII)
    - `?0`  => 48  (digit)
    - `?\\n` => 10  (newline escape)
    - `?\\t` => 9   (tab escape)
    - `?\\r` => 13  (carriage return escape)
    - `?\\ ` => 32  (escaped space)
    - `?\\\\` => 92 (escaped backslash)

    Tested by calling `make-elisp-readtable` and reading from a string stream.
    '''

class ReaderStringLiteralTestReq(Req):
    '''The test suite must verify that the custom string reader handles escapes.

    Tests must cover:
    - Plain string `"hello"` => `"hello"`
    - Embedded newline `"a\\nb"` => string with actual newline character.
    - Embedded tab `"a\\tb"` => string with actual tab character.
    - Embedded backslash `"a\\\\b"` => `"a\\b"`.
    '''

class ReaderReadtableCompositionTestReq(Req):
    '''The test suite must verify that `make-elisp-readtable` produces a
    readtable where both the string reader and char-literal reader are active
    simultaneously, without interfering with standard CL tokens.

    Test: read `(?a "hello" 42 nil t)` from a single string as a list and
    assert the result is `(97 "hello" 42 nil t)`.
    '''


# ---------------------------------------------------------------------------
# Primitive Tests
# ---------------------------------------------------------------------------

class PrimCharToStringTestReq(Req):
    '''The test suite must verify `char-to-string`.

    Tests must cover:
    - `(char-to-string 65)` => `"A"`
    - `(char-to-string 97)` => `"a"`
    - `(char-to-string 10)` => a string containing a newline.
    '''

class PrimStringToCharTestReq(Req):
    '''The test suite must verify `string-to-char`.

    Tests must cover:
    - `(string-to-char "A")` => 65
    - `(string-to-char "hello")` => 104  (first char only)
    - `(string-to-char "")` => 0
    '''

class PrimIntToStringTestReq(Req):
    '''The test suite must verify `int-to-string`.

    Tests must cover:
    - `(int-to-string 0)` => `"0"`
    - `(int-to-string 42)` => `"42"`
    - `(int-to-string -7)` => `"-7"`
    '''

class PrimConcatTestReq(Req):
    '''The test suite must verify `concat`.

    Tests must cover:
    - `(concat "a" "b" "c")` => `"abc"`
    - `(concat)` => `""`
    - `(concat "hello" " " "world")` => `"hello world"`
    '''

class PrimSubstringTestReq(Req):
    '''The test suite must verify `substring`.

    Tests must cover:
    - `(substring "hello" 1 3)` => `"el"`
    - `(substring "hello" 2)` => `"llo"` (no end)
    - `(substring "hello" 0 5)` => `"hello"`
    '''

class PrimLookupKeyTestReq(Req):
    '''The test suite must verify `lookup-key` on a freshly constructed keymap.

    Tests must cover:
    - An unbound key returns `nil`.
    - After `(define-key map "a" 'my-cmd)`, `(lookup-key map "a")` => `my-cmd`.
    - Keys are case-sensitive: `"a"` and `"A"` are different bindings.
    '''

class PrimDefineKeyTestReq(Req):
    '''The test suite must verify `define-key` map mutation.

    Tests must cover:
    - Binding a new key adds it.
    - Re-binding an existing key replaces the old command.
    - `(define-key map "x" nil)` unbinds the key (lookup returns nil).
    '''


# ---------------------------------------------------------------------------
# Symbol & Variable Tests
# ---------------------------------------------------------------------------

class SymbolValueRoundtripTestReq(Req):
    '''The test suite must verify `elisp-symbol-value` / `elisp-set-variable`
    roundtrip behavior in a fresh Elisp state.

    Tests must cover:
    - Setting and getting a global variable.
    - A void variable raises an elisp-style condition (not a CL unbound-variable).
    - Buffer-local variables shadow global variables for the current buffer.
    '''

class UnreadCommandCharTestReq(Req):
    '''The test suite must verify the `unread-command-char` queue.

    Tests must cover:
    - Initial value is -1.
    - After `(setq unread-command-char 97)`, `(read-char)` returns 97
      and `unread-command-char` reverts to -1.
    - A second `(read-char)` without repopulating reads normally (or signals
      EOF on an empty stream).
    '''


# ---------------------------------------------------------------------------
# Transpiler Tests
# ---------------------------------------------------------------------------

class TranspilerAtomRoundtripTestReq(Req):
    '''The test suite must verify that `transpile-elisp` on self-evaluating
    atoms returns the correct CL form.

    Tests must cover:
    - Integer: `(transpile-elisp 42)` => `42`
    - String:  `(transpile-elisp "hi")` => `"hi"`
    - Nil:     `(transpile-elisp nil)` => `nil`
    - T:       `(transpile-elisp t)` => `t`
    '''

class TranspilerSetqFormTestReq(Req):
    '''The test suite must verify `transpile-elisp` on `setq` forms.

    Tests must cover:
    - `(setq x 1)` transpiles to an `elisp-set-variable` call for `x`.
    - Multi-assignment `(setq a 1 b 2)` transpiles to a `progn` of two
      `elisp-set-variable` calls.
    '''

class TranspilerDefunInteractiveTestReq(Req):
    '''The test suite must verify that `transpile-elisp` on a `defun` with
    `(interactive)` stores the `:user-interactive` sentinel correctly.

    Tests must cover:
    - After transpiling `(defun my-cmd () (interactive) (insert "x"))`,
      `(get 'my-cmd 'interactive)` => `:user-interactive`.
    - After transpiling `(defun my-cmd () (interactive "r") ...)`,
      `(get 'my-cmd 'interactive)` => `"r"`.
    - A `defun` without `(interactive)` leaves the property unset.
    '''

class TranspilerCharLiteralTestReq(Req):
    '''The test suite must verify that char literals (`?x`) loaded through
    `compile-elisp-form` evaluate to the correct integer.

    Tests must cover:
    - `(compile-elisp-form 65)` (already an int) => `65`
    - A form read through the elisp readtable: `?a` => `97`
    - `?\n` => `10`

    This exercises the reader and transpiler together end-to-end.
    '''


# ---------------------------------------------------------------------------
# Command Loop Tests
# ---------------------------------------------------------------------------

class CommandpTestReq(Req):
    '''The test suite must verify `commandp` sentinel semantics.

    Tests must cover:
    - A symbol with `(get sym 'interactive)` => `t` returns `t`.
    - A symbol with `(get sym 'interactive)` => `:user-interactive`
      returns `(interactive)`.
    - A symbol with `(get sym 'interactive)` => `"r"` returns
      `(interactive "r")`.
    - A symbol with no interactive property returns `nil`.
    - The symbol `'car` returns `nil`.
    '''

class CommandExecuteTestReq(Req):
    '''The test suite must verify `command-execute` dispatches correctly.

    Tests must cover:
    - Calling `(command-execute 'my-cmd)` invokes `my-cmd`'s function.
    - `this-command` is bound to `my-cmd` during execution.
    - `last-command` is updated to the previous `this-command` after execution.
    - Calling with a lambda (not a symbol) also works.
    '''

class SelfInsertCommandTestReq(Req):
    '''The test suite must verify `self-insert-command` inserts the current key.

    Tests must cover:
    - With `*this-command-keys*` set to `"x"`, `self-insert-command` inserts
      `"x"` into the current buffer.
    - The buffer point advances by 1.
    '''


# ---------------------------------------------------------------------------
# Feature grouping
# ---------------------------------------------------------------------------

class ClTestSuite(Feat):
    '''CL Unit Test Suite (Parachute) feature grouping.

    Covers: test infrastructure, reader tests, primitive tests, symbol/variable
    tests, transpiler tests, and command-loop tests.
    '''
