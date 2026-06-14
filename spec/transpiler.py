'''
Holomacs Elisp-to-CL Transpiler Specifications
'''

from .err import Feat, Req

class TranspileAtomReq(Req):
    '''The transpiler must translate self-evaluating Elisp atoms directly into their Common Lisp equivalents.
    - Numbers (integers, floats) are translated directly: `42` -> `42`, `3.14` -> `3.14`.
    - Strings are translated to Common Lisp strings: `"abc"` -> `"abc"`.
    - Characters (like `?a`) are translated to Common Lisp characters: `?a` -> `#\\a`.
    - The boolean value `nil` (and empty lists) are translated to `nil`, and `t` is translated to `t`.
    '''

class TranspileSymbolReq(Req):
    '''The transpiler must translate Elisp symbols to Common Lisp symbols.
    - Standard Elisp symbols must be mapped into the `:holomacs` package namespace to avoid clashes with Common Lisp built-ins.
    - Special symbols `nil`, `t`, and keywords (e.g. `:tag`) must map directly to their CL equivalents.
    - Case sensitivity must be preserved.
    '''

class TranspileFunctionCallReq(Req):
    '''The transpiler must translate general function calls `(fn args...)` to CL function calls in the `:holomacs` package.
    - If `fn` is not a special form, it must be transpiled as a function call in the `:holomacs` package.
    - All argument expressions must be recursively transpiled.
    - Example: `(message "Hello %s" name)` -> `(holomacs::message "Hello %s" holomacs::name)`.
    '''

class TranspileDefunReq(Req):
    '''The transpiler must translate Elisp `defun` declarations into Common Lisp `defun` forms.
    - The function name symbol is mapped to the `:holomacs` namespace.
    - Function parameters must be declared `special` via `(declare (special param1 param2 ...))` inside the body
      to ensure authentic Elisp dynamic scoping inside the function.
    - Example:
      ```elisp
      (defun my-func (x) (+ x 1))
      ```
      transpiles to:
      ```cl
      (defun holomacs::my-func (holomacs::x)
        (declare (special holomacs::x))
        (holomacs::+ holomacs::x 1))
      ```
    '''

class TranspileSetqReq(Req):
    '''The transpiler must translate Elisp `setq` assignments into Common Lisp `setq` (or `setf`) forms.
    - Variables assigned are mapped to the `:holomacs` namespace.
    - Multiple assignments must be supported: `(setq a 1 b 2)` -> `(setq holomacs::a 1 holomacs::b 2)`.
    '''

class TranspileQuoteReq(Req):
    '''The transpiler must translate `quote` special forms to Common Lisp `quote` forms.
    - It must preserve the structure of the quoted form, but any symbols inside the quoted form must be interned
      in the `:holomacs` package (except standard symbols like `nil`, `t`, and keywords).
    - Example: `'(a b c)` -> `'(holomacs::a holomacs::b holomacs::c)`.
    '''

class TranspilePrognReq(Req):
    '''The transpiler must translate `progn` special forms to Common Lisp `progn` forms.
    - All sub-expressions inside the body must be recursively transpiled.
    '''

class TranspileIfReq(Req):
    '''The transpiler must translate `if` special forms to Common Lisp `if` forms.
    - It must support the three-part structure: `(if cond then else...)`.
    - If there are multiple `else` forms, they must be wrapped in an implicit `progn` in the transpiled Common Lisp output.
    - Example: `(if test then else1 else2)` -> `(if test then (progn else1 else2))`.
    '''

class TranspileCondReq(Req):
    '''The transpiler must translate `cond` special forms to Common Lisp `cond` forms.
    - Each clause of the `cond` must be transpiled.
    - If a clause has a condition but no body, it should transpile to evaluate the condition.
    '''

class TranspileLetReq(Req):
    '''The transpiler must translate `let` local bindings to Common Lisp `let` forms.
    - All local variables bound by the `let` must be declared `special` via `(declare (special var1 var2 ...))`
      at the beginning of the body to guarantee Elisp's dynamic scoping behavior.
    - Binding values must be evaluated in parallel (before any variables are bound).
    - Example:
      ```elisp
      (let ((a 1) (b 2)) (print (+ a b)))
      ```
      transpiles to:
      ```cl
      (let ((holomacs::a 1) (holomacs::b 2))
        (declare (special holomacs::a holomacs::b))
        (holomacs::print (holomacs::+ holomacs::a holomacs::b)))
      ```
    '''

class TranspileLetStarReq(Req):
    '''The transpiler must translate `let*` sequential bindings to Common Lisp `let*` forms.
    - All local variables bound by the `let*` must be declared `special` via `(declare (special var1 var2 ...))`
      at the beginning of the body to guarantee Elisp's dynamic scoping behavior.
    - Binding values must be evaluated sequentially.
    '''

class TranspileWhileReq(Req):
    '''The transpiler must translate Elisp `while` loops to Common Lisp `loop while` or recursive forms.
    - Example: `(while test body...)` -> `(loop while test do (progn body...))`.
    '''

class TranspileCatchReq(Req):
    '''The transpiler must translate `catch` special forms to Common Lisp `catch` forms.
    - The tag expression and body forms must be recursively transpiled.
    '''

class TranspileThrowReq(Req):
    '''The transpiler must translate `throw` special forms to Common Lisp `throw` forms.
    - The tag expression and value expression must be recursively transpiled.
    '''

class TranspileConditionCaseReq(Req):
    '''The transpiler must translate `condition-case` special forms to Common Lisp `handler-case` forms.
    - The variable symbol used to bind error info must be transpiled, or if it is nil/ignored, handled appropriately.
    - Elisp error symbols (like `error`) must map to their corresponding Common Lisp condition types (like `elisp-error`).
    '''

class TranspileUnwindProtectReq(Req):
    '''The transpiler must translate `unwind-protect` special forms to Common Lisp `unwind-protect` forms.
    - The protected form and cleanup forms must be recursively transpiled.
    '''

class CompileLoadReq(Req):
    '''The engine must support loading, transpiling, and natively compiling Elisp source files at runtime.
    - The file must be read form by form.
    - Each form is transpiled to Common Lisp.
    - The transpiled form is compiled using SBCL's native compiler and loaded into the active runtime.
    '''

class ElispToClTranspiler(Feat):
    '''Elisp-to-CL Transpiler feature grouping.'''
