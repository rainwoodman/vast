using GLib;
using Vast;

int main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/array", () => {
        message("hello");
        var a = new Vast.Array<double?> (sizeof (double), {10});
        message("a = %s", a.to_string());
        var b = new Vast.Array<double?> (sizeof (double), {10}, null, a.data);
        message("b = %s", b.to_string());

        for(var i = 0; i < 10; i ++) {
            a.set_scalar({i}, (double) i);
            assert (i == a.get_scalar ({i}));
        }

        for(var i = 0; i < 10; i ++) {
            assert (i == a.get_scalar ({i}));
            assert (i == b.get_scalar ({i}));
        }

        // negative index
        for(var i = -1; i > -10; i--) {
            assert (10 + i == a.get_scalar ({i}));
            assert (10 + i == b.get_scalar ({i}));
        }

        var iter = a.iterator();
        while(iter.next()) {
            message("%g", iter.get());
            iter.set((double) 0);
            message("%g", iter.get());
        }
    });

    Test.add_func ("/array/large", () => {
        assert (sizeof (Value) > sizeof (void*));

        var a = new Vast.Array<Value?> (sizeof (Value), {10});

        var val = Value (typeof (string));
        val.set_string ("test");

        a.set_scalar ({0}, val);

        assert (val != a.get_scalar ({0}));
        assert ("test" == a.get_scalar ({0}).get_string ());
    });

    Test.add_func ("/array/compact", () => {
        var a = new Vast.Array<uint8?> (sizeof (uint8), {200});

        assert (sizeof (uint8) * 200 == a.size);

        a.set_scalar ({0}, 10);
        assert (10 == a.get_scalar ({0}));
    });

    Test.add_func ("/array/negative_indexing", () => {
        var a = new Vast.Array<double?> (sizeof (double), {10, 20});

        for(var i = 0; i < 10; i ++) {
            for (var j = 0; j < 20; j++) {
                a.set_scalar({i, j}, (double) i * j);
            }
        }

        // negative index
        for(var i = -1; i > -10; i--) {
            assert (10 + i == a.get_scalar ({i, 1}));
        }

        for(var j = -1; j > -20; j--) {
            assert (20 + j == a.get_scalar ({1, j}));
        }

        // diagonal negative indexing
        for (var i = -1, j = -1; i > -10 && j > -10; i-- + j--) {
            assert ((10 + i) * (20 + j) == a.get_scalar ({i, j}));
        }
    });

    Test.add_func ("/array/slice", () => {
        var a = new Vast.Array<int64?> (sizeof (int64), {30, 30});

        for (var i = 0; i < 30; i++) {
            for (var j = 0; j < 30; j++) {
                a.set_scalar ({i, j}, i * j);
            }
        }

        var b = a.slice ({10, 10}, {20, 20});
        assert (100 == b.get_scalar ({0, 0}));
        assert (10 == b.shape[0]);
        assert (10 == b.shape[1]);

        // negative indexing
        var c = a.slice ({-10, -10}, {-1, -1});
        assert (400 == c.get_scalar ({0, 0}));
        assert (9 == c.shape[0]);
        assert (9 == c.shape[1]);
    });

    Test.add_func ("/array/transpose", () => {
        var array = new Vast.Array<double?> (sizeof (double), {2, 2});

        array.set_scalar ({0, 0}, 1);
        array.set_scalar ({0, 1}, 2);
        array.set_scalar ({1, 0}, 3);
        array.set_scalar ({1, 1}, 4);

        var transposed = array.transpose (); // implicit dim 0 and 1

        assert (1 == transposed.get_scalar ({0, 0}));
        assert (2 == transposed.get_scalar ({1, 0}));
        assert (3 == transposed.get_scalar ({0, 1}));
        assert (4 == transposed.get_scalar ({1, 1}));

        var identity = array.transpose (1, 0);

        assert (1 == identity.get_scalar ({0, 0}));
        assert (2 == identity.get_scalar ({1, 0}));
        assert (3 == identity.get_scalar ({0, 1}));
        assert (4 == identity.get_scalar ({1, 1}));
    });

    Test.add_func ("/array/transpose/negative_indexing", () => {
        var array = new Vast.Array<double?> (sizeof (double), {2, 2});

        array.set_scalar ({0, 0}, 1);
        array.set_scalar ({0, 1}, 2);
        array.set_scalar ({1, 0}, 3);
        array.set_scalar ({1, 1}, 4);

        var transposed = array.transpose (-2, -1); // two last dims

        assert (1 == transposed.get_scalar ({0, 0}));
        assert (2 == transposed.get_scalar ({1, 0}));
        assert (3 == transposed.get_scalar ({0, 1}));
        assert (4 == transposed.get_scalar ({1, 1}));
    });

    Test.add_func ("/array/mapped", () => {
        FileUtils.set_contents ("test", "a");
        MappedFile mapped_file;

        try {
            mapped_file = new MappedFile ("test", true);
        } catch (FileError err) {
            assert_not_reached ();
        }

        var a = new Vast.Array<char?> (sizeof (char),
                                      {1},
                                      null,
                                      mapped_file.get_bytes ());

        assert ('a' == a.get_scalar ({0}));

        a.set_scalar ({0}, 'b');

        assert ('b' == mapped_file.get_contents ()[0]);
    });

    return Test.run ();
}
