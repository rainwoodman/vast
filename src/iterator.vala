using GLib;

public class Vast.Iterator : Object
{
    public Array array { get; construct; }

    [CCode (array_length = false)]
    private ssize_t[] _cursor = null;

    public ssize_t* cursor {
        get {
            return _cursor;
        }
    }

    private size_t _offset;

    public size_t offset {
        get { return _offset; }
    }

    public Iterator (Array array)
    {
        base (array: array);
    }

    public bool
    next ()
    {
        if (_cursor == null) {
            /*
             * For scalar-like array, we cannot use an empty '_cursor' as it
             * would be interpreted as 'null', thus we create a phony one.
             */
            _cursor = new ssize_t[array.dimension.clamp (1, size_t.MAX)];
            Memory.set (_cursor, 0, array.dimension.clamp (1, size_t.MAX) * sizeof (ssize_t));
            _offset = 0;
            return true;
        }

        for (var i = array.dimension; i > 0; i--) {
            _cursor[i - 1] = _cursor[i - 1] + 1;
            _offset        = _offset + array.strides[i - 1];
            if (_cursor[i - 1] < array.shape[i - 1]) {
                return true;
            } else {
                _cursor[i - 1] -= (ssize_t) array.shape[i - 1];
                _offset        -= array.shape[i - 1] * array.strides[i - 1];
            }
        }

        // could not increment the cursor
        return false;
    }

    public unowned void*
    get ()
        requires (_cursor != null)
    {
        return (uint8*) array.data.get_data () + _offset;
    }

    public Value
    get_value ()
    {
        return array.get_value (_cursor);
    }

    public void
    set (void* val)
        requires (_cursor != null)
    {
        Memory.copy ((uint8*) array.data.get_data () + _offset, val, array.scalar_size);
    }

    public void
    set_value (Value val)
    {
        array.set_value (_cursor, val);
    }

    public void
    reset ()
    {
        _cursor = null;
    }

    public void
    move ([CCode (array_length = false)] ssize_t[] destination)
    {
        if (_cursor == null) {
            _cursor = new ssize_t[array.dimension];
        }
        _offset = 0;
        for (var i = 0; i < array.dimension; i++) {
            _cursor[i] = destination[i];
            _offset   += destination[i] * array.strides[i];
        }
    }
}
