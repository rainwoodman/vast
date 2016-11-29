using GLib;

public class Vast.Array : Object
{
    public Type scalar_type { get; construct; }

    public size_t scalar_size { get; construct; }

    public size_t dimension { get; construct; }

    [CCode (array_length = false)]
    private size_t[] _shape;

    public size_t* shape {
        get {
            return _shape;
        }
        construct {
            _shape = new size_t[dimension];
            Memory.copy (_shape, value, dimension * sizeof (size_t));
        }
    }

    [CCode (array_length = false)]
    ssize_t[] _strides;

    public ssize_t* strides {
        get {
            return _strides;
        }
        construct {
            _strides = new ssize_t[dimension];
            if (value == null) {
                for (var i = dimension; i > 0; i--) {
                    _strides[i - 1] = (i == dimension) ? (ssize_t) scalar_size : _strides[i] * (ssize_t) _shape[i];
                }
            } else {
                Memory.copy (_strides, value, dimension * sizeof (ssize_t));
            }
        }
    }

    public size_t origin { get; construct; default = 0; }

    public size_t size {
        get {
            size_t size = 1;
            for (var i = 0; i < dimension; i++) {
                size *= _shape[i];
            }
            return size;
        }
    }

    public Bytes data { get; construct; }

    private static inline size_t
    _size_from_shape (size_t[] shape)
    {
        size_t size = 1;
        for (var i = 0; i < shape.length; i++) {
            size *= shape[i];
        }
        return size;
    }

    public Array (Type       scalar_type,
                  size_t     scalar_size,
                  size_t[]   shape,
                  [CCode (array_length=false)]
                  ssize_t[]? strides = null,
                  Bytes?     data    = null,
                  size_t     origin  = 0)
    {
        base (scalar_type: scalar_type,
              scalar_size: scalar_size,
              dimension:   shape.length,
              shape:       shape,
              strides:     strides,
              data:        data ?? new Bytes (new uint8[scalar_size * _size_from_shape (shape)]),
              origin:      origin);
    }

    private inline size_t
    _offset_from_index ([CCode (array_length = false)] ssize_t[] index)
    {
        size_t p = origin;
        for (var i = 0; i < dimension; i++) {
            p += (size_t) (index[i] < 0 ? _shape[i] + index[i] : index[i]) * _strides[i];
        }
        return p;
    }

    public unowned void*
    get_pointer ([CCode (array_length = false)] ssize_t[] index)
    {
        return (uint8*) _data.get_data () + _offset_from_index (index);
    }

    public Value
    get_value ([CCode (array_length = false)] ssize_t[] index)
    {
        return memory_to_value(get_pointer(index), scalar_type, scalar_size);
    }

    public void
    copy_from_memory ([CCode (array_length = false)] ssize_t[] index, void* memory)
    {
        Memory.copy (get_pointer(index), memory, scalar_size);
    }

    public void
    set_value ([CCode (array_length = false)] ssize_t[] index, Value val)
    {
        value_to_memory(val, get_pointer(index), scalar_type, scalar_size);
    }

    public FlatIterator
    iterator ()
    {
        return new FlatIterator (this);
    }

    public Array
    reshape (size_t[] new_shape)
        requires (_shape == null || _size_from_shape (_shape) == _size_from_shape (new_shape))
    {
        return new Array (scalar_type,
                          scalar_size,
                          new_shape,
                          _strides, // TODO: compute proper strides
                          data,
                          origin);
    }

    private inline size_t[]
    _shape_from_slice ([CCode (array_length = false)] ssize_t[] from, [CCode (array_length = false)] ssize_t[] to)
    {
        var shape = new size_t[dimension];
        for (var i = 0; i < dimension; i++) {
            shape[i] = to[i] - from[i];
        }
        return shape;
    }

    public Array
    slice ([CCode (array_length = false)] ssize_t[] from, [CCode (array_length = false)] ssize_t[] to)
    {
        return new Array (scalar_type,
                          scalar_size,
                          _shape_from_slice (from, to),
                          _strides,
                          data,
                          _offset_from_index (from));
    }

    private inline ssize_t[] _strides_from_steps (ssize_t[] steps)
    {
        var strides = new ssize_t[dimension];
        for (var i = 0; i < dimension; i++) {
            strides[i] = _strides[i] * steps[i];
        }
        return strides;
    }

    private inline size_t[]
    _shape_from_steps (ssize_t[] steps)
    {
        var shape = new size_t[dimension];
        for (var i = 0; i < dimension; i++) {
            shape[i] = _shape[i] / steps[i]; // round down
        }
        return shape;
    }

    public Array
    step ([CCode (array_length = false)] ssize_t[] steps)
    {
        return new Array (scalar_type,
                          scalar_size,
                          _shape_from_steps (steps),
                          _strides_from_steps (steps),
                          data);
    }

    private inline size_t
    _axis_from_external_axis (ssize_t axis)
    {
        return axis < 0 ? dimension + axis : axis;
    }

    public Array
    transpose ([CCode (array_length = false)] ssize_t[]? axes = null)
    {
        var transposed_strides = new ssize_t[dimension];
        var transposed_shape   = new size_t[dimension];
        for (var i = 0; i < dimension; i++)
        {
            if (axes == null) {
                transposed_strides[i] = _strides[(i + 1) % dimension];
                transposed_shape[i]   = _shape[(i + 1) % dimension];
            } else {
                transposed_strides[i] = _strides[_axis_from_external_axis (axes[i])];
                transposed_shape[i]   = _shape[_axis_from_external_axis (axes[i])];
            }
        }
        return new Array (scalar_type, scalar_size, transposed_shape, transposed_strides, data);
    }

    public Array
    swap (ssize_t from_axis = 0, ssize_t to_axis = 1)
        requires (_axis_from_external_axis (from_axis) < dimension)
        requires (_axis_from_external_axis (to_axis)   < dimension)
    {
        var axes = new ssize_t[dimension];
        for (var i = 0; i < dimension; i++) {
            axes[i] = i; // identity
        }

        // swap dimensions
        axes[_axis_from_external_axis (from_axis)] = to_axis;
        axes[_axis_from_external_axis (to_axis)]   = from_axis;

        return transpose (axes);
    }

    public string
    to_string ()
    {
        StringBuilder sb = new StringBuilder ();
        sb.append_printf ("dtype: %s, ", scalar_type.name ());
        sb.append_printf ("dsize: %" + size_t.FORMAT + ", ", scalar_size);
        sb.append_printf ("shape: (");
        for (var i = 0; i < dimension; i++) {
            sb.append_printf ("%" + size_t.FORMAT, shape[i]);
            if (i < dimension - 1) {
                sb.append (", ");
            }
        }
        sb.append_c (')');
        sb.append_printf (", ");
        sb.append_printf ("mem: %" + size_t.FORMAT + "B", data.length);
        var @out = new MemoryOutputStream.resizable ();
        try {
            new StringFormatter (this).to_stream (@out);
        } catch (Error err) {
            error (err.message);
        }
        return sb.str + (string) @out.steal_data ();
    }

    /* inspiring another function that find the
       axes that are trivially iterable */
    bool
    is_trivially_iterable() {
        var i = dimension - 1;
        size_t expected = scalar_size;
        while(i >= 0) {
            if(_strides[i] != expected) return false;
            expected *= _shape[i];
            i--;
        }
        return true;
    }

}
