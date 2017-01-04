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

    def test_builder(self):
        a = Vast.Array(scalar_type=float, scalar_size=8)
        b = a.build(0).broadcast(0, 5).end()

        builder = Vast.ArrayBuilder(array=a, dimension=0)
        self.assertEqual(0, builder.get_dimension())
        self.assertIs(a, builder.get_array())

    def test_function(self):
        f = Vast.Function();

    def test_graph(self):
        return
        g = Vast.Graph()
        sin = Vast.Function()
        v_x = Vast.GraphVariable(direction=Vast.GraphVariableDirection.IN)
        v_z = Vast.GraphVariable(direction=Vast.GraphVariableDirection.OUT)
        g.connectv(sin, [v_x, v_z])
        e = Vast.SimpleGraphExecutor(graph=g)
        b = e.compute(v_z);

if __name__ == '__main__':
    unittest.main()
