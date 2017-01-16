from ..module import get_introspection_module

Vast = get_introspection_module('Vast')

Vast.Tensor.__getitem__ = lambda self, i: self.get_value(i)
Vast.Tensor.__setitem__ = lambda self, i, item: self.set_value(i, item)
