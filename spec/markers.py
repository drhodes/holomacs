'''
Holomacs Markers & Buffer Editing Specifications
'''

from .err import Feat, Req

class MarkerLifecycleReq(Req):
    '''The engine must support standard marker lifecycle: `make-marker`, `markerp`, `marker-position`, `marker-buffer`, `set-marker`, and `copy-marker`.'''

class MarkerAdjustmentReq(Req):
    '''All registered markers must automatically adjust their position offsets on buffer insertions and deletions.'''

class BufferDeletionReq(Req):
    '''The engine must support standard buffer deletion: `delete-char`, `delete-region`, and `erase-buffer`.'''

class BufferMovementReq(Req):
    '''The engine must support line and character movements: `forward-char`, `backward-char`, `forward-line`, `beginning-of-line`, and `end-of-line`.'''

class MarkersAndBufferEditing(Feat):
    '''Markers & Advanced Buffer Editing Primitives feature grouping.'''
