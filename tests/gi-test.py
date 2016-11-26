#!/usr/bin/env python3

from gi.repository import Vast

arr = Vast.Array(scalar_type=float, scalar_size=8).reshape([2, 2, 2])

arr.set_value([0, 0, 0], 1)
assert (1 == arr.get_value([0, 0, 0]))
