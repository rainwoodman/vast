namespace Vast {

public class Array : Object
{
    public Type scalar_type {get; construct;}

    public size_t scalar_size {get; construct;}

    public size_t dimension {get; construct; }

    size_t _shape[32];

    public size_t * shape {
        get {
            return _shape;
        }
        construct {
            for(var i = 0; i < this.dimension; i ++) {
                _shape[i] = value[i];
            }
        }
    }

    ssize_t _strides[32];

    public ssize_t * strides {
        get {
            return _strides;
        }
        construct {
            if(value == null) {
                if(dimension > 0) {
                    _strides[dimension - 1] = (ssize_t) this.scalar_size;

                    for(ssize_t i = (ssize_t) dimension - 2; i >= 0; i --) {
                        _strides[i] = _strides[i+1] * (ssize_t) _shape[i+1];
                    }
                }
            } else {
                for(var i = 0; i < this.dimension; i ++) {
                    _strides[i] = value[i];
                }
            }
        }
    }

    public size_t size {
        get {
            size_t size = 1;
            for(var i = 0; i < dimension; i ++) {
                size *= this.shape[i];
            }
            return size;
        }
    }

    public Bytes data { get; construct; }

    private static inline size_t
    _size_from_shape (size_t[] shape)
    {
        size_t size = 1;
        for(var i = 0; i < shape.length; i ++) {
            size *= shape[i];
        }
        return size;
    }

    public Array (Type       scalar_type,
                  size_t     scalar_size,
                  size_t[]   shape,
                  [CCode (array_length=false)]
                  ssize_t[]? strides = null,
                  Bytes?     data    = null)
    {
        base (scalar_type: scalar_type,
              scalar_size: scalar_size,
              dimension:   shape.length,
              shape:       shape,
              strides:     strides,
              data:        data ?? new Bytes (new uint8[scalar_size * _size_from_shape (shape)]));
    }

    private inline size_t
    _offset_from_index ([CCode (array_length = false)] ssize_t[] index)
    {
        size_t p = 0;
        for(var i = 0; i < this.dimension; i ++) {
            p += (size_t) (index[i] < 0 ? shape[i] + index[i] : index[i]) * strides[i];
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

    public ArrayIterator iterator()
    {
        return new ArrayIterator(this);
    }

    public void
    set_pointer ([CCode (array_length = false)] ssize_t[] index, void* val)
    {
        /* What is the best way of doing this the vala way?
         * get triggers a dup function, but looks like there
         * is no clear way doing lvalue?*/
        Memory.copy((uint8*) data.get_data () + _offset_from_index (index), val, scalar_size);
    }

    public void
    set_value ([CCode (array_length = false)] ssize_t[] index, Value val)
    {
        var dest_value = Value (scalar_type);

        if (val.transform (ref dest_value)) {
            if (scalar_type == typeof (string)) {
                set_pointer (index, val.get_string ());
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

    private inline size_t[]
    _shape_from_slice ([CCode (array_length = false)] ssize_t[] from, [CCode (array_length = false)] ssize_t[] to)
    {
        var shape = new size_t[dimension];
        for (var i = 0; i < dimension; i++)
        {
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
                          new Bytes.from_bytes (data, (int) _offset_from_index (from), (int) _offset_from_index (to) - _offset_from_index (from)));
    }

    private inline ssize_t[] _strides_from_steps (ssize_t[] steps)
    {
        var strides = new ssize_t[dimension];
        for (var i = 0; i < dimension; i++) {
            strides[i] = _strides[i] * steps[i];
        }
        return strides;
    }

    private inline size_t[] _shape_from_steps (ssize_t[] steps)
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

    private inline size_t _axis_from_external_axis (ssize_t axis)
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
    to_string()
    {
        StringBuilder sb = new StringBuilder();
        sb.append_printf("dtype: %s, ", scalar_type.name ());
        sb.append_printf("dsize: %" + size_t.FORMAT + ", ", scalar_size);
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
        return (string) @out.steal_data ();
    }

}

}
