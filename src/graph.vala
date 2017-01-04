using GLib;

/***
    var graph = new Graph();

    var X = graph.variable();
    var Y = graph.variable();
    var R1 = graph.dummy();

    graph.connect("sin", {X, R1})
    graph.connect("cos", {R1, Y})

    var ae = new ArrayExecutor(graph);

    ae.assign (X, new Array.from_list({0, 1, 2, 3}));

    var y = ae.compute({Y})[0];
    var x = ae.compute({X})[0];

    Branching will be handled in the nodes.

***/

public class Vast.Graph : Object
{
    private GenericSet<Node?> nodes;

    private GenericSet<Variable?> variables;

    construct
    {
        nodes     = new GenericSet<Node?> (direct_hash, direct_equal);
        variables = new GenericSet<Variable?> (variable_hash, variable_equal);
    }

    /* find the node that generates V */
    public Node?
    find_node (Vast.Graph.Variable V)
        requires (variables.contains (V))
        requires (Variable.Direction.OUT in V.direction)
    {
        /** FIXME: exception or null? **/
        /** FIXME: this is too slow. likely need a better data structure. **/
        foreach(var node in nodes) {
            foreach (var variable in node.variables) {
                if (variable_equal (variable, V)) {
                    return node;
                }
            }
        }
        return null;
    }

    /* create a variable */
    public Vast.Graph.Variable
    create_variable(Variable.Direction direction)
    {
        Variable v;
        variables.add (v = new Vast.Graph.Variable (direction));
        return v;
    }

    /* create a node connecting some variables */
    public new void
    connectv (Vast.Operation operation, Variable[] variables)
        requires (operation.arguments.length == operation.arguments.length)
    {
        // var vin = variables[0:operation.nin];
        // var vout = variables[operation.nin:operation.nin+operation.nout];

        var _variables = new SList<Variable> ();

        foreach (var v in variables) {
            _variables.append (v);
        }

        nodes.add (new Node (operation, (owned) _variables));

        /* keep the reference counts for inputs. */
        /*
        foreach(var v in vin) {
            //v.vincount += 1;
        }
        foreach(var v in vout) {
            //v.voutcount += 1;
        }
        */
    }

    public void
    connect_valist (Operation operation, va_list list)
    {
        var variables = new Variable[operation.arguments.length];

        for (;;) {
            var name = list.arg<string?> ();
            if (name == null) {
                break;
            }

            var v = list.arg<Variable?> ();
            if (v == null) {
                error ("No variable associated to name '%s'.", name);
            }

            for (var i = 0; i < operation.arguments.length; i++) {
                if (operation.arguments[i] == name) {
                    variables[i] = v;
                }
            }
        }

        connectv (operation, variables);
    }

    /**
     * Connect an operation to a set of named variables.
     */
    public new void
    connect (Operation operation, ...)
    {
        connect_valist (operation, va_list ());
    }

    /* check if the graph is computable */
    public bool validate()
    {
        foreach (var v in variables) {
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
    public
    string to_string()
    {
        var sb = new StringBuilder();
        sb.append_printf("Graph (0x%p)\n", this);
        sb.append("Variables:\n");
        foreach (var v in variables) {
            sb.append_printf("%s\n", v.to_string());
        }
        sb.append("Nodes:\n");
        foreach(var node in nodes) {
            sb.append_printf("%s\n", node.to_string());
        }
        return sb.str;
    }

    public class Node: Object
    {
        public Operation operation { get; construct; }

        public SList<Variable> variables { get; owned construct; }

        public Node (Operation operation, owned SList<Variable> variables)
        {
            base (operation: operation);
            _variables = (owned) variables; // FIXME: this is likely a bug in the Vala compiler
        }

        public string
        to_string()
        {
            var sb = new StringBuilder ();
            sb.append_printf ("%s\t(", operation.name);
            var i = 0;
            for (unowned SList<Variable> node = variables; node != null; node = node.next) {
                sb.append_printf ("%s:\t%s", operation.arguments[i++], node.data.to_string ());
                if (node.next != null) {
                    sb.append (", \n\t ");
                }
            }
            sb.append_c (')');
            return sb.str;
        }
    }

    /* quickly hash by reusing UUID entropy */
    public static uint
    variable_hash (Variable? a)
    {
        return (uint32) a._id[0:8] ^ (uint32) a._id[8:16];
    }

    /* quickly check for equalty by comparing UUID 128 bit integers */
    public static bool
    variable_equal (Variable? a, Variable? b)
    {
        return (uint64) a._id[0:8]  == (uint64) b._id[0:8] &&
               (uint64) a._id[8:16] == (uint64) b._id[8:16];
    }

    public class Variable : Object
    {
        [Flags]
        public enum Direction {
            IN,
            OUT,
            INOUT = IN | OUT;
            public string
            to_string ()
            {
                return "%s%s".printf (IN in this ? "in" : "", OUT in this ? "out" : "");
            }
        }

        internal uint8 _id[16];
        private  char  _unparsed_id[37];

        public string name {
            get { return (string) _unparsed_id; }
        }

        public Direction direction { get; construct; }

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

        public Variable(Direction direction)
        {
            base (direction: direction);
        }

        public string
        to_string()
        {
            return "%s\t%s".printf (direction.to_string (), name);
        }
    }
}
