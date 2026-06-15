'''
Holomacs Primitive Coverage Specifications
'''

from .err import Feat, Req


class BolpBobpReq(Req):
    r'''The engine must implement `bolp` and `bobp` primitives.
    - `bolp` returns `t` if point is at the beginning of a line (or beginning of buffer), nil otherwise.
    - `bobp` returns `t` if point is at the beginning of the buffer (position 1), nil otherwise.
    '''


class EolpEobpReq(Req):
    r'''The engine must implement `eolp` and `eobp` primitives.
    - `eolp` returns `t` if point is at the end of a line (or end of buffer), nil otherwise.
    - `eobp` returns `t` if point is at the end of the buffer (point-max), nil otherwise.
    '''


class CharAfterReq(Req):
    r'''The engine must implement `char-after` primitive.
    - It returns the character code at a given position (or at point if not specified).
    - If the position is out of range or at the end of buffer, it returns nil.
    '''


class BufferStringSizeReq(Req):
    r'''The engine must implement `buffer-string` and `buffer-size` primitives.
    - `buffer-string` returns the entire contents of the current buffer as a string.
    - `buffer-size` returns the total number of characters in the current buffer.
    '''


class RegexSearchMatchReq(Req):
    r'''The engine must implement regex search and match tracking primitives.
    - `string-match` matches a regular expression against a string.
    - `match-beginning` and `match-end` return the start and end offsets of the last match or its subexpressions.
    '''


class ReplaceMatchReq(Req):
    r'''The engine must implement `replace-match` primitive.
    - It replaces the matched text from the last regex/string match with new text.
    '''


class SimpleSearchReq(Req):
    r'''The engine must implement `search-forward` and `search-backward` primitives.
    - They search for a literal string in the current buffer from the point.
    - They move point to the end of the match (or start for backward) and return the new point on success, or signal error/return nil on failure depending on arguments.
    '''


class SkipCharsReq(Req):
    r'''The engine must implement `skip-chars-forward` and `skip-chars-backward` primitives.
    - They move point past characters belonging to a specified set.
    '''


class CasePrimitivesReq(Req):
    r'''The engine must implement case manipulation primitives.
    - `downcase`, `upcase`, and `capitalize` for string case translation.
    - `downcase-region`, `upcase-region`, and `capitalize-region` to modify case of buffer regions.
    '''


class LookingAtReq(Req):
    r'''The engine must implement `looking-at` primitive.
    - It matches a regular expression against the buffer text immediately following the point.
    '''


class HashTablePrimitivesReq(Req):
    r'''The engine must implement hash table primitives.
    - `make-hash-table`, `puthash`, `gethash`, and `remhash` for hash table lifecycle and key-value lookups.
    '''


class PrimitiveCoverageUnitTestReq(Req):
    r'''The unit tests must verify `bolp`, `bobp`, `eolp`, `eobp`, `char-after`, `buffer-size`, `buffer-string`, `string-match`, `match-beginning`, `match-end`, `replace-match`, `search-forward`, `search-backward`, `skip-chars-forward`, `skip-chars-backward`, case conversion, `looking-at`, and hash tables.
    '''


class PrimitiveCoverageFeature(Feat):
    r'''Primitive Coverage feature grouping.'''


