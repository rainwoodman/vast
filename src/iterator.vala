using GLib;

public class Vast.FlatIterator : Object
{
    public Array array { get; construct; }

    [CCode (array_length = false)]
    private ssize_t[] _cursor = null;

    private size_t _offset;

    public FlatIterator (Array array)
    {
        base (array: array);
    }

    public bool
    next ()
    {
        if (_cursor == null) {
            _cursor = new ssize_t[array.dimension];
            Memory.set (_cursor, 0, array.dimension * sizeof (ssize_t));
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
    {
        return (uint8*) array.data.get_data () + _offset;
    }

    public Value
    get_value ()
    {
        return memory_to_value(get(), array.scalar_type, array.scalar_size);
    }

    public void
    set (void* memory)
    {
        Memory.copy (get(), memory, array.scalar_size);
    }

    void
    set_value (Value val)
    {
        value_to_memory(val, get(), array.scalar_type, array.scalar_size);
    }


    private void
    reset ()
    {
        _cursor = null;
    }

}
