#!/usr/bin/env python3

from gi.repository import Vast

a = Vast.Array(scalar_type=float, scalar_size=8)

assert(0 == a.get_dimension())
assert(0 == a.get_origin())
assert(a.get_data() is None)

b = a.reshape([2, 2, 2])

assert(3 == b.get_dimension())
assert(b.get_data() is not None)
assert(64 == b.get_data().get_size())

b.set_value([0, 0, 0], 1)
assert (1 == b.get_value([0, 0, 0]))
