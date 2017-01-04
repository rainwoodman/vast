using GLib;
using Math;
using Vast;

class Operand: Object {
    public double x;
    public Operand(double x) {
        this.x = x;
    }
}

[CCode (has_target=false)]
delegate double UFuncImpl1(double x);

[CCode (has_target=false)]
delegate double UFuncImpl2(double x, double y);

class Operation1 : Vast.Operation {
    private UFuncImpl1 impl;
    public Operation1(string name, UFuncImpl1 impl)
    {
        string[] arguments = {"x", "y"};
        Object (name: name, arguments: arguments);
        this.impl = impl;
    }

    public override void
    invokev (Vast.Array[] arrays)
    {
        arrays[2].set_from_value ({}, impl (arrays[0].get_value ({}).get_double ()));
    }
}

class Operation2 : Vast.Operation {
    UFuncImpl2 impl;
    public Operation2(string name, UFuncImpl2 impl)
    {
        string[] arguments = {"x", "y"};
        Object (name: name, arguments: arguments);
        this.impl = impl;
    }

    public override void
    invokev (Vast.Array[] arrays)
    {
        arrays[2].set_from_value ({}, impl (arrays[0].get_value ({}).get_double (), arrays[1].get_value ({}).get_double ()));
    }
}

int main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/graph", () => {
        var osin = new Operation1("sin", GLib.Math.sin);
        var ocos = new Operation1("cos", GLib.Math.cos);
        var oatan2 = new Operation2("atan2", GLib.Math.atan2);

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
