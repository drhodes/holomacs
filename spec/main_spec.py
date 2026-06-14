'''
main spec
'''

from libspec import Spec
from . import app, engine, markers

class MainSpec(Spec):
    def modules(self):
        return [app, engine, markers]
