public abstract class Vast.GraphExecutor : Object
{
    public Vast.Graph graph {get; construct set;}

    public GraphExecutor(Vast.Graph graph)
    {
        base (graph: graph);
    }

    /**
     * Assign a variable to be either sourced from or receive a computation.
     */
    public abstract void
    assign (Graph.Variable v, Array a) throws Error;

    public virtual async void
    assign_async (Graph.Variable v, Array a, int priority = GLib.Priority.DEFAULT, Cancellable? cancellable = null) throws Error
    {
        assign (v, a);
    }

    [CCode (array_length = false)]
    public abstract Array[]
    compute (Graph.Variable[] v, Cancellable? cancellable = null) throws Error;

    [CCode (array_length = false)]
    public virtual Array[]
    compute_async (Graph.Variable[] v, int priority = GLib.Priority.DEFAULT, Cancellable? cancellable = null) throws Error
    {
        return compute (v, cancellable);
    }
}


