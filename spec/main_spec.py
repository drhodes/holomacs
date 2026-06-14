'''
main spec
'''

from libspec import Spec
from . import app, engine, markers, transpiler

class MainSpec(Spec):
    def modules(self):
        return [app, engine, markers, transpiler]
