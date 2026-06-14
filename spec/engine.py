'''
Holomacs Engine Specifications
'''

from .err import Feat, Req

class Engine(Req):
    '''The Common Lisp (SBCL) engine must run side-by-side with historical
    GNU Emacs internals to verify behavioral compatibility. It must provide
    complete parity for basic Lisp forms, list manipulation, type predicates,
    symbol operations, control flow, keymaps, and file/buffer input/output.
    '''

# 1. Essential List & Equality Primitives
class EqReq(Req):
    '''The `eq` primitive compares two Lisp objects for identity.
    It returns `t` if the arguments are the same object, and `nil` otherwise.
    In Elisp, `eq` behaves like Common Lisp `eq`. Symbols, conses, and strings
    are compared by object reference, whereas integers with the same value are
    guaranteed to be `eq` in Elisp (unlike standard Common Lisp where number
    identity is comparison-dependent; the Holomacs engine must guarantee integer
    `eq` parity).
    '''

class EqualReq(Req):
    '''The `equal` primitive compares two Lisp objects for structural similarity.
    It returns `t` if they have similar structures and contents, and `nil` otherwise.
    Strings are compared character-by-character (case-sensitively), vectors are
    compared element-by-element, and lists are compared recursively. Other types
    (like symbols or numbers) are compared via `eq`.
    '''

class ConsReq(Req):
    '''The `cons` primitive creates a new cons cell whose CAR is the first argument
    and CDR is the second argument. It is the fundamental building block of lists
    and must allocate a fresh cons structure in the engine.
    '''

class ListReq(Req):
    '''The `list` primitive creates a new list with the arguments as its elements.
    It must construct a chain of fresh cons cells terminating in `nil`.
    '''

class LengthReq(Req):
    '''The `length` primitive returns the number of elements in a sequence (list, vector, or string).
    If the argument is not a sequence, the engine must raise a `wrong-type-argument` error.
    For lists, it counts cons cells until it hits `nil`. For improper lists, it should
    signal an error.
    '''

class NthReq(Req):
    '''The `nth` primitive returns the Nth element of a list (0-indexed).
    If N is negative, it returns the first element (CAR of the list).
    If N is greater than or equal to the length of the list, it returns `nil`.
    '''

class NthcdrReq(Req):
    '''The `nthcdr` primitive returns the Nth CDR of a list.
    If N is zero or negative, it returns the list itself.
    If N is greater than or equal to the length of the list, it returns `nil`.
    '''

class MemberReq(Req):
    '''The `member` primitive checks if an element is a member of a list.
    It uses `equal` for comparison. It returns the tail of the list starting
    with the first occurrence of the element if found, and `nil` otherwise.
    '''

class MemqReq(Req):
    '''The `memq` primitive checks if an element is a member of a list.
    It uses `eq` for comparison. It returns the tail of the list starting
    with the first occurrence of the element if found, and `nil` otherwise.
    '''

class AssocReq(Req):
    '''The `assoc` primitive looks up a key in an association list (alist).
    It uses `equal` to compare keys. It returns the first cons cell whose CAR
    is `equal` to the key, or `nil` if no such element is found.
    '''

class AssqReq(Req):
    '''The `assq` primitive looks up a key in an association list (alist).
    It uses `eq` to compare keys. It returns the first cons cell whose CAR
    is `eq` to the key, or `nil` if no such element is found.
    '''

class NconcReq(Req):
    '''The `nconc` primitive concatenates lists by physically modifying the CDR
    of the last cons cell of each argument to point to the next argument.
    It returns the resulting concatenated list. It is a destructive operation.
    '''

class AppendReq(Req):
    '''The `append` primitive concatenates lists by copying all arguments except
    the last one, and making the CDR of the last cons of the copied list point
    to the final argument. It returns the concatenated list without modifying
    the original input lists.
    '''

class ListEqualityPrimitives(Feat):
    '''Essential List & Equality Primitives feature grouping.'''


# 2. Core Type Predicates & Symbol Operations
class SymbolpReq(Req):
    '''The `symbolp` predicate returns `t` if the argument is a symbol, and `nil` otherwise.'''

class StringpReq(Req):
    '''The `stringp` predicate returns `t` if the argument is a string, and `nil` otherwise.'''

class IntegerpReq(Req):
    '''The `integerp` predicate returns `t` if the argument is an integer, and `nil` otherwise.'''

class NumberpReq(Req):
    '''The `numberp` predicate returns `t` if the argument is a number (integer or float), and `nil` otherwise.'''

class ListpReq(Req):
    '''The `listp` predicate returns `t` if the argument is a list (either a cons cell or `nil`), and `nil` otherwise.'''

class ArraypReq(Req):
    '''The `arrayp` predicate returns `t` if the argument is an array (vector or string), and `nil` otherwise.'''

class SymbolValueReq(Req):
    '''The `symbol-value` primitive returns the current dynamic value of a symbol.
    If the symbol's value cell is void (unbound), it must signal a `void-variable` error.
    '''

class SymbolFunctionReq(Req):
    '''The `symbol-function` primitive returns the function definition of a symbol.
    If the symbol's function cell is void (undefined), it must signal a `void-function` error.
    '''

class InternReq(Req):
    '''The `intern` primitive enters a string into the global symbol table (obarray) and returns the symbol.
    If a symbol with that name already exists, it returns the existing symbol. Otherwise, it creates
    a new symbol, enters it into the obarray, and returns it.
    '''

class MakeSymbolReq(Req):
    '''The `make-symbol` primitive returns a newly allocated, uninterned symbol whose name is the specified string.
    Its value and function cells are initially void.
    '''

class BoundpReq(Req):
    '''The `boundp` predicate returns `t` if a symbol has a bound value, and `nil` otherwise.
    It checks if the symbol's value cell is bound.
    '''

class FboundpReq(Req):
    '''The `fboundp` predicate returns `t` if a symbol has a function definition, and `nil` otherwise.
    It checks if the symbol's function cell is defined.
    '''

class TypePredicatesSymbolOperations(Feat):
    '''Core Type Predicates & Symbol Operations feature grouping.'''


# 3. Support Control Flow Special Forms
class WhileReq(Req):
    '''The interpreter/compiler must support the `while` special form.
    `while` repeatedly evaluates a test form, and if it returns non-nil,
    evaluates a body of forms, looping until the test returns `nil`.
    '''

class CatchReq(Req):
    '''The interpreter/compiler must support the `catch` special form.
    `catch` establishes a dynamic exit point with a tag symbol, then evaluates
    body forms. If a `throw` to the same tag is executed, evaluation of the
    `catch` form terminates immediately and returns the thrown value.
    '''

class ThrowReq(Req):
    '''The interpreter/compiler must support the `throw` special form.
    `throw` exits to the nearest active `catch` form with a matching tag symbol,
    passing a return value. If no matching tag is active, it must signal a
    `no-catch` error.
    '''

class ConditionCaseReq(Req):
    '''The interpreter/compiler must support the `condition-case` special form.
    It executes a body of forms with active error handlers. If an error is signaled
    during evaluation, it matches the error against handler clauses. If a match is
    found, the handler body is evaluated with the error symbol and data bound to a local variable.
    '''

class UnwindProtectReq(Req):
    '''The interpreter/compiler must support the `unwind-protect` special form.
    It guarantees that a cleanup form is executed regardless of whether the primary
    body completes normally, throws a non-local exit, or signals an error.
    '''

class ControlFlowSpecialForms(Feat):
    '''Support Control Flow Special Forms feature grouping.'''


# 4. Basic File & Keymap I/O
class FindFileNoselectReq(Req):
    '''The `find-file-noselect` primitive reads a file into a buffer and returns that buffer.
    If a buffer visiting that file already exists, it returns the existing buffer.
    If the file does not exist, it creates a new empty buffer associated with the file path.
    '''

class WriteRegionReq(Req):
    '''The `write-region` primitive writes a portion of the current buffer (from start to end offsets)
    to a specified file path. It must support appending and writing to arbitrary files.
    '''

class InsertFileContentsReq(Req):
    '''The `insert-file-contents` primitive inserts the contents of a specified file into the
    current buffer at the cursor (point) position, returning a cons of the file name and inserted length.
    '''

class MakeSparseKeymapReq(Req):
    '''The `make-sparse-keymap` primitive creates a new sparse keymap (an alist starting with the symbol `keymap`)
    and returns it. Keymaps bind keys (characters/strings) to command symbols or other keymaps.
    '''

class DefineKeyReq(Req):
    '''The `define-key` primitive associates a key sequence (string or vector) with a binding
    in a specified keymap, overriding any existing binding for that key sequence.
    '''

class LookupKeyReq(Req):
    '''The `lookup-key` primitive looks up a key sequence in a specified keymap.
    It returns the bound command/function symbol, another keymap if the sequence is prefix,
    or `nil` if the key sequence is unbound.
    '''

class UseGlobalMapReq(Req):
    '''The `use-global-map` primitive sets the active global keymap to the specified keymap.
    It defines the default fallback bindings for keyboard inputs.
    '''

class FileKeymapIO(Feat):
    '''Basic File & Keymap I/O feature grouping.'''


# 5. Arithmetic Primitives
class PlusReq(Req):
    '''The `+` primitive sums its arguments (numbers) and returns the total.
    If no arguments are provided, it returns 0.
    '''

class TimesReq(Req):
    '''The `*` primitive multiplies its arguments (numbers) and returns the product.
    If no arguments are provided, it returns 1.
    '''

class OnePlusReq(Req):
    '''The `1+` primitive returns its numeric argument incremented by 1.'''

class OneMinusReq(Req):
    '''The `1-` primitive returns its numeric argument decremented by 1.'''

class ArithmeticPrimitives(Feat):
    '''Basic Arithmetic Primitives feature grouping.'''


# 6. Output & Printing Primitives
class MessageReq(Req):
    '''The `message` primitive formats a string (using format descriptors like %s, %d)
    and prints it to the echo area / terminal. It returns the formatted string.
    '''

class PrintReq(Req):
    '''The `print` primitive outputs a Lisp object to the stream, followed by a newline.
    It prints the printed representation of the object (readable representation).
    It returns the printed object.
    '''

class OutputPrimitives(Feat):
    '''Output and Printing Primitives feature grouping.'''
