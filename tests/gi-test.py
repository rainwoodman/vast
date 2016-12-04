#!/usr/bin/env python3

from gi.repository import Vast

a = Vast.Array(scalar_type=float, scalar_size=8)

assert(0 == a.get_dimension())
assert(0 == a.get_origin())
assert(a.get_data() is not None)
