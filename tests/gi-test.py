#!/usr/bin/env python3

from gi.repository import Vast
import unittest

class ArrayTestCase(unittest.TestCase):
    def test_gobject_construction(self):
        a = Vast.Array(scalar_type=float, scalar_size=8)
        self.assertEqual(8, a.get_scalar_size())
        self.assertEqual(0, a.get_dimension())
        self.assertEqual(0, a.get_origin())
        self.assertIsNotNone(a.get_data())

if __name__ == '__main__':
    unittest.main()
