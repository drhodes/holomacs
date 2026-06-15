'''
main spec
'''

from libspec import Spec
from . import app, engine, markers, transpiler, command_loop, cl_tests, redisplay, interactive_args, primitive_coverage

class MainSpec(Spec):
    def modules(self):
        return [app, engine, markers, transpiler, command_loop, cl_tests, redisplay, interactive_args, primitive_coverage]



