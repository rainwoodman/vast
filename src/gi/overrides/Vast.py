from ..module import get_introspection_module

Vast = get_introspection_module('Vast')

Vast.Array.__getitem__ = lambda self, i: self.get_value(i)
Vast.Array.__setitem__ = lambda self, i, item: self.set_value(i, item)
