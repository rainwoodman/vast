using GLib;

public class Vast.ArrayIterator : Object
{
    public Array array { get; construct; }

    [CCode (array_length = false)]
    public ssize_t [] cursor;

    private ssize_t offset;
    private bool    ended;
    private bool    started;

    public ArrayIterator (Array array)
    {
        base (array: array);
        cursor = new ssize_t[array.dimension];
        reset ();
    }

    public bool
    next ()
    {
        if (!started) {
            started = true;
            return !ended;
        }
        if (array.dimension == 0) {
            /* special case for scalar. This could have been merged with below? */
            ended = true;
            return !ended;
        }
        ssize_t dim = (ssize_t) array.dimension - 1;
        cursor[dim]++;
        while (dim >= 0 && cursor[dim] == array.shape[dim]) {
            cursor[dim] = 0;
            dim --;
            if (dim >= 0) {
                cursor[dim]++;
            } else {
                ended = true;
            }
        }
        return !ended;
    }

    public void*
    get ()
    {
        return (uint8*) array.data.get_data () + offset;
    }

    public Value
    get_value ()
    {
        return array.get_value (cursor);
    }

    public void
    set (void* val)
    {
        Memory.copy ((uint8*) array.data.get_data () + offset, val, array.scalar_size);
    }

    public void
    set_value (Value val)
    {
        array.set_value (cursor, val);
    }

    public void
    reset ()
    {
        ended   = false;
        started = false;
        var zero = new ssize_t[array.dimension];
        for (var i = 0; i < zero.length; i++) {
            zero[i] = 0;
        }
        move (zero);
    }

    public void
    move (ssize_t [] cursor)
    {
        offset = 0;
        for (var i = 0; i < cursor.length; i++) {
            cursor[i] = cursor[i];
            offset += cursor[i] * array.strides[i];
        }
        ended = false;
        for (var i = 0; i < cursor.length; i++) {
            if (cursor[i] >= array.shape[i]) {
                ended = true;
                break;
            }
        }
    }

    public bool
    end ()
    {
        return ended;
    }
}
