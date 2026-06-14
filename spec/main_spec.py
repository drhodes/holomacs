'''
main spec
'''

from libspec import Spec
from . import app, engine

class MainSpec(Spec):
    def modules(self):
        return [app, engine]
