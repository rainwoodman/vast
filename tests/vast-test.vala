using GLib;
using Vast;

int main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/array", () => {
        message("hello");
        var a = new Vast.Array (typeof (double), sizeof (double), {10});
        var b = new Vast.Array (typeof (double), sizeof (double), {10}, {}, a.data);

        assert (a.data == b.data);

        for(var i = 0; i < 10; i ++) {
            a.set_value ({i}, (double) i);
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

        foreach (var val in a) {
            message ("%f", *(double*) val);
        }
    });

    Test.add_func ("/array/scalar_like", () => {
        var a = new Vast.Array (typeof (double), sizeof (double), {});

        assert (null == a.shape);
        assert (null == a.strides);
        assert (1 == a.size);
        assert (null != a.data);
        assert (sizeof (double) == a.data.get_size ());

        a.set_value ({}, 1);
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
        assert (null == a.shape);
        assert (null == a.strides);
        assert (1 == a.size);
        assert (0 == a.origin);
        assert (null == a.data);
        assert ("dtype: void, dsize: %lu, dimension: 0, shape: (), strides: (), mem: 0B".printf (sizeof (void)) == a.to_string ());

        var b = a.reshape ({2, 2, 2, 4});
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
                a.set_value ({i, j}, i * j);
            }
        }

        var iter = new Iterator (a);

        for (var i = 0; i < 5; i++) {
            for (var j = 0; j < 2; j++) {
                assert (iter.next ());
                assert (i * j == iter.get_value ().get_double ());
                message ("%" + size_t.FORMAT, iter.offset);
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
        s.set_value ({1}, 1);
        message("s = %s", s.to_string());

        var v = new Vast.Array (typeof (double), sizeof (double), {6});
        v.set_value ({0}, 1);
        v.set_value ({1}, 1);
        v.set_value ({2}, 1);
        v.set_value ({3}, 1);
        v.set_value ({4}, 1);
        v.set_value ({5}, 1);
        message("v = %s", v.to_string());

        var m = new Vast.Array (typeof (double), sizeof (double), {5, 6});
        m.set_value ({0, 1}, 1);
        m.set_value ({0, 2}, 1);
        m.set_value ({0, 3}, 1);
        m.set_value ({0, 4}, 1);
        m.set_value ({0, 5}, 1);
        message("m = %s", m.to_string());

        var a = new Vast.Array (typeof (double), sizeof (double), {4, 5, 6});
        a.set_value ({0, 0, 1}, 1);
        a.set_value ({0, 0, 2}, 1);
        a.set_value ({0, 0, 3}, 1);
        a.set_value ({0, 0, 4}, 1);
        a.set_value ({0, 0, 5}, 1);
        message("a = %s", a.to_string());

        var b = new Vast.Array (typeof (double), sizeof (double), {1, 2, 3, 4, 5, 6});
        assert (6 == b.dimension);
        b.set_value ({0, 0, 0, 0, 0, 1}, 1);
        b.set_value ({0, 0, 0, 0, 0, 2}, 1);
        b.set_value ({0, 0, 0, 0, 0, 3}, 1);
        b.set_value ({0, 0, 0, 0, 0, 4}, 1);
        b.set_value ({0, 0, 0, 0, 0, 5}, 1);
        message("b = %s", b.to_string());

        var c = new Vast.Array (typeof (double), sizeof (double), {1});
        message ("c = %s", c.to_string ());
    });

    Test.add_func ("/array/reshape", () => {
        var a = new Vast.Array (typeof (char), sizeof (char), {10});
        var b = a.reshape ({5, 2});
        assert (5 == b.shape[0]);
        assert (2 == b.shape[1]);
    });

    Test.add_func ("/array/compact", () => {
        var a = new Vast.Array (typeof (uint8), sizeof (uint8), {200});

        assert (sizeof (uint8) * 200 == a.size);

        a.set_value ({0}, 10);
        assert (10 == a.get_value ({0}).get_uchar ());
    });

    Test.add_func ("/array/string", () => {
        var a = new Vast.Array (typeof (string), sizeof (char) * 10, {10});

        a.set_value ({0}, "test");

        assert ("test" == a.get_value ({0}).get_string ());
        assert (4 == a.get_value ({0}).get_string ().length);

        // trucation
        a.set_value ({0}, "testtesttee");
        assert ("testtestt" == a.get_value ({0}).get_string ());
    });

    Test.add_func ("/array/large", () => {
        var a = new Vast.Array (typeof (char), sizeof (char), {100, 100, 100, 100});
    });

    Test.add_func ("/array/negative_indexing", () => {
        var a = new Vast.Array (typeof (double), sizeof (double), {10, 20});

        for(var i = 0; i < 10; i ++) {
            for (var j = 0; j < 20; j++) {
                a.set_value ({i, j}, (double) i * j);
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

    Test.add_func ("/array/slice", () => {
        var a = new Vast.Array (typeof (int64), sizeof (int64), {30, 30});

        for (var i = 0; i < 30; i++) {
            for (var j = 0; j < 30; j++) {
                a.set_value ({i, j}, i * j);
            }
        }

        var b = a.slice ({10, 10}, {20, 20});
        assert (100 == b.get_value ({0, 0}).get_int64 ());
        assert (10 == b.shape[0]);
        assert (10 == b.shape[1]);

        assert (100 == a.get_value ({10, 10}).get_int64 ());
        b.set_value ({0, 0}, 0);
        assert (0 == a.get_value ({10, 10}).get_int64 ());

        // negative indexing
        var c = a.slice ({-10, -10}, {-1, -1});
        assert (400 == c.get_value ({0, 0}).get_int64 ());
        assert (9 == c.shape[0]);
        assert (9 == c.shape[1]);

        assert (29 == a.slice ({0, 0}, {-1, -1}).shape[0]);
        assert (29 == a.slice ({0, 0}, {-1, -1}).shape[1]);

        // reverse stride
        message (a.slice ({10, 10}, {0, 0}).to_string ());
        assert (10 == a.slice ({10, 10}, {0, 0}).shape[1]);
        assert (-1 * sizeof (int64) == a.slice ({10, 10}, {0, 0}).strides[1]);

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
            array.set_value ({i}, i);
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
            a.set_value ({i}, i);
        }

        var b = a.flip (0);

        for (var i = 0; i < 10; i++) {
            assert (9 - i == b.get_value ({i}).get_int64 ());
        }
    });

    Test.add_func ("/array/transpose", () => {
        var array = new Vast.Array (typeof (double), sizeof (double), {2, 2});

        array.set_value ({0, 0}, 1);
        array.set_value ({0, 1}, 2);
        array.set_value ({1, 0}, 3);
        array.set_value ({1, 1}, 4);

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

        array.set_value ({0, 0}, 1);
        array.set_value ({0, 1}, 2);
        array.set_value ({1, 0}, 3);
        array.set_value ({1, 1}, 4);

        var transposed = array.transpose ({-1, -2}); // two last dims

        assert (1 == transposed.get_value ({0, 0}).get_double ());
        assert (2 == transposed.get_value ({1, 0}).get_double ());
        assert (3 == transposed.get_value ({0, 1}).get_double ());
        assert (4 == transposed.get_value ({1, 1}).get_double ());
    });

    Test.add_func ("/array/swap", () => {
        var array = new Vast.Array (typeof (double), sizeof (double), {2, 2});

        array.set_value ({0, 0}, 1);
        array.set_value ({0, 1}, 2);
        array.set_value ({1, 0}, 3);
        array.set_value ({1, 1}, 4);

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
                                      mapped_file.get_bytes ());

        assert ('a' == a.get_value ({0}));

        a.set_value ({0}, 'b');

        assert ('b' == mapped_file.get_contents ()[0]);
    });

    return Test.run ();
}
