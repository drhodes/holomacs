'''
Holomacs Engine Specifications
'''

from .err import Feat, Req

class Engine(Req):
    '''The Common Lisp (SBCL) engine must run side-by-side with historical
    GNU Emacs internals to verify behavioral compatibility.
    '''

# 1. Essential List & Equality Primitives
class EqEqualReq(Req):
    '''The engine must implement the `eq` and `equal` primitives for type-safe comparisons.'''

class ConsListLengthReq(Req):
    '''The engine must implement list construction and inspection: `cons`, `list`, `length`, `nth`, and `nthcdr`.'''

class MemberMemqAssocAssqReq(Req):
    '''The engine must implement lookup and membership primitives: `member`, `memq`, `assoc`, and `assq`.'''

class NconcAppendReq(Req):
    '''The engine must implement list concatenation and structure mutations: `nconc` and `append`.'''

class ListEqualityPrimitives(Feat):
    '''Essential List & Equality Primitives feature grouping.'''


# 2. Core Type Predicates & Symbol Operations
class TypePredicatesReq(Req):
    '''The engine must implement type predicates: `symbolp`, `stringp`, `integerp`, `numberp`, `listp`, and `arrayp`.'''

class SymbolOperationsReq(Req):
    '''The engine must implement symbol table operations: `symbol-value`, `symbol-function`, `intern`, and `make-symbol`.'''

class TypePredicatesSymbolOperations(Feat):
    '''Core Type Predicates & Symbol Operations feature grouping.'''


# 3. Support Control Flow Special Forms
class WhileLoopReq(Req):
    '''The interpreter must support the `while` special form for looping.'''

class CatchThrowReq(Req):
    '''The interpreter must support the `catch` and `throw` special forms for non-local exits.'''

class ErrorHandlingReq(Req):
    '''The interpreter must support the `condition-case` and `unwind-protect` special forms for robust error handling and cleanup.'''

class ControlFlowSpecialForms(Feat):
    '''Support Control Flow Special Forms feature grouping.'''


# 4. Basic File & Keymap I/O
class FileOperationsReq(Req):
    '''The engine must support standard file operations: `find-file-noselect`, `write-region`, and `insert-file-contents`.'''

class KeymapOperationsReq(Req):
    '''The engine must support keymaps: `make-sparse-keymap`, `define-key`, `lookup-key`, and `use-global-map`.'''

class FileKeymapIO(Feat):
    '''Basic File & Keymap I/O feature grouping.'''
