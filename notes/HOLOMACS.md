# Project Holomacs: Common Lisp Emacs Port

## Vision
To create a "Hollowed-out Emacs" (Holomacs) where the internal C core is replaced by a pure Common Lisp (SBCL) engine, while preserving the exact behavioral "hologram" of historical Emacs versions.

## Strategy: The TDD Strangler Fig
1. **Historical Grounding**: Start at the earliest possible stable commit of GNU Emacs (circa 1985-1991).
2. **Behavioral Oracle**: Use the original C-based Emacs as a "black box" to generate expected behavior.
3. **Subr Implementation**: Identify and reimplement the core C primitives (Subrs) in idiomatic Common Lisp.
4. **Iterative Porting**: Use LLMs to help bridge the gap between commits, verifying each step against a TTY-based test harness.

## Current Progress (June 2026)

### 1. Source Archaeology
- **Target Repository**: `https://github.com/emacs-mirror/emacs.git`
- **Initial Revision Commit**: `1ab256cb9997cf15983abc63310cdf32f0533bca` (Dated 1991, labeled "Initial revision").
- **Reference Inventories**:
    - `holomacs_primitives.txt`: List of **547 primitives** (Subrs) extracted from the C core.
    - `holomacs_c_files.txt`: List of the original C source and header files.

### 2. Architectural Decisions
- **Host Language**: Common Lisp (SBCL).
- **Core Strategy**: 
    - **Elisp-to-CL Transpiler**: Convert `.el` files into native CL to leverage SBCL's compiler.
    - **Subr Layer**: Reimplement C functions like `insert`, `goto-char`, and `search-forward` in CL.
    - **Oracle Harness**: A Python/Pexpect-based harness that runs the original C binary in a PTY and compares its screen output to the Holomacs CL implementation.

### 3. Obstacles & Technical Debt
- **C Build System**: The 1991 codebase predates modern `configure` scripts and expects 1980s headers (Termcap, K&R C).
- **Missing Headers**: Initial attempts to find `s-linux.h` failed because the OS-specific headers were structured differently (or non-existent for Linux) in the early 90s.
- **Next Step**: Patch the 1991 `src/config.in` and `Makefile` to compile on modern Linux or find a compatible `s-*.h` / `m-*.h` pair.

## How to Continue
1. **Fix the Oracle**: Get the C code in `/tmp/emacs-archaeology` to compile. This provides the "Behavioral Oracle."
2. **Scaffold Holomacs**: Initialize an SBCL project.
3. **Implement Primitives**: Start with `data.c` (math and type checking) as they are the easiest to verify.
4. **PTY Testing**: Build a Python script that compares the output of `emacs` (C) and `holomacs` (CL) for a simple command like `emacs -batch -eval "(print (+ 1 2))"`.

---
*Documented by Gemini CLI on 2026-06-14*
