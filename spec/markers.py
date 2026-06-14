'''
Holomacs Markers & Buffer Editing Specifications
'''

from .err import Feat, Req

class MakeMarkerReq(Req):
    '''The `make-marker` primitive creates a new marker that does not point anywhere.
    Its position is initially `nil` and its buffer is `nil`.
    '''

class MarkerpReq(Req):
    '''The `markerp` predicate returns `t` if the argument is a marker object, and `nil` otherwise.'''

class MarkerPositionReq(Req):
    '''The `marker-position` primitive returns the position of a marker as an integer,
    or `nil` if the marker does not point anywhere.
    '''

class MarkerBufferReq(Req):
    '''The `marker-buffer` primitive returns the buffer that the marker points into,
    or `nil` if the marker does not point anywhere.
    '''

class SetMarkerReq(Req):
    '''The `set-marker` primitive positions a marker at a specific character offset in a buffer.
    If the buffer argument is `nil` or omitted, it points to the current buffer.
    If position is `nil` or out of range, the marker is set to point nowhere.
    '''

class CopyMarkerReq(Req):
    '''The `copy-marker` primitive returns a new marker that points to the same position
    and buffer as the argument marker.
    '''

class MarkerAdjustmentReq(Req):
    '''All registered markers pointing to a buffer must automatically adjust their position offsets
    whenever insertions or deletions occur in that buffer.
    - An insertion at or before a marker shifts the marker forward by the insertion length.
    - A deletion of a region containing or preceding the marker shifts the marker backward appropriately.
    - A deletion of a region containing the marker collapses the marker to the beginning of the deleted region.
    '''

class MarkerLifecycleAdjustment(Feat):
    '''Marker Lifecycle & Auto-Adjustment behavior grouping.'''


class DeleteCharReq(Req):
    '''The `delete-char` primitive deletes N characters directly following the cursor (point).
    If N is negative, it deletes -N characters preceding the cursor.
    '''

class DeleteRegionReq(Req):
    '''The `delete-region` primitive deletes the text between two position offsets (start and end)
    in the current buffer. It must automatically adjust active markers.
    '''

class EraseBufferReq(Req):
    '''The `erase-buffer` primitive deletes all text in the current buffer, resetting point to 1.
    All markers pointing into the buffer are set to point to position 1.
    '''

class BufferDeletionOperations(Feat):
    '''Buffer Deletion operations grouping.'''


class ForwardCharReq(Req):
    '''The `forward-char` primitive moves the cursor (point) forward by N characters.
    If N is omitted or nil, it defaults to 1. If moving would exceed buffer boundaries,
    it signals a `beginning-of-buffer` or `end-of-buffer` error.
    '''

class BackwardCharReq(Req):
    '''The `backward-char` primitive moves the cursor (point) backward by N characters.
    If N is omitted or nil, it defaults to 1. If moving would exceed buffer boundaries,
    it signals a `beginning-of-buffer` or `end-of-buffer` error.
    '''

class ForwardLineReq(Req):
    '''The `forward-line` primitive moves the cursor (point) forward by N lines,
    stopping at the beginning of the line. It returns the number of lines it failed to move.
    '''

class BeginningOfLineReq(Req):
    '''The `beginning-of-line` primitive moves the cursor (point) to the beginning
    of the current line.
    '''

class EndOfLineReq(Req):
    '''The `end-of-line` primitive moves the cursor (point) to the end of the current line.'''

class BufferMovementOperations(Feat):
    '''Buffer Movement operations grouping.'''


class GetBufferCreateReq(Req):
    '''The `get-buffer-create` primitive returns a buffer with the specified name.
    If a buffer with that name already exists, it is returned. Otherwise, a new buffer
    is created and returned.
    '''

class SetBufferReq(Req):
    '''The `set-buffer` primitive makes the specified buffer current for editing operations.
    It returns the buffer. Note that this does not display the buffer in any window.
    '''

class InsertReq(Req):
    '''The `insert` primitive inserts one or more strings/characters at the cursor (point)
    position in the current buffer, advancing point past the inserted text.
    '''

class PointReq(Req):
    '''The `point` primitive returns the current cursor position in the current buffer
    as an integer (1-indexed).
    '''

class GotoCharReq(Req):
    '''The `goto-char` primitive sets the cursor (point) in the current buffer to the
    specified position. If the position is outside the buffer boundaries, it is clamped
    to the minimum or maximum point. It returns the new position.
    '''

class PointMinReq(Req):
    '''The `point-min` primitive returns the minimum accessible position in the current buffer (always 1).'''

class PointMaxReq(Req):
    '''The `point-max` primitive returns the maximum accessible position in the current buffer
    (the buffer size plus 1).
    '''

class BufferSubstringReq(Req):
    '''The `buffer-substring` primitive returns the string text between the specified start
    and end position offsets in the current buffer.
    '''

class MakeLocalVariableReq(Req):
    '''The `make-local-variable` primitive makes a variable buffer-local in the current buffer.
    It allows the variable to have a value specific to this buffer, while other buffers
    reference the global value.
    '''

class BufferLifecycleEditing(Feat):
    '''Buffer Lifecycle, Editing, and Properties grouping.'''
