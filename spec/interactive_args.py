'''
Holomacs Interactive Argument Parsing Specifications
'''

from .err import Feat, Req


class CallInteractivelyReq(Req):
    r'''The engine must implement `call-interactively`.
    - It executes an interactive command, dynamically resolving and passing the arguments specified in its `:interactive` property.
    '''


class InteractiveSpecEmptyReq(Req):
    r'''If a command's interactive specification is empty or nil, `call-interactively` must invoke it with no arguments.
    '''


class InteractiveSpecRegionReq(Req):
    r'''If the interactive spec is `"r"`, `call-interactively` must pass the region start and end (min and max of point and mark) as two integer arguments.
    '''


class InteractiveSpecPrefixReq(Req):
    r'''If the interactive spec is `"P"`, `call-interactively` must pass the raw prefix argument (held in `current-prefix-arg`).
    '''


class InteractiveSpecStringPromptReq(Req):
    r'''If the interactive spec starts with prompt codes like `"s"` (string) or `"f"` (file), the engine must read input from standard input using the prompt, and pass the string as an argument.
    '''


class CallInteractivelyUnitTestReq(Req):
    r'''The test suite must verify `call-interactively` for empty specs, region arguments, prefix arguments, and prompt-based string arguments.
    '''


class InteractiveArgsFeature(Feat):
    r'''Interactive Command Arguments and Parsing feature grouping.'''
