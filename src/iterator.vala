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

    private uint8* _baseptr;

    construct {
        _baseptr = (uint8*) array.data.get_data () - array.origin * array.scalar_size;
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
            _offset        = _offset + array.strides[i - 1] * array.scalar_size;
            if (_cursor[i - 1] < array.shape[i - 1]) {
                return true;
            } else {
                _cursor[i - 1] -= (ssize_t) array.shape[i - 1];
                _offset        -= array.shape[i - 1] * array.strides[i - 1] * array.scalar_size;
            }
        }

        // could not increment the cursor
        return false;
    }

    public unowned void*
    get ()
        requires (_cursor != null)
    {
        return _baseptr + _offset;
    }

    public unowned void*
    get_pointer ()
        requires (_cursor != null)
    {
        return _baseptr + _offset;
    }

    public Value
    get_value ()
        requires (_cursor != null)
    {
        return array._memory_to_value (_baseptr + _offset);
    }

    public Value
    get_value_as (Type dest_type)
    {
        var dest_value = Value (dest_type);
        if (get_value ().transform (ref dest_value)) {
            return dest_value;
        } else {
            error ("Could not transform '%s' into '%s'.", array.scalar_type.name (),
                                                          dest_type.name ());
        }
    }

    public void
    set_from_pointer (void* val)
        requires (_cursor != null)
    {
        Memory.copy (_baseptr + _offset, val, array.scalar_size);
    }

    public void
    set_from_value (Value val)
        requires (_cursor != null)
    {
        var val_copy = val;
        array._value_to_memory (ref val_copy, _baseptr + _offset);
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
            _offset   += destination[i] * array.strides[i] * array.scalar_size;
        }
    }
}
