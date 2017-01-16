#!/usr/bin/env python3

from gi.repository import Vast
import unittest

class TensorTestCase(unittest.TestCase):
    def test_gobject_construction(self):
        a = Vast.Tensor(scalar_type=float, scalar_size=8)
        self.assertEqual(8, a.get_scalar_size())
        self.assertEqual(0, a.get_dimension())
        self.assertEqual(0, a.get_origin())
        self.assertIsNotNone(a.get_data())

    def test_builder(self):
        a = Vast.Tensor(scalar_type=float, scalar_size=8)
        b = a.build(0).broadcast(0, 5).end()

        builder = Vast.TensorBuilder(array=a, dimension=0)
        self.assertEqual(0, builder.get_dimension())
        self.assertIs(a, builder.get_array())

if __name__ == '__main__':
    unittest.main()
