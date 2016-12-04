using GLib;

public class Vast.Array : Object
{
    public Type scalar_type { get; construct; }

    public size_t scalar_size { get; construct; default = sizeof (void); }

    public size_t dimension { get; construct; default = 0; }

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

    private          Bytes   _data;
    internal unowned uint8* _cached_data;

    public Bytes? data {
        get
        {
            return _data;
        }
        construct {
            _data        = value;
            if (value != null) {
                _cached_data = value.get_data ();
            }
        }
    }

    private static inline size_t
    _size_from_shape (size_t[] shape)
    {
        size_t size = 1;
        for (var i = 0; i < shape.length; i++) {
            size *= shape[i];
        }
        return size;
    }

    public Array (Type      scalar_type,
                  size_t    scalar_size,
                  size_t[]  shape,
                  [CCode (array_length = false)]
                  ssize_t[] strides = {},
                  Bytes?    data    = null,
                  size_t    origin  = 0)
        requires (scalar_size > 0)
        requires (_size_from_shape (shape) > 0)
    {
        base (scalar_type: scalar_type,
              scalar_size: scalar_size,
              dimension:   shape.length,
              shape:       shape,
              strides:     strides,
              data:        data ?? new Bytes (new uint8[scalar_size * _size_from_shape(shape)]),
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
        return _cached_data + _offset_from_index (index);
    }

    public Value
    get_value ([CCode (array_length = false)] ssize_t[] index)
    {
        return _memory_to_value (_cached_data + _offset_from_index (index));
    }

    public void
    set_pointer ([CCode (array_length = false)] ssize_t[] index, void* val)
    {
        Memory.copy (_cached_data + _offset_from_index (index), val, scalar_size);
    }

    public void
    set_value ([CCode (array_length = false)] ssize_t[] index, Value val)
    {
        _value_to_memory (val, _cached_data + _offset_from_index (index));
    }

    public void
    fill (void* ptr)
    {
        foreach (var dest_ptr in this) {
            Memory.copy (dest_ptr, ptr, scalar_size);
        }
    }

    public void
    fill_value (Value val)
    {
        var ptr = new uint8[scalar_size]; // FIXME: allocate this on the stack
        _value_to_memory (val, ptr);
        fill (ptr);
    }

    public Iterator
    iterator ()
    {
        return new Iterator (this);
    }

    public Array
    reshape (size_t[] new_shape)
        requires (_data == null || _size_from_shape (_shape[0:dimension]) == _size_from_shape (new_shape))
    {
        return new Array (scalar_type,
                          scalar_size,
                          new_shape,
                          {},
                          data,
                          origin);
    }

    private inline size_t[]
    _shape_from_slice ([CCode (array_length = false)] ssize_t[] from, [CCode (array_length = false)] ssize_t[] to)
    {
        var shape = new size_t[dimension];
        for (var i = 0; i < dimension; i++) {
            var a = to[i] < 0 ? _shape[i] + to[i] : to[i];
            var b = from[i] < 0 ? _shape[i] + from[i] : from[i];
            if (a < b) {
                shape[i] = b - a;
            } else {
                shape[i] = a - b;
            }
        }
        return shape;
    }

    private inline ssize_t[]
    _strides_from_slice ([CCode (array_length = false)] ssize_t[] from, [CCode (array_length = false)] ssize_t[] to) {
        var strides = new ssize_t[dimension];
        for (var i = 0; i < dimension; i++) {
            if ((from[i] < 0 ? _shape[i] + from[i] : from[i]) > (to[i] < 0 ? _shape[i] + to[i] : to[i])) {
                strides[i] = -_strides[i];
            } else {
                strides[i] = _strides[i];
            }
        }
        return strides;
    }

    public Array
    slice ([CCode (array_length = false)] ssize_t[] from, [CCode (array_length = false)] ssize_t[] to)
    {
        return new Array (scalar_type,
                          scalar_size,
                          _shape_from_slice (from, to),
                          _strides_from_slice (from, to),
                          data,
                          _offset_from_index (from));
    }

    private inline ssize_t[]
    _fill_index (ssize_t val)
    {
        var index = new ssize_t[dimension];
        for (var i = 0; i < dimension; i++) {
            index[i] = val;
        }
        return index;
    }

    public Array
    head ([CCode (array_length = false)] ssize_t[] to)
    {
        return slice (_fill_index (0), to);
    }

    public Array
    tail ([CCode (array_length = false)] ssize_t[] from)
    {
        var to = new ssize_t[dimension];
        for (var i = 0; i < dimension; i++) {
            to[i] = (ssize_t) _shape[i];
        }
        return slice (from, to);
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
            shape[i] = _shape[i] / (steps[i] < 0 ? -steps[i] : steps[i]); // round down
        }
        return shape;
    }

    public Array
    step ([CCode (array_length = false)] ssize_t[] steps)
    {
        var new_origin = origin;
        for (var i = 0; i < dimension; i++) {
            if (steps[i] < 0) {
                new_origin += _strides[i] * _shape[i] - scalar_size;
            }
        }
        return new Array (scalar_type,
                          scalar_size,
                          _shape_from_steps (steps),
                          _strides_from_steps (steps),
                          data,
                          new_origin);
    }

    private inline size_t
    _axis_from_external_axis (ssize_t axis)
    {
        return axis < 0 ? dimension + axis : axis;
    }

    public Array
    flip (ssize_t axis = 0)
    {
        var steps = _fill_index (1);
        steps[_axis_from_external_axis (axis)] = -1;
        return step (steps);
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
        return new Array (scalar_type, scalar_size, transposed_shape, transposed_strides, data, origin);
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
        sb.append_printf ("dimension: %" + size_t.FORMAT + ", ", dimension);
        sb.append_printf ("shape: (");
        for (var i = 0; i < dimension; i++) {
            sb.append_printf ("%" + size_t.FORMAT, shape[i]);
            if (i < dimension - 1) {
                sb.append (", ");
            }
        }
        sb.append ("), ");
        sb.append_printf ("strides: (");
        for (var i = 0; i < dimension; i++) {
            sb.append_printf ("%" + ssize_t.FORMAT, strides[i]);
            if (i < dimension - 1) {
                sb.append (", ");
            }
        }
        sb.append ("), ");
        sb.append_printf ("mem: %" + size_t.FORMAT + "B", _data == null ? 0 : _data.length);
        if (dimension == 0) {
            return sb.str;
        }
        var @out = new MemoryOutputStream.resizable ();
        try {
            new StringFormatter (this).to_stream (@out);
        } catch (Error err) {
            error (err.message);
        }
        return sb.str + (string) @out.steal_data ();
    }

    private extern static unowned void* _value_get_data (ref Value val);

    internal inline void
    _value_to_memory (Value val, void * memory)
    {
        var dest_value = Value (scalar_type);
        if (val.transform (ref dest_value)) {
            if (dest_value.fits_pointer ()) {
                if (scalar_type == typeof (string)) {
                    var dest = Posix.strncpy ((string) memory, dest_value.get_string (), scalar_size - 1);
                    dest.data[scalar_size - 1] = '\0';
                } else {
                    Memory.copy (memory, dest_value.peek_pointer (), scalar_size);
                }
            } else {
                Memory.copy (memory, _value_get_data (ref dest_value), scalar_size);
            }
        } else {
            error ("Could not transform '%s' into '%s'.", val.type ().name (),
                                                          dest_value.type ().name ());
        }
    }

    internal inline Value
    _memory_to_value (void * memory)
    {
        var _value = Value (scalar_type);

        if (_value.fits_pointer ()) {
            if (scalar_type == typeof (string)) {
                _value.set_string ((string) memory);
            } else {
                Memory.copy (_value.peek_pointer (), memory, scalar_size);
            }
        } else {
            Memory.copy (_value_get_data (ref _value), memory, scalar_size);
        }

        return _value;
    }
}
