using GLib;
using Vast;
using Vast.Network;

int main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/graph", () => {
        var sin = new Operation("sin", 1, 1);
        var cos = new Operation("cos", 1, 1);

        var graph = new Graph();
        var X = graph.variable();
        var Y = graph.variable();
        var R1 = graph.dummy();

        graph.connect(sin, {X, R1});
        graph.connect(cos, {R1, Y});
        message("%s", graph.to_string());
    });

    return Test.run ();
}
