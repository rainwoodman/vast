using GLib;

/* Let's first try a static graph */

public class Vast.Variable : Object
{
    public string name {get; construct set;}
    public bool is_dummy {get; construct set;}

    public Vast.Variable.dummy() {
        base(is_dummy : true, name : null);
    }

    public Vast.Variable(string name) {
        base(is_dummy : false, name : name);
    }
}

public class Vast.Network.Edge: Object
{
    public unowned Vast.Node src;
    public unowned Vast.Node dest;
    public Vast.Variable variable;
}

public class Vast.Network.Graph : Object
{
    public List<Vast.Network.Edge> edges;
    public List<Vast.Network.Node> nodes;

    public Node
    find_rule(Vast.Network.Variable V)
    {
        /* find the node that generates V */
    }
}

public class Vast.Network.Operation: Object
{
    public int nin {get; construct set;}
    public int nout {get; construct set;}
    public string name {get; construct set;}

    public Vast.Network.Operation (string name, int nin, int nout)
    {
        base(name : name, nin : nin, nout : nout);
    }

    public Vast.Network.Node make_node(Vast.Network.Variable [] variables)
    {
        return Node(this, variables);
    }
}

public class Vast.Network.Node: Object
{
    public Vast.Network.Operation operation;
    public unowned Vast.Network.Edge [] edges;

    public Vast.Network.Node(Vast.Network.Operation operation, Vast.Network.Variable [] variables)
    {

    }
}

public class Vast.Network.ArrayExecutor : Object
{
    public Vast.Network.Graph graph {get; construct set;}

    public HashTable<Vast.Network.Variable, Vast.Array> cache;

    construct {
        cache = new HastTable<Vast.Network.Variable, Vast.Array>();
    }

    public Vast.Network.Executor(Vast.Network.Graph graph)
    {
        base(graph : graph)
    }

    public Vast.Array []
    create_outputs(Vast.Network.Operation operation, Vast.Array [] inputs)
    {
        /* For any operation and given inputs, we shall be able to infer the output types*/
    }

    public void
    execute_node(Vast.Network.Operation operation, Vast.Array [] inputs, Vast.Array [] outputs)
    {
        /* carry out the operation */
    }

    public void initialize(Vast.Network.Variable V, Vast.Array array)
    {
        /* FIXME: is V a src of graph? If not we may want to die here */
        cache.set(V, array);
    }

    public Vast.Array [] compute(Vast.Network.Variable [] V)
    {
        /* comput the graph till all variables in V are realized and updated */
    }

}

/***
    var graph = new Graph();

    var X = graph.variable();
    var Y = graph.variable();
    var R1 = graph.variable();

    var node = graph.node("sin", {X, R1})
    var node = graph.node("cos", {R1, Y})

    var ae = new ArrayExecutor(graph);

    ae.initialize(X, new Array.from_list({0, 1, 2, 3}));

    var y = ae.compute({Y})[0];
    var x = ae.compute({X})[0];

***/
