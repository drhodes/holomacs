# Archaeology Journal: Reconstructing the 1991 Oracle

### 2026-06-14: FINAL ARCHAEOLOGY UPDATE - The 64-bit Top-Tagging Oracle

**Status:** Oracle binary fully functional, compiles and runs successfully!

**The breakthrough: Top-Bit Tagging**
We successfully moved the Lisp engine's "Metadata" (type tags and GC mark bits) out of the way of modern pointers.
1.  **Word Size**: `Lisp_Object` is now a 64-bit `long`.
2.  **Tagging Scheme**: Adjusted to 8-bit types (`GCTYPEBITS 8`, `VALBITS 55`) to accommodate type values > 15 (specifically `Lisp_Window` = 20), preventing type truncation and infinite recursion loops.
3.  **Pointer Integrity**: The bottom 55 bits are reserved for pointers (`XPNTR`), which perfectly accommodates 48-bit virtual addresses on modern x86-64 Linux.

**Technical Debt Settled:**
-   **Linker Fixes**: Added `-fcommon` to allow legacy C global variable patterns.
-   **Type Harmonization**: Fixed type conflicts in `config.h`, `buffer.c` (loop alignment to `sizeof(Lisp_Object)` and `long*`), and `holomacs_stubs.c`.
-   **Calling Convention Resolution**: Defined `NO_ARG_ARRAY` in `config.h` to prevent register-based argument address leakage (e.g. `&s1` in `nconc2`), avoiding stack corruption and memory loops on modern x86-64 ABI.
-   **Implicit Declaration Cleanup**: Patched legacy source files to satisfy strict modern GCC rules.

**Build and Run Commands:**
To compile:
```bash
cd emacs-archaeology && nix-shell --run "cd src && rm -f *.o && make -f Makefile_oracle"
```
To run the bare interactive loop (use redirected stdin to exit immediately in batch mode):
```bash
./src/emacs_oracle -batch < /dev/null
```

**Archaeology Phase: COMPLETE.**
**Holomacs Common Lisp Phase: READY TO COMMENCE.**


