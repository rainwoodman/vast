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
     * Number of scalars to skip for traversing each axis, immutable.
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
     * Offset to the memory location of the first element in number of scalars.
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
                strides[i - 1] = (i == dimension) ? 1 : strides[i] * (ssize_t) shape[i];
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

        assert (origin * scalar_size < data.length);

        _baseptr = (uint8*) data.get_data () + origin * scalar_size;
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
                  size_t[]  shape   = {},
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

    private static extern Bytes _bytes_new_zeroed (size_t len);

    public Array.zeroed (Type      scalar_type,
                         size_t    scalar_size,
                         size_t[]  shape   = {},
                         [CCode (array_length = false)]
                         ssize_t[] strides = {},
                         size_t    origin  = 0)
    {
        this (scalar_type,
              scalar_size,
              shape,
              strides,
              origin,
              _bytes_new_zeroed (_size_from_shape (shape) * scalar_size));
    }

    private inline size_t
    _offset_from_index ([CCode (array_length = false)] ssize_t[] index)
    {
        size_t p = 0;
        for (var i = 0; i < _dimension; i++) {
            p += (size_t) (index[i] < 0 ? _shape[i] + index[i] : index[i]) * _strides[i];
        }
        return p * _scalar_size;
    }

    public unowned void*
    get_pointer ([CCode (array_length = false)] ssize_t[] index)
    {
        return _baseptr + _offset_from_index (index);
    }

    public unowned string
    get_string ([CCode (array_length = false)] ssize_t[] index)
        requires (scalar_type == typeof (string))
    {
        return (string) (_baseptr + _offset_from_index (index));
    }

    public Value
    get_value ([CCode (array_length = false)] ssize_t[] index)
    {
        return _memory_to_value (_baseptr + _offset_from_index (index));
    }

    public Value
    get_value_as ([CCode (array_length = false)] ssize_t[] index, Type dest_type)
    {
        var dest_value = Value (dest_type);
        if (get_value (index).transform (ref dest_value)) {
            return dest_value;
        } else {
            error ("Could not transform '%s' into '%s'.", scalar_type.name (),
                                                          dest_type.name ());
        }
    }

    public void
    set_from_pointer ([CCode (array_length = false)] ssize_t[] index, void* val)
    {
        Memory.copy (_baseptr + _offset_from_index (index), val, scalar_size);
    }

    public void
    set_from_string ([CCode (array_length = false)] ssize_t[] index, string val)
        requires (scalar_type == typeof (string))
    {
        Posix.strncpy ((string) (_baseptr + _offset_from_index (index)), val, scalar_size - 1);
        *(_baseptr + _offset_from_index (index) + scalar_size) = '\0';
    }

    public void
    set_from_value ([CCode (array_length = false)] ssize_t[] index, Value val)
    {
        var val_copy = val;
        _value_to_memory (ref val_copy, _baseptr + _offset_from_index (index));
    }

    public void
    fill_from_pointer (void* ptr)
    {
        foreach (var dest_ptr in this) {
            Memory.copy (dest_ptr, ptr, _scalar_size);
        }
    }

    public void
    fill_from_value (Value val)
    {
        var ptr      = new uint8[scalar_size]; // FIXME: allocate this on the stack
        var val_copy = val;
        _value_to_memory (ref val_copy, ptr);
        fill_from_pointer (ptr);
    }

    public void
    fill_from_array (Array arr)
        requires (size <= arr.size)
    {
        var iter     = iterator ();
        var arr_iter = arr.iterator ();
        if (Value.type_compatible (arr.scalar_type, scalar_type)) {
            while (iter.next () && arr_iter.next ()) {
                iter.set_from_pointer (arr_iter.get_pointer ());
            }
        } else if (Value.type_transformable (arr.scalar_type, scalar_type)) {
            while (iter.next () && arr_iter.next ()) {
                iter.set_from_value (arr_iter.get_value ());
            }
        } else {
            error ("Could not transform '%s' into '%s'.", arr.scalar_type.name (),
                                                          scalar_type.name ());
        }
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
    broadcast_to (size_t[] new_shape)
    {
        var sb = build (new_shape.length);
        for (var i = 0; i < new_shape.length; i++) {
            sb.broadcast (i, new_shape[i]);
        }
        return sb.end ();
    }

    public Array
    redim (size_t new_dimension)
        requires (new_dimension >= dimension)
    {
        var new_shape = new size_t[new_dimension];
        Memory.copy (new_shape, shape, dimension * sizeof (size_t));
        for (var i = dimension; i < new_dimension; i++) {
            new_shape[i] = 1;
        }
        return reshape (new_shape);
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

    public Array
    view_as (Type new_scalar_type, size_t new_scalar_size)
        requires (scalar_size % new_scalar_size == 0 || new_scalar_size % scalar_size == 0)
    {
        var new_shape   = new size_t[dimension];
        var new_strides = new ssize_t[dimension];
        for (var i = 0; i < dimension; i++) {
            new_shape[i]   = (shape[i] * scalar_size) / new_scalar_size;
            new_strides[i] = (strides[i] * (ssize_t) new_scalar_size) / (ssize_t) scalar_size;
        }
        return new Array (new_scalar_type, new_scalar_size, new_shape, new_strides, origin, data);
    }

    public Builder
    build (size_t new_dimension = 0)
    {
        return new Builder(this, new_dimension == 0 ? dimension : new_dimension);
    }

    /* method that is supposed to be compatible with for Vala slicing.
     * require from <= to */
    public Array
    slice ([CCode (array_length = false)] ssize_t[] from, [CCode (array_length = false)] ssize_t[] to)
    {
        var sb = this.build();
        for (var i = 0; i < _dimension; i ++) {
            sb.slice(i, from[i], to[i]);
        }
        return sb.end();
    }

    public Array
    head ([CCode (array_length = false)] ssize_t[] to)
    {
        var sb = this.build();
        for (var i = 0; i < _dimension; i ++) {
            sb.head(i, to[i]);
        }
        return sb.end();
    }

    public Array
    tail ([CCode (array_length = false)] ssize_t[] from)
    {
        var sb = this.build();
        for (var i = 0; i < _dimension; i ++) {
            sb.tail(i, from[i]);
        }
        return sb.end();
    }

    public Array
    step ([CCode (array_length = false)] ssize_t[] steps)
    {
        var sb = this.build();

        for (var i = 0; i < _dimension; i ++) {
            sb.step(i, steps[i]);
        }
        return sb.end();
    }

    public Array
    flip (ssize_t axis = 0)
    {
        return build ().step (axis, -1).end ();
    }

    public Array
    transpose ([CCode (array_length = false)] ssize_t[]? axes = null)
    {
        var sb = this.build();

        for (var i = 0; i < _dimension; i ++) {
            sb.axis (i, (axes != null)? axes[i]: (ssize_t) ((i+1) % _dimension));
        }
        return sb.end();
    }

    public Array
    swap (ssize_t from_axis = 0, ssize_t to_axis = 1)
    {
        return build ().axis (from_axis, to_axis).axis (to_axis, from_axis).end ();
    }

    public Array
    copy ()
    {
        return new Array (scalar_type,
                          scalar_size,
                          _shape[0:dimension],
                          _strides,
                          origin,
                          new Bytes (data.get_data ()));
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
    _value_to_memory (ref Value val, void * memory)
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
    _memory_to_value (void* memory)
    {
        var val = Value (scalar_type);

        if (val.fits_pointer ()) {
            if (scalar_type == typeof (string)) {
                val.set_string ((string) memory);
            } else if (scalar_type.is_a (Type.BOXED)) {
                var tmp_val = Value (scalar_type);
                tmp_val.set_boxed (memory);
                tmp_val.copy (ref val);
            } else {
                Memory.copy (val.peek_pointer (), memory, scalar_size);
            }
        } else {
            Memory.copy (_value_get_data (ref val), memory, scalar_size);
        }

        return val;
    }

    public class Builder : Object
    {
        /* The Builder gives a syntax to create a new Array viewing
         * the current array.
         *
         * for each dimension we can use
         *
         *  this.slice(axis, step, from, to)
         *
         * it shall be idential to numpy's slice(from, to, step) indexing syntax.
         * THRU corresponds to omitted values in Python.
         * if there is a difference, consider it a bug.
         * (easier to test once with have GIR working)
         *
         * we can also reroute the axis's shape and strides to any axis in the original
         * array, or set it to a new axis (NEW_AXIS). (implement transpose, e.g.)
         *
         *  this.axis(axis, originalaxis)
         *
         * if an axis has shape[axis] == 1 or strides[axis] == 0,
         * then we can change the shape (broadcastable)
         *
         *  this.broadcast(axis, newshape)
         *
         * the final build array is built after this.end() is called.
         *
         * methods can be chained or called in a loop.
         *
         */
        public Array  array     { get; construct; }
        public size_t dimension { get; construct; }

        private size_t  shape[32];
        private ssize_t strides[32];
        private size_t  origin;

        /* bookkeeping */
        private ssize_t original_axis[32];
        private bool    removal[32];

        internal Builder(Array array, size_t dimension)
        {
            base (array: array, dimension: dimension);
        }

        construct
        {
            for (var i = 0; i < dimension; i ++) {
                shape[i]         = i < array.dimension ? array.shape[i] : 1;
                strides[i]       = i < array.dimension ? array.strides[i] : 0;
                original_axis[i] = i;
                removal[i]       = false;
            }
            origin = array.origin;
        }

        /* from:to:step */
        public Builder
        slice(ssize_t axis, ssize_t from, ssize_t to, ssize_t step=1)
        {
            return qslice(axis, from, to, step);
        }

        /* :to:step */
        public Builder
        head(ssize_t axis, ssize_t to, ssize_t step=1)
        {
            return qslice(axis, null, to, step);
        }

        /* from::step */
        public Builder
        tail(ssize_t axis, ssize_t from, ssize_t step=1)
        {
            return qslice(axis, from, null, step);
        }

        /* ::step */
        public Builder
        step(ssize_t axis, ssize_t step=1)
        {
            return qslice(axis, null, null, step);
        }

        /* [i]; the axis is marked for removeal */
        public Builder
        index(ssize_t axis, ssize_t where)
        {
            qslice(axis, where, where, 0);
            return this;
        }

        public Builder
        qslice(ssize_t axis,
            ssize_t ? qfrom = null,
            ssize_t ? qto = null,
            ssize_t step = 1)
        {
            /* if step is 0, mark the axis for removal */
            axis = wrap_by_dimension(axis);

            ssize_t from, to;
            if(qfrom == null) {
                assert (step != 0);
                if (step > 0)
                    from = 0;
                else
                    from = (ssize_t) shape[axis] - 1;
            } else {
                from = qfrom;
                from = from < 0 ? (ssize_t) shape[axis] + from : from;
            }

            if(qto == null) {
                assert (step != 0);
                if (step > 0)
                    to = (ssize_t) shape[axis];
                else
                    to = -1;
            }
            else {
                to = qto;
                to = to < 0 ? (ssize_t) shape[axis] + to   : to;
            }

            origin += from * strides[axis];

            /* XXX: hopefully this rounds down even for negative steps */
            if (step == 0) {
                assert (to == from);
                removal[axis] = true;
            } else {
                shape[axis] = (to - from) / step;
                strides[axis] *= step;
                assert (shape[axis] >= 0);
            }

            return this;
        }

        /* use original_axis for new axis, a new shape[d] == 1 axis if NEW_AXIS*/
        public Builder
        axis (ssize_t axis, ssize_t from_axis)
        {
            axis      = wrap_by_dimension (axis);
            from_axis = wrap_by_dimension (from_axis);
            if (from_axis < array.dimension) {
                shape[axis]   = array.shape[from_axis];
                strides[axis] = array.strides[from_axis];
            } else {
                shape[axis]   = 1;
                strides[axis] = 0;
            }
            original_axis[axis] = from_axis;
            return this;
        }

        public Builder
        broadcast(ssize_t axis, size_t newshape)
        {
            axis = wrap_by_dimension(axis);
            assert (shape[axis] == 1 || strides[axis] == 0 || shape[axis] == newshape);
            strides[axis] = 0;
            shape[axis] = newshape;
            return this;
        }

        public Array
        end()
        {
            /* ensure each original_axes is used only once */
            int n[32];

            /* XXX: this is dumb. how to zero initialize a vala array? */
            for(var i = 0; i < array._dimension; i ++) {
                n[i] = 0;
            }

            for(var i = 0; i < dimension; i ++) {
                var o = original_axis[i];
                if (o >= array.dimension) {
                    continue;
                }
                n[o] ++;
            }
            for(var i = 0; i < array._dimension; i ++) {
                /* each original axis shall be used at most once */
                assert (n[i] <= 1);
                /* XXX: raised error shall be informative */
            }

            /* remove axes that are marked for removal due to indexing */
            ssize_t j = 0;
            for(var i = 0; i < dimension; i ++) {
                if(removal[i]) continue;
                shape[j] = shape[i];
                strides[j] = strides[i];
                j ++;
            }

            /* the axes are reasonable - create the array. */
            return new Array (array.scalar_type,
                              array.scalar_size,
                              shape[0:j],
                              strides,
                              origin,
                              array.data);
        }

        private ssize_t wrap_by_dimension(ssize_t axis)
        {
            return (axis < 0) ? ((ssize_t) dimension + axis) : axis;
        }
    }

}
