using GLib;
using Vast;

int main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/array", () => {
        var a = new Vast.Array (typeof (double), sizeof (double), {10});
        var b = new Vast.Array (typeof (double), sizeof (double), {10}, {}, 0, a.data);

        assert (a.data == b.data);

        for(var i = 0; i < 10; i ++) {
            a.set_from_value ({i}, (double) i);
            assert (i == a.get_value ({i}).get_double ());
        }

        for(var i = 0; i < 10; i ++) {
            assert (i == a.get_value ({i}).get_double ());
            assert (i == b.get_value ({i}).get_double ());
        }

        // negative index
        for(var i = -1; i > -10; i--) {
            assert (10 + i == a.get_value ({i}).get_double ());
            assert (10 + i == b.get_value ({i}).get_double ());
        }
    });

    Test.add_func ("/array/zeroed", () => {
        var arr = new Vast.Array (typeof (int), sizeof (int), {10});

        for (var i = 0; i < 10; i++) {
            assert (0 == arr.get_value ({i}).get_int ());
        }
    });

    Test.add_func ("/array/fill", () => {
        var arr = new Vast.Array (typeof (int), sizeof (int), {10});

        arr.fill_value (1);

        for (var i = 0; i < 10; i++) {
            assert (1 == arr.get_value ({i}).get_int ());
        }
    });

    Test.add_func ("/array/scalar_like", () => {
        var a = new Vast.Array (typeof (double), sizeof (double), {});

        assert (1 == a.size);
        assert (null != a.data);
        assert (sizeof (double) == a.data.get_size ());

        a.set_from_value ({}, 1);
        assert (1 == a.get_value ({}).get_double ());

        var a_iter = a.iterator ();
        assert (a_iter.next ());
        assert (!a_iter.next ());
    });

    Test.add_func ("/array/gobject_construction", () => {
        var a = Object.new (typeof (Vast.Array)) as Vast.Array;

        assert (0 == a.dimension);
        assert (typeof (void) == a.scalar_type);
        assert (sizeof (void) == a.scalar_size);
        assert (1 == a.size);
        assert (0 == a.origin);
        assert (null != a.data);
        assert ("dtype: void, dsize: %lu, dimension: 0, shape: (), strides: (), size: 1, mem: 1B".printf (sizeof (void)) == a.to_string ());

        size_t [] shape = {2, 2, 2, 4};
        var b = Object.new (typeof (Vast.Array), "dimension", shape.length, "shape", shape) as Vast.Array;
        assert (typeof (void) == b.scalar_type);
        assert (sizeof (void) == b.scalar_size);
        assert (2 == b.shape[0]);
        assert (2 == b.shape[1]);
        assert (2 == b.shape[2]);
        assert (4 == b.shape[3]);
        assert (2 * 2 * 4 * sizeof (void) == b.strides[0]);
        assert (2 * 4 * sizeof (void) == b.strides[1]);
        assert (4 * sizeof (void) == b.strides[2]);
        assert (sizeof (void) == b.strides[3]);
        assert (0 == b.origin);
        assert (null != b.data);
    });

    Test.add_func ("/array/iterator", () => {
        var a = new Vast.Array (typeof (double), sizeof (double), {5, 2});

        for (var i = 0; i < 5; i++) {
            for (var j = 0; j < 2; j++) {
                a.set_from_value ({i, j}, i * j);
            }
        }

        var iter = new Iterator (a);

        for (var i = 0; i < 5; i++) {
            for (var j = 0; j < 2; j++) {
                assert (iter.next ());
                assert (i * j == iter.get_value ().get_double ());
                assert ((i * 2 + j) * sizeof (double) == iter.offset);
            }
        }

        assert (!iter.next ());

        iter.move ({0, 0});
        assert (0 == iter.get_value ().get_double ());

        iter.move ({0, 0});
        assert (0 == iter.get_value ().get_double ());
    });

    Test.add_func ("/array/to_string", () => {
        var s = new Vast.Array (typeof (double), sizeof (double), {1});
        s.set_from_value ({1}, 1);

        var v = new Vast.Array (typeof (double), sizeof (double), {6});
        v.set_from_value ({0}, 1);
        v.set_from_value ({1}, 1);
        v.set_from_value ({2}, 1);
        v.set_from_value ({3}, 1);
        v.set_from_value ({4}, 1);
        v.set_from_value ({5}, 1);

        var m = new Vast.Array (typeof (double), sizeof (double), {5, 6});
        m.set_from_value ({0, 1}, 1);
        m.set_from_value ({0, 2}, 1);
        m.set_from_value ({0, 3}, 1);
        m.set_from_value ({0, 4}, 1);
        m.set_from_value ({0, 5}, 1);

        var a = new Vast.Array (typeof (double), sizeof (double), {4, 5, 6});
        a.set_from_value ({0, 0, 1}, 1);
        a.set_from_value ({0, 0, 2}, 1);
        a.set_from_value ({0, 0, 3}, 1);
        a.set_from_value ({0, 0, 4}, 1);
        a.set_from_value ({0, 0, 5}, 1);

        var b = new Vast.Array (typeof (double), sizeof (double), {1, 2, 3, 4, 5, 6});
        assert (6 == b.dimension);
        b.set_from_value ({0, 0, 0, 0, 0, 1}, 1);
        b.set_from_value ({0, 0, 0, 0, 0, 2}, 1);
        b.set_from_value ({0, 0, 0, 0, 0, 3}, 1);
        b.set_from_value ({0, 0, 0, 0, 0, 4}, 1);
        b.set_from_value ({0, 0, 0, 0, 0, 5}, 1);

        var c = new Vast.Array (typeof (double), sizeof (double), {1});
    });

    Test.add_func ("/array/reshape", () => {
        var a = new Vast.Array (typeof (char), sizeof (char), {10});
        var b = a.reshape ({5, 2});
        assert (5 == b.shape[0]);
        assert (2 == b.shape[1]);
    });

    Test.add_func ("/array/redim", () => {
        var a = new Vast.Array (typeof (char), sizeof (char), {10});
        var b = a.redim (5);
        assert (10 == b.shape[0]);
        assert (1 == b.shape[1]);
        assert (1 == b.shape[2]);
        assert (1 == b.shape[3]);
        assert (1 == b.shape[4]);
    });

    Test.add_func ("/array/compact", () => {
        var a = new Vast.Array (typeof (uint8), sizeof (uint8), {200});

        assert (sizeof (uint8) * 200 == a.size);

        a.set_from_value ({0}, 10);
        assert (10 == a.get_value ({0}).get_uchar ());
    });

    Test.add_func ("/array/string", () => {
        var a = new Vast.Array (typeof (string), sizeof (char) * 10, {10});

        a.set_from_value  ({0}, "test");

        assert ("test" == a.get_value ({0}).get_string ());
        assert (4 == a.get_value ({0}).get_string ().length);

        // trucation
        a.set_from_value ({0}, "testtesttee");
        assert ("testtestt" == a.get_value ({0}).get_string ());

        a.set_from_string ({1}, "abcd");
        assert ("abcd" == a.get_string ({1}));
    });

    Test.add_func ("/array/large", () => {
        var a = new Vast.Array (typeof (char), sizeof (char), {100, 100, 100, 100});
    });

    Test.add_func ("/array/negative_indexing", () => {
        var a = new Vast.Array (typeof (double), sizeof (double), {10, 20});

        for(var i = 0; i < 10; i ++) {
            for (var j = 0; j < 20; j++) {
                a.set_from_value ({i, j}, (double) i * j);
            }
        }

        // negative index
        for(var i = -1; i > -10; i--) {
            assert (10 + i == a.get_value ({i, 1}).get_double ());
        }

        for(var j = -1; j > -20; j--) {
            assert (20 + j == a.get_value ({1, j}).get_double ());
        }

        // diagonal negative indexing
        for (var i = -1, j = -1; i > -10 && j > -10; i-- + j--) {
            assert ((10 + i) * (20 + j) == a.get_value ({i, j}).get_double ());
        }
    });

    Test.add_func ("/array/index", () => {
        var a = new Vast.Array (typeof (int64), sizeof (int64), {30, 30});

        for (var i = 0; i < 30; i++) {
            for (var j = 0; j < 30; j++) {
                a.set_from_value ({i, j}, i * j);
            }
        }

        assert (2 == a.index ({}).dimension);
        assert (1 == a.index ({0}).dimension);
        assert (0 == a.index ({0}).get_value ({0}).get_int64 ());
        assert (100 == a.index ({10}).get_value ({10}).get_int64 ());
        assert (0 == a.index ({10, 10}).dimension);
        assert (100 == a.index ({10, 10}).get_value ({}).get_int64 ());

        for (var i = 0; i < 30; i++) {
            assert (2 * i == a.index ({2}).get_value ({i}).get_int64 ());              // first line vector
            assert (2 * i == a.transpose ().index ({2}).get_value ({i}).get_int64 ()); // first column vector
        }
    });

    Test.add_func ("/array/viewbuilder", () => {
        var a = new Vast.Array (typeof (double), sizeof (double), {10, 20});

        for(var i = 0; i < 10; i ++) {
            for (var j = 0; j < 20; j++) {
                a.set_from_value ({i, j}, (double) (i + 1 ) * j);
            }
        }

        var b = a.build()
                 .head(0, 5, -1)
                 .end();

        assert (b.get_value({0, 1}).get_double() == 10 * 1);
        assert (b.get_value({1, 1}).get_double() == 9 * 1);

        var b1 = a.build()
                 .qslice(0, null, 5, -1)
                 .end();

        assert (b1.get_value({0, 1}).get_double() == 10 * 1);
        assert (b1.get_value({1, 1}).get_double() == 9 * 1);

        var c = a.build()
                 .tail(0, 5, -1)
                 .tail(1, 2, 3)
                 .end();

        assert (c.get_value({0, 0}).get_double() == 6 * 2);
        assert (c.get_value({0, 1}).get_double() == 6 * (2 + 3));
        assert (c.get_value({1, 2}).get_double() == 5 * (2 + 6));

        var c1 = a.build()
                 .qslice(0, 5, null, -1)
                 .qslice(1, 2, null, 3)
                 .end();

        assert (c1.get_value({0, 0}).get_double() == 6 * 2);
        assert (c1.get_value({0, 1}).get_double() == 6 * (2 + 3));
        assert (c1.get_value({1, 2}).get_double() == 5 * (2 + 6));

        var d = a.build()
                 .axis(0, 1)
                 .axis(1, 0)
                 .end();

        assert (d.get_value({3, 7}).get_double() == 8 * 3);
        assert (d.get_value({7, 3}).get_double() == 4 * 7);

        /* new axes will have shape[d] == 1 and strides[d] == 0, so we can broadcast them */
        var e = d.build(3)
                 .broadcast(-1, 30)
                 .end();

        assert (e.get_value({3, 7, 29}).get_double() == 8 * 3);
        assert (e.get_value({7, 3, 29}).get_double() == 4 * 7);

        /* here we broadcast, but the shape remain unchanged */
        var e2 = d.build(2)
                 .broadcast(1, 10)
                 .end();

        assert (20 == e2.shape[0]);
        assert (10 == e2.shape[1]);

        var f = a.build()
                 .tail(1, 5)
                 .end();

        assert (f.get_value({1, 1}).get_double() == 2 * 6);
        assert (f.get_value({1, 2}).get_double() == 2 * 7);

        var f1 = a.build()
                 .qslice(1, 5, null)
                 .end();

        assert (f1.get_value({1, 1}).get_double() == 2 * 6);
        assert (f1.get_value({1, 2}).get_double() == 2 * 7);

        var g = a.build()
                 .index(1, 5)
                 .end();

        assert (g.dimension == 1);
        assert (g.get_value({1}).get_double() == 2 * 5);
        assert (g.get_value({2}).get_double() == 3 * 5);

    });

    Test.add_func ("/array/slice", () => {
        var a = new Vast.Array (typeof (int64), sizeof (int64), {30, 30});

        for (var i = 0; i < 30; i++) {
            for (var j = 0; j < 30; j++) {
                a.set_from_value ({i, j}, i * j);
            }
        }

        var b = a.slice ({10, 10}, {20, 20});
        assert (100 == b.get_value ({0, 0}).get_int64 ());
        assert (10 == b.shape[0]);
        assert (10 == b.shape[1]);

        assert (100 == a.get_value ({10, 10}).get_int64 ());
        b.set_from_value ({0, 0}, 0);
        assert (0 == a.get_value ({10, 10}).get_int64 ());

        // negative indexing
        var c = a.slice ({-10, -10}, {-1, -1});
        assert (400 == c.get_value ({0, 0}).get_int64 ());
        assert (9 == c.shape[0]);
        assert (9 == c.shape[1]);

        assert (29 == a.slice ({0, 0}, {-1, -1}).shape[0]);
        assert (29 == a.slice ({0, 0}, {-1, -1}).shape[1]);

        // reverse stride
        // this shall die, slice cannot handle this because it assumes step == 1
        // assert (10 == a.slice ({10, 10}, {0, 0}).shape[1]);
        // assert (-1 * sizeof (int64) == a.slice ({10, 10}, {0, 0}).strides[1]);

        // full slice
        assert (30 == a.slice ({0, 0}, {(ssize_t) a.shape[0], (ssize_t) a.shape[1]}).shape[0]);

        // head slice
        assert (20 == a.head ({20, 20}).shape[0]);
        assert (20 == a.head ({-10, -10}).shape[0]);

        // tail slice
        assert (10 == a.tail ({20, 20}).shape[0]);
        assert (10 == a.tail ({-10, -10}).shape[0]);
    });

    Test.add_func ("/array/step", () => {
        var array = new Vast.Array (typeof (int64), sizeof (int64), {10});

        for (var i = 0; i < 10; i++) {
            array.set_from_value ({i}, i);
        }

        assert (5 == array.step ({2}).shape[0]);
        assert (10 == array.step ({1}).shape[0]);
        assert (2 == array.step ({5}).shape[0]);
        assert (3 == array.step ({3}).shape[0]);

        var stepped = array.step ({2});

        assert (0 == stepped.get_value ({0}).get_int64 ());
        assert (2 == stepped.get_value ({1}).get_int64 ());
        assert (4 == stepped.get_value ({2}).get_int64 ());
        assert (6 == stepped.get_value ({3}).get_int64 ());
        assert (8 == stepped.get_value ({4}).get_int64 ());

        var b = array.step ({-1});
        assert (9 == b.get_value ({0}).get_int64 ());
        assert (8 == b.get_value ({1}).get_int64 ());
        assert (7 == b.get_value ({2}).get_int64 ());
        assert (1 == b.get_value ({8}).get_int64 ());
        assert (0 == b.get_value ({9}).get_int64 ());
    });

    Test.add_func ("/array/flip", () => {
        var a = new Vast.Array (typeof (int64), sizeof (int64), {10});

        for (var i = 0; i < 10; i++) {
            a.set_from_value ({i}, i);
        }

        var b = a.flip (0);

        for (var i = 0; i < 10; i++) {
            assert (9 - i == b.get_value ({i}).get_int64 ());
        }
    });

    Test.add_func ("/array/transpose", () => {
        var array = new Vast.Array (typeof (double), sizeof (double), {2, 2});

        array.set_from_value ({0, 0}, 1);
        array.set_from_value ({0, 1}, 2);
        array.set_from_value ({1, 0}, 3);
        array.set_from_value ({1, 1}, 4);

        var transposed = array.transpose (); // implicit dim 0 and 1

        assert (1 == transposed.get_value ({0, 0}).get_double ());
        assert (2 == transposed.get_value ({1, 0}).get_double ());
        assert (3 == transposed.get_value ({0, 1}).get_double ());
        assert (4 == transposed.get_value ({1, 1}).get_double ());

        var identity = array.transpose ({1, 0});

        assert (1 == identity.get_value ({0, 0}).get_double ());
        assert (2 == identity.get_value ({1, 0}).get_double ());
        assert (3 == identity.get_value ({0, 1}).get_double ());
        assert (4 == identity.get_value ({1, 1}).get_double ());
    });

    Test.add_func ("/array/transpose/negative_indexing", () => {
        var array = new Vast.Array (typeof (double), sizeof (double), {2, 2});

        array.set_from_value ({0, 0}, 1);
        array.set_from_value ({0, 1}, 2);
        array.set_from_value ({1, 0}, 3);
        array.set_from_value ({1, 1}, 4);

        var transposed = array.transpose ({-1, -2}); // two last dims

        assert (1 == transposed.get_value ({0, 0}).get_double ());
        assert (2 == transposed.get_value ({1, 0}).get_double ());
        assert (3 == transposed.get_value ({0, 1}).get_double ());
        assert (4 == transposed.get_value ({1, 1}).get_double ());
    });

    Test.add_func ("/array/swap", () => {
        var array = new Vast.Array (typeof (double), sizeof (double), {2, 2});

        array.set_from_value ({0, 0}, 1);
        array.set_from_value ({0, 1}, 2);
        array.set_from_value ({1, 0}, 3);
        array.set_from_value ({1, 1}, 4);

        var swapped = array.swap (0, 1);

        assert (1 == swapped.get_value ({0, 0}).get_double ());
        assert (2 == swapped.get_value ({1, 0}).get_double ());
        assert (3 == swapped.get_value ({0, 1}).get_double ());
        assert (4 == swapped.get_value ({1, 1}).get_double ());
    });

    Test.add_func ("/array/mapped", () => {
        FileUtils.set_contents ("test", "a");
        MappedFile mapped_file;

        try {
            mapped_file = new MappedFile ("test", true);
        } catch (FileError err) {
            assert_not_reached ();
        }

        var a = new Vast.Array (typeof (char), sizeof (char),
                                      {1},
                                      {},
                                      0,
                                      mapped_file.get_bytes ());

        assert ('a' == a.get_value ({0}));

        a.set_from_value ({0}, 'b');

        assert ('b' == mapped_file.get_contents ()[0]);
    });

    return Test.run ();
}
