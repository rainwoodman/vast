using GLib;
using Math;
using Vast;

int main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/graph", () => {
        var osin = new SimpleOperation ("sin", {"x", "y"}, (arrays) => {
            var from_iter = arrays[0].iterator ();
            var to_iter   = arrays[1].iterator ();
            while (from_iter.next () && to_iter.next ()) {
                to_iter.set_from_value (GLib.Math.sin (from_iter.get_value ().get_double ()));
            }
        });
        var ocos = new SimpleOperation ("cos", {"x", "y"}, (arrays) => {
            var from_iter = arrays[0].iterator ();
            var to_iter   = arrays[1].iterator ();
            while (from_iter.next () && to_iter.next ()) {
                to_iter.set_from_value (GLib.Math.cos (from_iter.get_value ().get_double ()));
            }
        });

        var graph = new Vast.Graph();
        var X = graph.create_variable(Graph.Variable.Direction.IN);
        var Y = graph.create_variable(Graph.Variable.Direction.OUT);
        var R1 = graph.create_variable(Graph.Variable.Direction.INOUT);

        // z = sin (x)
        graph.connectv (osin, {X, R1});

        // z = cos (x)
        graph.connectv (ocos, {R1, Y});

        message("%s", graph.to_string());
        var exec = new SimpleGraphExecutor(graph);

        var x = new Vast.Array (typeof (double), sizeof (double), {});
        x.fill_from_value (1.0);
        exec.assign (X, x);

        Vast.Array y;
        try {
            y = exec.compute({Y})[0];
        } catch (Error err) {
            assert_not_reached ();
        }

        assert (y.get_value ({}).get_double () == GLib.Math.cos(GLib.Math.sin(1.0)));
    });

    return Test.run ();
}
