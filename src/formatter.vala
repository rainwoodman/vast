using GLib;

public abstract class Vast.Formatter : Object
{
    /**
     * The tensor this is formatting.
     */
    public Tensor tensor { get; construct; }

    /**
     * Format the tensor into the provided {@link GLib.OutputStream}.
     */
    public abstract bool to_stream (OutputStream @out, Cancellable? cancellable = null) throws Error;

    public virtual async bool to_stream_async (OutputStream @out,
                                               int          priority    = GLib.Priority.DEFAULT,
                                               Cancellable? cancellable = null) throws Error
    {
        return to_stream (@out, cancellable);
    }
}
