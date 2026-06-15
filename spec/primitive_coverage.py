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


class PrimitiveCoverageUnitTestReq(Req):
    r'''The unit tests must verify `bolp`, `bobp`, `eolp`, `eobp`, `char-after`, `buffer-size`, and `buffer-string`.
    '''


class PrimitiveCoverageFeature(Feat):
    r'''Primitive Coverage feature grouping.'''
