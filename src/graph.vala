using GLib;

/***
    var graph = new Graph();

    var X = graph.variable();
    var Y = graph.variable();
    var R1 = graph.dummy();

    graph.connect("sin", {X, R1})
    graph.connect("cos", {R1, Y})

    var ae = new ArrayExecutor(graph);

    ae.initialize(X, new Array.from_list({0, 1, 2, 3}));

    var y = ae.compute({Y})[0];
    var x = ae.compute({X})[0];

    Branching will be handled in the nodes.

***/

public class Vast.Network.Variable : Object
{
    public string name {get; construct set;}

    /* keep the reference counts for inputs.
     * if a dummy variable has been used as many as vincount
     * during execution, then it can be eliminated from
     * cache.
     */

    public int vincount {get; internal set;}
    public int voutcount {get; internal set;}

    construct
    {
        vincount = 0;
        voutcount = 0;
    }

    public Variable.dummy()
    {
        name = "D%08p".printf((void*) this);
        base(name : name);
    }

    public Variable(string? name=null)
    {
        var name1 = name;
        if(name1 == null) {
            name1 = "V%08p".printf((void*) this);
        }
        base(name : name1);
    }
}

public class Vast.Network.Operation: Object
{
    public int nin {get; construct set;}
    public int nout {get; construct set;}
    public string name {get; construct set;}

    /* This is the symbol that we use to look up the UFunc via GIR */
    public Operation (string name,
        int nin,
        int nout)
    {
        base(name : name, nin : nin, nout : nout);
    }
}

public class Vast.Network.Node: Object
{
    public Vast.Network.Operation operation;
    public unowned Vast.Network.Variable [] vout;
    public unowned Vast.Network.Variable [] vin;

    public Node(
        /* FIXME: can we use Object(a : a) type constructor here? */
        Vast.Network.Operation operation,
        Vast.Network.Variable [] vin,
        Vast.Network.Variable [] vout
        )
    {
        this.operation = operation;
        this.vin = vin;
        this.vout = vout;
    }
}

public class Vast.Network.Graph : Object
{
    public List<Vast.Network.Node> nodes;
    public List<Vast.Network.Variable> variables;

    /* find the node that generates V */
    public Vast.Network.Node?
    find_node(Vast.Network.Variable V)
    {
        /** FIXME: exception or null? **/
        /** FIXME: this is too slow. likely need a better data structure. **/
        foreach(var node in nodes) {
            foreach(var v in node.vout) {
                if(v == V) return node;
            }
        }
        return null;
    }

    /* create a variable */
    public Vast.Network.Variable variable()
    {
        return new Vast.Network.Variable();
    }

    public Vast.Network.Variable dummy()
    {
        return new Vast.Network.Variable.dummy();
    }

    /* create a node connecting some variables */
    public new void connect(
        Vast.Network.Operation operation,
        Vast.Network.Variable [] variables)
    {
        var vin = variables[0:operation.nin];
        var vout = variables[operation.nin:operation.nin+operation.nout];

        var node = new Vast.Network.Node(operation, vin, vout);

        this.nodes.append(node);

        /* keep the reference counts for inputs. */
        foreach(var v in vin) {
            v.vincount += 1;
        }
        foreach(var v in vin) {
            v.voutcount += 1;
        }
    }
    /* check if the graph is computable */
    public bool validate()
    {
        foreach(var v in variables) {
            if(v.voutcount > 1) {
                /* a variable is used twice. This is bad. */
                continue;
            }
            if(v.voutcount == 0 && v.vincount == 0) {
                /* a unused variable, issue a warning? */
                continue;
            }
        }
        return true;
    }

    /* */
    public string tostring()
    {
        /* write something like this:

            Graph: (%P)
            Input Variables :
            Output Variables :
            Dummy Variables :
            Edges :
        */
        return "Graph";
    }
}

public class Vast.Network.ArrayExecutor : Object
{
    public Vast.Network.Graph graph {get; construct set;}

    public HashTable<Vast.Network.Variable, Vast.Array> cache;

    construct {
        cache = new HashTable<Vast.Network.Variable, Vast.Array>(direct_hash, direct_equal);
    }

    public ArrayExecutor(Vast.Network.Graph graph)
    {
        base(graph : graph);
    }

    public void
    create_outputs(Vast.Network.Operation operation,
            Vast.Array [] inputs,
            Vast.Array? [] outputs
        )
    {
        /* For any operation and given inputs, we shall be able to infer the output types*/

        /* check if the input arrays are correct */

        /* create array in outputs if the item is null */
    }

    public void
    execute_node(Vast.Network.Operation operation, Vast.Array [] inputs, Vast.Array [] outputs)
    {
        /* carry out the operation */

        /* Look up the operation via GIR */

        /* call it. */
    }

    public void initialize(Vast.Network.Variable V, Vast.Array array)
    {
        /* FIXME: is V a src of graph? If not we may want to die here */
        cache.set(V, array);
    }

    public void compute_node(Vast.Network.Node node)
    {
        /* ensure input variables are computed */
        this.compute(node.vin);

        var ai = new Vast.Array [node.vin.length];
        var ao = new Vast.Array? [node.vout.length];

        for(var i = 0; i < ai.length; i ++) {
            ai[i] = cache.get(node.vin[i]);
        }

        /* create output variables if not yet */
        for(var i = 0; i < ao.length; i ++) {
            ao[i] = cache.get(node.vout[i]);
        }
        create_outputs(node.operation, ai, ao);

        /* this will remember the output variables */
        for(var i = 0; i < ao.length; i ++) {
            cache.set(node.vout[i], ao[i]);
        }

        foreach(var v in node.vin) {
            /* FIXME: count the number of consumptions
             * most cases transients are used only once
             * but we may be able to free those with used multiple
             * times after they are done. need to count the number of
             * consumptions during * (when?) */

            if(v.voutcount == 1 && v.vincount == 1) {
                cache.remove(v);
            }
        }

        execute_node(node.operation, ai, ao);
    }


    /* compute the graph till all variables in V are realized */
    public Vast.Array [] compute(Vast.Network.Variable [] V)
    {
        var result = new Vast.Array[V.length];

        for(var i = 0; i < V.length; i ++) {
            var v = V[i];
            if(cache.contains(v)) {
                result[i] = cache.get(v);
            } else {
                var node = this.graph.find_node(v);
                compute_node(node);

                result[i] = cache.get(v);
            }
        }
        return result;
    }

}

