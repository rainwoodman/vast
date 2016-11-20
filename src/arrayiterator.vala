using GLib;

public class Vast.ArrayIterator : Object
{
    public Array array { get; construct; }

    [CCode (array_length = false)]
    private ssize_t[] _cursor;

    public ssize_t* cursor {
        get {
            return _cursor;
        }
        construct {
            _cursor = new ssize_t[array.dimension];
            Memory.copy (_cursor, value, array.dimension * sizeof (ssize_t));
        }
    }

    private ssize_t offset  = 0;
    private bool    ended   = false;
    private bool    started = false;

    private static inline ssize_t[]
    _fill_cursor (ssize_t initial, size_t dimension)
    {
        var cursor = new ssize_t[dimension];
        for (var i = 0; i < dimension; i++) {
            cursor[i] = initial;
        }
        return cursor;
    }

    public ArrayIterator (Array array)
    {
        base (array: array, cursor: _fill_cursor (0, array.dimension));
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
        _cursor[dim]++;
        while (dim >= 0 && _cursor[dim] == array.shape[dim]) {
            cursor[dim] = 0;
            dim --;
            if (dim >= 0) {
                _cursor[dim]++;
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
        return array.get_value (_cursor);
    }

    public void
    set (void* val)
    {
        Memory.copy ((uint8*) array.data.get_data () + offset, val, array.scalar_size);
    }

    public void
    set_value (Value val)
    {
        array.set_value (_cursor, val);
    }

    public void
    reset ()
    {
        ended   = false;
        started = false;
        move (_fill_cursor (0, array.dimension));
    }

    public void
    move ([CCode (array_length = false)] ssize_t[] cursor)
    {
        offset = 0;
        for (var i = 0; i < array.dimension; i++) {
            _cursor[i] = cursor[i];
            offset += cursor[i] * array.strides[i];
        }
        ended = false;
        for (var i = 0; i < array.dimension; i++) {
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
