using GLib;
using Math;
using Vast.Network;

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

class Operation1 : Vast.Network.Operation {
    UFuncImpl1 impl;
    public Operation1(string name, UFuncImpl1 impl)
    {
        base(name, 1, 1);
        this.impl = impl;
    }
    public override void
    prepare(Object [] inputs, Object? [] outputs)
    {
        for(var i = 0; i < this.nout; i ++) {
            if(outputs[i] != null) continue;
            outputs[i] = new Operand(0.0);
        }
    }
    public override void
    execute(Object[] inputs, Object[] outputs)
    {
        (outputs[0] as Operand).x = this.impl((inputs[0] as Operand).x);
    }
}

class Operation2 : Vast.Network.Operation {
    UFuncImpl2 impl;
    public Operation2(string name, UFuncImpl2 impl)
    {
        base(name, 2, 1);
        this.impl = impl;
    }
    public override void
    prepare(Object [] inputs, Object? [] outputs)
    {
        for(var i = 0; i < this.nout; i ++) {
            if(outputs[i] != null) continue;
            outputs[i] = new Operand(0.0);
        }
    }
    public override void
    execute(Object[] inputs, Object[] outputs)
    {
        (outputs[0] as Operand).x = this.impl(
                (inputs[0] as Operand).x,
                (inputs[1] as Operand).x);
    }
}

int main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/graph", () => {
        var osin = new Operation1("sin", Math.sin);
        var ocos = new Operation1("cos", Math.cos);
        var oatan2 = new Operation2("atan2", Math.atan2);

        var graph = new Graph();
        var X = graph.variable();
        var Y = graph.variable();
        var R1 = graph.dummy();

        graph.connect(osin, {X, R1});
        graph.connect(ocos, {R1, Y});
        message("%s", graph.to_string());
        var exec = new Executor(graph);

        exec.initialize(X, new Operand(1.0));
        var y = exec.compute({Y})[0] as Operand;
        assert (y.x == Math.cos(Math.sin(1.0)));
    });

    return Test.run ();
}
