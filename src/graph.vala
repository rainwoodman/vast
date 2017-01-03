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
    internal uint8 _id[16];
    private  char  _unparsed_id[37];

    public string name {
        get { return (string) _unparsed_id; }
    }

    /* keep the reference counts for inputs.
     * if a dummy variable has been used as many as vincount
     * during execution, then it can be eliminated from
     * cache.
     */

    public int vincount {get; internal set;}
    public int voutcount {get; internal set;}

    construct
    {
        UUID.generate (_id);
        UUID.unparse (_id, _unparsed_id);
        vincount = 0;
        voutcount = 0;
    }

    public Variable.dummy()
    {
    }

    public Variable()
    {
    }
    public string to_string()
    {
        var type = "unknown";
        if(vincount == voutcount) {
            type = "dummy";
        }
        if(vincount == 0) {
            type = "output";
        }
        if(voutcount == 0) {
            type = "output";
        }
        return "%s:%s(as vin %d, as vout %d)".printf(
                name, type, vincount, voutcount);
    }
}

public abstract class Vast.Network.Operation : Object
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

    public abstract void
    prepare(Object [] inputs,
            Object? [] outputs);
        /* For any operation and given inputs, we shall be able to infer the output types*/

        /* check if the input arrays are correct */

        /* create array in outputs if the item is null */

    public abstract void
    execute(Object[] inputs, Object[] outputs);
        /* carry out the operation */

        /* Look up the operation via GIR */

        /* call it. */
}

public class Vast.Network.Node: Object
{
    public Vast.Network.Operation operation;
    public Vast.Network.Variable [] vout;
    public Vast.Network.Variable [] vin;

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

    public string
    to_string()
    {
        var sb = new StringBuilder();
        foreach(var v in vout) {
            sb.append_printf("%s, ", v.name);
        }
        sb.append_printf("= %s (", operation.name);
        foreach(var v in vin) {
            sb.append_printf("%s, ", v.name);
        }
        sb.append_printf(")");
        return sb.str;
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
        var v = new Vast.Network.Variable();
        this.variables.append(v);
        return v;
    }

    public Vast.Network.Variable dummy()
    {
        var v = new Vast.Network.Variable.dummy();
        this.variables.append(v);
        return v;
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
        foreach(var v in vout) {
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
    public string to_string()
    {
        var sb = new StringBuilder();
        sb.append_printf("Graph (0x%p)\n", this);
        sb.append("Variables:\n");
        foreach(var v in variables) {
            sb.append_printf("%s\n", v.to_string());
        }
        sb.append("Nodes:\n");
        foreach(var node in nodes) {
            sb.append_printf("%s\n", node.to_string());
        }
        return sb.str;
    }
}

public class Vast.Network.Executor : Object
{
    public Vast.Network.Graph graph {get; construct set;}

    public HashTable<Vast.Network.Variable, Object> cache;

    construct {
        cache = new HashTable<Vast.Network.Variable, Object>(direct_hash, direct_equal);
    }

    public Executor(Vast.Network.Graph graph)
    {
        base(graph : graph);
    }

    public void initialize(Vast.Network.Variable V, Object array)
    {
        /* FIXME: is V a src of graph? If not we may want to die here */
        cache.set(V, array);
    }

    public void compute_node(Vast.Network.Node node)
    {
        /* ensure input variables are computed */
        this.compute(node.vin);

        var ai = new Object [node.vin.length];
        var ao = new Object? [node.vout.length];

        for(var i = 0; i < ai.length; i ++) {
            ai[i] = cache.get(node.vin[i]);
        }

        /* create output variables if not yet */
        for(var i = 0; i < ao.length; i ++) {
            ao[i] = cache.get(node.vout[i]);
        }
        node.operation.prepare(ai,  ao);

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

        node.operation.execute(ai, ao);
    }


    /* compute the graph till all variables in V are realized */
    public Object [] compute(Vast.Network.Variable [] V)
    {
        var result = new Object[V.length];

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

