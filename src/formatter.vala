using GLib;

public abstract class Vast.Formatter : Object
{
    /**
     * The array this is formatting.
     */
    public Array array { get; construct; }

    /**
     * Format the array into the provided {@link GLib.OutputStream}.
     */
    public abstract bool to_stream (OutputStream @out, Cancellable? cancellable = null) throws Error;

    public virtual async bool to_stream_async (OutputStream @out,
                                               int          priority    = GLib.Priority.DEFAULT,
                                               Cancellable? cancellable = null) throws Error
    {
        return to_stream (@out, cancellable);
    }
}
