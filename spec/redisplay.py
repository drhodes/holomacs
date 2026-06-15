'''
Holomacs Redisplay and Interactive Terminal Loop Specifications
'''

from .err import Feat, Req


class RedisplayPrimitiveReq(Req):
    r'''The engine must implement a `redisplay` primitive.
    If the global variable `noninteractive` is bound and non-nil, `redisplay` must return nil and perform no operations.
    '''


class RedisplayClearScreenReq(Req):
    r'''The `redisplay` primitive must clear the terminal screen using ANSI escape codes `\e[H\e[2J` before writing the layout.
    '''


class RedisplayHeaderLineReq(Req):
    r'''The layout rendering must include a header line displaying the buffer name (e.g., `=== BUFFER: *scratch* ===`).
    '''


class RedisplayHighlightCursorReq(Req):
    r'''The layout rendering must highlight the character at the current 1-indexed point position using reverse video (ANSI `\e[7m<char>\e[0m`).
    '''


class RedisplayHighlightPointMaxReq(Req):
    r'''If the point is at point-max, a highlighted trailing space `\e[7m \e[0m` is rendered to indicate the cursor at the end of the buffer.
    '''


class RedisplayModelineReq(Req):
    r'''The layout rendering must include a modeline displaying the buffer name, major mode, and point position (e.g., `--- *scratch* (Fundamental) --- Point: 1 ---`).
    '''


class TerminalRawModeSetupReq(Req):
    r'''A terminal wrapper must configure the TTY to raw mode (no buffering, no echo via `stty raw -echo`) before loop execution so characters are read instantly.
    '''


class TerminalRawModeCleanupReq(Req):
    r'''The terminal wrapper must use `unwind-protect` to guarantee that terminal settings are restored to sane echo mode (via `stty sane`) upon exit, error, or interruption.
    '''


class RedisplayUnitTestLayoutReq(Req):
    r'''The test suite must verify the layout rendering format and cursor highlighting for mid-buffer and end-of-buffer points.
    '''


class TerminalRawModeUnitTestCleanupReq(Req):
    r'''The test suite must verify that the raw terminal wrapper successfully restores sane mode even under abnormal exit or errors.
    '''


class RedisplayAndInteractiveLoop(Feat):
    r'''Logical Redisplay & Interactive Loop feature grouping.'''
