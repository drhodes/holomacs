from .err import Feat, Req

class DefaultKeybindingsReq(Req):
    '''The editor must populate the global keymap with default self-insert bindings
    for all printable ASCII characters (characters 32 to 126) during state initialization.
    '''

class CommandLoopRedisplayReq(Req):
    '''The command loop must invoke `redisplay` at the start of each input-reading cycle
    to ensure that updates are rendered on screen before waiting for the next keypress.
    '''

class RunEditorEntryPointReq(Req):
    '''The editor must provide a `run-editor` entry point function.
    '''

class RunEditorStateInitReq(Req):
    '''The `run-editor` function must initialize a fresh Elisp state by calling `init-elisp-state`.
    '''

class RunEditorRawModeWrapperReq(Req):
    '''The `run-editor` function must execute the command loop inside the `with-raw-terminal` wrapper.
    '''

class RunEditorCommandLoopReq(Req):
    '''The `run-editor` function must run the interactive `command-loop`.
    '''

class TerminalEditor(Feat):
    '''Terminal Editor feature grouping.'''
