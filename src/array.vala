using GLib;

public class Vast.Array : Object
{
    /**
     * GType of the scalar elements, immutable.
     */
    public Type scalar_type { get; construct; /* implicitly typeof (void) */ }

    /**
     * Size of a scalar element in bytes, immutable.
     */
    public size_t scalar_size { get; construct; default = sizeof (void); }

    /**
     * Number of independant axes, immutable. 0 indicates a scalar array.
     */
    public size_t dimension { get; construct; default = 0; }

    private size_t  _shape[32];
    /* placeholder which will be copied in '_shape' later */
    private size_t* _shape_in;

    /**
     * Length of each axis in bytes, immutable.
     *
     * The size is given by the 'dimension' property.
     */
    public size_t* shape {
        get {
            return _shape;
        }
        construct {
            _shape_in = value;
        }
    }

    private ssize_t  _strides[32];
    /* placeholder which will be copied in '_strides' later */
    private ssize_t* _strides_in;

    /**
     * Number of bytes to skip for traversing each axis, immutable.
     *
     * The size is given by the 'dimension' property.
     */
    public ssize_t* strides {
        get {
            return _strides;
        }
        construct {
            _strides_in = value;
        }
    }

    /**
     * Number of scalar elements in the array, immutable.
     */
    public size_t size { get; private set; }

    /**
     * GObject that owns the memory buffer for storage of scalar elements.
     *
     * If 'null', it will be allocated internally.
     *
     * It is mutable although {@link GLib.Bytes} specifies that it is an
     * immutable array of bytes.
     *
     * Note that views of this array will share this {@link GLib.Bytes}
     * instance.
     */
    public Bytes? data { get; construct; default = null; }

    /* pointer to the memory location of buffer */
    private uint8* _baseptr;

    /**
     * Offset to the memory location of the first element in bytes.
     *
     * Internally, a base pointer is computed from the 'data' property.
     */
    public size_t origin { get; construct; default = 0; }

    construct {
        /* initializes the read-only attributes of the Array Object */
        assert (dimension <= 32);

        if (_shape_in == null) {
            assert (dimension == 0);
        } else {
            /* We will copy the in-values from g_object_new */
            Memory.copy (_shape, _shape_in, dimension * sizeof (size_t));
            /* the input pointers from gobject is no longer useful, void them.*/
            _shape_in = null;
        }

        if (_strides_in == null) {
            /* assume C contiguous strides */
            for (var i = dimension; i > 0; i--) {
                strides[i - 1] = (i == dimension) ? (ssize_t) scalar_size : strides[i] * (ssize_t) shape[i];
            }
        } else {
            for (var i = 0; i < dimension; i ++) {
                strides[i] = _strides_in[i];
            }
            /* the input pointers from gobject is no longer useful, void them.*/
            _strides_in = null;
        }

        /* calculate size, since it is immutable, we do it once here */
        size = 1;
        for (var i = 0; i < dimension; i ++) {
            size *= shape[i];
        }

        /* provide a default bytes object for the buffer */
        data = data ?? new Bytes (new uint8[scalar_size * size]);

        assert (origin < data.length);

        _baseptr = (uint8*) data.get_data () + origin;
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
                  size_t    origin  = 0,
                  Bytes?    data    = null)
        requires (shape.length <= 32)
        requires (scalar_size > 0)
        requires (_size_from_shape (shape) > 0)
    {
        base (scalar_type: scalar_type,
              scalar_size: scalar_size,
              dimension:   shape.length,
              shape:       shape,
              strides:     strides,
              data:        data,
              origin:      origin);
    }

    public Array.zeroed (Type      scalar_type,
                         size_t    scalar_size,
                         size_t[]  shape,
                         [CCode (array_length = false)]
                         ssize_t[] strides = {},
                         size_t    origin  = 0)
    {
        var mem    = (uint8[]) malloc0 (_size_from_shape (shape) * scalar_size);
        mem.length = (int) (_size_from_shape (shape) * scalar_size);
        this (scalar_type,
              scalar_size,
              shape,
              strides,
              origin,
              new Bytes.take (mem));
    }

    private inline size_t
    _offset_from_index ([CCode (array_length = false)] ssize_t[] index)
    {
        size_t p = 0;
        for (var i = 0; i < _dimension; i++) {
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
        return _memory_to_value (_baseptr + _offset_from_index (index));
    }

    public void
    set_pointer ([CCode (array_length = false)] ssize_t[] index, void* val)
    {
        Memory.copy (_baseptr + _offset_from_index (index), val, scalar_size);
    }

    public void
    set_value ([CCode (array_length = false)] ssize_t[] index, Value val)
    {
        _value_to_memory (val, _baseptr + _offset_from_index (index));
    }

    public void
    fill (void* ptr)
    {
        foreach (var dest_ptr in this) {
            Memory.copy (dest_ptr, ptr, _scalar_size);
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
        requires (_size_from_shape (_shape[0:dimension]) == _size_from_shape (new_shape))
    {
        return new Array (scalar_type,
                          scalar_size,
                          new_shape,
                          {},
                          origin,
                          data);
    }

    public Array
    index (ssize_t[] idx)
        requires (idx.length <= dimension)
    {
        var new_origin = origin;
        for (var i = 0; i < idx.length; i++) {
            new_origin += idx[i] * strides[i];
        }
        return new Array (scalar_type,
                          scalar_size,
                          _shape[idx.length:dimension],
                          _strides[idx.length:dimension],
                          new_origin,
                          data);
    }

    private inline size_t[]
    _shape_from_slice ([CCode (array_length = false)] ssize_t[] from, [CCode (array_length = false)] ssize_t[] to)
    {
        var ret = new size_t[dimension];
        for (var i = 0; i < dimension; i++) {
            var a = to[i] < 0 ? shape[i] + to[i] : to[i];
            var b = from[i] < 0 ? shape[i] + from[i] : from[i];
            if (a < b) {
                ret[i] = b - a;
            } else {
                ret[i] = a - b;
            }
        }
        return ret;
    }

    private inline ssize_t[]
    _strides_from_slice ([CCode (array_length = false)] ssize_t[] from, [CCode (array_length = false)] ssize_t[] to) {
        var ret = new ssize_t[dimension];
        for (var i = 0; i < dimension; i++) {
            if ((from[i] < 0 ? shape[i] + from[i] : from[i]) > (to[i] < 0 ? shape[i] + to[i] : to[i])) {
                ret[i] = -strides[i];
            } else {
                ret[i] = strides[i];
            }
        }
        return ret;
    }

    public Array
    slice ([CCode (array_length = false)] ssize_t[] from, [CCode (array_length = false)] ssize_t[] to)
    {
        return new Array (scalar_type,
                          scalar_size,
                          _shape_from_slice (from, to),
                          _strides_from_slice (from, to),
                          origin + _offset_from_index (from),
                          data);
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
            to[i] = (ssize_t) shape[i];
        }
        return slice (from, to);
    }

    private inline ssize_t[] _strides_from_steps (ssize_t[] steps)
    {
        var ret = new ssize_t[dimension];
        for (var i = 0; i < dimension; i++) {
            ret[i] = strides[i] * steps[i];
        }
        return ret;
    }

    private inline size_t[]
    _shape_from_steps (ssize_t[] steps)
    {
        var ret = new size_t[dimension];
        for (var i = 0; i < dimension; i++) {
            ret[i] = shape[i] / (steps[i] < 0 ? -steps[i] : steps[i]); // round down
        }
        return ret;
    }

    public Array
    step ([CCode (array_length = false)] ssize_t[] steps)
    {
        var new_origin = origin;
        for (var i = 0; i < dimension; i++) {
            if (steps[i] < 0) {
                new_origin += strides[i] * shape[i] - scalar_size;
            }
        }
        return new Array (scalar_type,
                          scalar_size,
                          _shape_from_steps (steps),
                          _strides_from_steps (steps),
                          new_origin,
                          data);
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
                transposed_strides[i] = strides[(i + 1) % dimension];
                transposed_shape[i]   = shape[(i + 1) % dimension];
            } else {
                transposed_strides[i] = strides[_axis_from_external_axis (axes[i])];
                transposed_shape[i]   = shape[_axis_from_external_axis (axes[i])];
            }
        }
        return new Array (scalar_type, scalar_size, transposed_shape, transposed_strides, origin, data);
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
        sb.append_printf ("size: %" + size_t.FORMAT + ", ", size);
        sb.append_printf ("mem: %" + size_t.FORMAT + "B", data == null ? 0 : data.length);
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
        var val = Value (scalar_type);

        if (val.fits_pointer ()) {
            if (scalar_type == typeof (string)) {
                val.set_string ((string) memory);
            } else {
                Memory.copy (val.peek_pointer (), memory, scalar_size);
            }
        } else {
            Memory.copy (_value_get_data (ref val), memory, scalar_size);
        }

        return val;
    }
}
