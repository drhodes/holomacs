'''
Holomacs Interactive Command Loop and Keymap Routing Specifications
'''

from .err import Feat, Req

class ReadCharReq(Req):
    '''The `read-char` primitive reads a single character from terminal input.
    In batch/test mode, it reads from a mock input queue/stream.
    '''

class ReadEventReq(Req):
    '''The `read-event` primitive reads a single input event (character or key symbol)
    from terminal input.
    '''

class CommandLoopVariablesReq(Req):
    '''The engine must maintain standard Emacs global variables:
    - `this-command`: The command symbol currently executing.
    - `last-command`: The command symbol that executed prior to the current one.
    - `real-last-command`: The actual last command executed (not overridden).
    - `this-command-keys`: A function returning the key sequence of the current command.
    '''

class InteractiveReq(Req):
    '''The transpiler and engine must support `(interactive)` declarations in functions.
    - Functions with `interactive` are registered as interactive commands.
    - `commandp` returns `t` for symbols holding interactive commands.
    '''

class SelfInsertCommandReq(Req):
    '''The `self-insert-command` inserts the character that invoked it into the current buffer.
    It reads the key sequence used (via `this-command-keys`) to determine the character.
    '''

class CommandLoopReq(Req):
    '''The core `command-loop` runs an infinite loop reading keys, translating them
    to commands via local/global maps, and executing them.
    - It handles standard command setup/cleanup and updates command tracking variables.
    '''

class InteractiveCommandLoop(Feat):
    '''Interactive Command Loop and Keymap Routing feature grouping.'''
