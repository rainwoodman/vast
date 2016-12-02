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

    /* Internal bytes that stores the array; cannot be null */
    public Bytes? data { get; construct;}
    internal uint8 * _baseptr;

    construct {
        /* provide a default buffer is nothing allocated */
        if(_data == null) {
            _data = new Bytes (new uint8[scalar_size * size]);
        } 
        _baseptr = _data.get_data();
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
        requires (shape.length > 0)
    {
        base (scalar_type: scalar_type,
              scalar_size: scalar_size,
              dimension:   shape.length,
              shape:       shape,
              strides:     strides,
              data:        data,
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
        return _baseptr + _offset_from_index (index);
    }

    public Value
    get_value ([CCode (array_length = false)] ssize_t[] index)
    {
        var _value = Value (scalar_type);

        if (scalar_type == typeof (string)) {
            _value.set_string ((string) get_pointer (index));
        }

        else if (_value.fits_pointer ()) {
            Memory.copy (_value.peek_pointer (), get_pointer (index), scalar_size);
        }

        else if (scalar_type == Type.BOXED) {
            _value.set_boxed (get_pointer (index));
        }

        else if (scalar_type == typeof (char)) {
            _value.set_char (*(char*) get_pointer (index));
        }

        else if (scalar_type == typeof (uint8)) {
            _value.set_uchar (*(uchar*) get_pointer (index));
        }

        else if (scalar_type == typeof (int64)) {
            _value.set_int64 (*(int64*) get_pointer (index));
        }

        else if (scalar_type == typeof (double)) {
            _value.set_double (*((double*) get_pointer (index)));
        }

        else {
            assert_not_reached ();
        }

        return _value;
    }

    public void
    set_pointer ([CCode (array_length = false)] ssize_t[] index, void* val)
    {
        Memory.copy (_baseptr + _offset_from_index (index), val, scalar_size);
    }

    public void
    set_value ([CCode (array_length = false)] ssize_t[] index, Value val)
    {
        var dest_value = Value (scalar_type);

        if (val.transform (ref dest_value)) {
            if (scalar_type == typeof (string)) {
                var ptr  = _baseptr + _offset_from_index (index);
                var str  = dest_value.get_string ();
                var dest = Posix.strncpy ((string) ptr, str, scalar_size - 1);
                dest.data[scalar_size - 1] = '\0';
            }

            else if (dest_value.fits_pointer ()) {
                set_pointer (index, dest_value.peek_pointer ());
            }

            else if (scalar_type == Type.BOXED) {
                set_pointer (index, dest_value.get_boxed ());
            }

            else if (scalar_type == typeof (char)) {
                var _ = dest_value.get_char ();
                set_pointer (index, (&_));
            }

            else if (scalar_type == typeof (uint8)) {
                var _ = dest_value.get_uchar ();
                set_pointer (index, (&_));
            }

            else if (scalar_type == typeof (int64)) {
                var _ = dest_value.get_int64 ();
                set_pointer (index, (&_));
            }

            else if (scalar_type == typeof (double)) {
                var _ = dest_value.get_double ();
                set_pointer (index, &_);
            }

            else {
                assert_not_reached ();
            }
        } else {
            error ("Could not transform '%s' into '%s'.", val.type ().name (),
                                                          dest_value.type ().name ());
        }
    }

    public Iterator
    iterator ()
    {
        return new Iterator (this);
    }

    public Array
    reshape (size_t[] new_shape)
        requires (new_shape.length > 0)
        requires (_shape == null || _size_from_shape (_shape[0:dimension]) == _size_from_shape (new_shape))
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
}
