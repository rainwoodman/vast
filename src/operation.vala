using GLib;

public abstract class Vast.Operation : Object
{
    public string name { get;  construct; }

    /**
     * Named arguments of this operation by position.
     */
    public string[] arguments { get; construct; }

    public abstract void
    invokev (Vast.Array[] variables) throws Error;

    public virtual void
    invokev_async (Vast.Array[] variables) throws Error
    {
        invokev (variables);
    }

    public void
    invoke_valist (va_list list) throws Error
    {
        // TODO
        var arrays = new Vast.Array[arguments.length];
        for (;;) {
            var name = list.arg<string?> ();

            if (name == null) {
                break;
            }

            var arr  = list.arg<Array?> ();

            if (arr == null) {
                error ("");
            }

            for (var i = 0; i < arguments.length; i++) {
                if (name == arguments[i]) {
                    arrays[i] = arr;
                }
            }
        }
        invokev (arrays);
    }

    public void
    invoke (...) throws Error
    {
        invoke_valist (va_list ());
    }

    public virtual Operation?
    find_partial_derivative (string out_variable, string in_variable)
    {
        return null;
    }
}
