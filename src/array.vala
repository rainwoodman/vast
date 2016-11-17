namespace Vast {

public class Array<T>: Object
{
    public Type scalar_type {get; construct;}

    public size_t scalar_size {get; construct;}

    public int ndim {get; construct; }

    size_t _shape[32];

    public size_t * shape {
        get {
            return _shape;
        }
        construct {
            for(var i = 0; i < this.ndim; i ++) {
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
                if(ndim > 0) {
                    _strides[ndim - 1] = (ssize_t) this.scalar_size;

                    for(var i = ndim - 2; i >= 0; i --) {
                        _strides[i] = _strides[i+1] * (ssize_t) _shape[i+1];
                    }
                }
            } else {
                for(var i = 0; i < this.ndim; i ++) {
                    _strides[i] = value[i];
                }
            }
        }
    }

    public size_t size {
        get {
            size_t size = 1;
            for(var i = 0; i < ndim; i ++) {
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

    public Array (size_t     scalar_size,
                  size_t[]   shape,
                  [CCode (array_length=false)]
                  ssize_t[]? strides = null,
                  Bytes?     data    = null)
    {
        base(
            scalar_type : typeof(T),
            scalar_size: scalar_size,
            ndim : shape.length,
            shape : shape,
            strides : strides,
            data : data ?? new Bytes (new uint8[scalar_size * _size_from_shape (shape)])
            );
    }

    private inline size_t
    _offset_for_index ([CCode (array_length = false)] ssize_t[] index)
    {
        size_t p = 0;
        for(var i = 0; i < this.ndim; i ++) {
            p += (size_t) (index[i] < 0 ? shape[i] + index[i] : index[i]) * strides[i];
        }
        return p;
    }

    public unowned T
    get_scalar([CCode (array_length = false)] ssize_t [] index)
    {
        return (T) ((uint8*) _data.get_data () + _offset_for_index (index));
    }

    public ArrayIterator<T> iterator()
    {
        return new ArrayIterator<T>(this);
    }

    public void
    set_scalar([CCode (array_length = false)] ssize_t [] index, T val)
    {
        /* What is the best way of doing this the vala way?
         * get triggers a dup function, but looks like there
         * is no clear way doing lvalue?*/
        Memory.copy((uint8*) data.get_data () + _offset_for_index (index), val, scalar_size);
    }

    private inline size_t[]
    _shape_from_slice ([CCode (array_length = false)] ssize_t[] from, [CCode (array_length = false)] ssize_t[] to)
    {
        var shape = new size_t[ndim];
        for (int i = 0; i < ndim; i++)
        {
            shape[i] = to[i] - from[i];
        }
        return shape;
    }

    public Array<T>
    slice ([CCode (array_length = false)] ssize_t[] from, [CCode (array_length = false)] ssize_t[] to)
    {
        return new Array<T> (scalar_size,
                             _shape_from_slice (from, to),
                             _strides,
                             new Bytes.from_bytes (data, (int) _offset_for_index (from), (int) _offset_for_index (to) - _offset_for_index (from)));
    }

    private inline int _dim_from_dim (int dim)
    {
        return dim < 0 ? ndim + dim : dim;
    }

    public Array<T>
    transpose ([CCode (array_length = false)] int[]? dims = null)
    {
        var transposed_strides = new ssize_t[ndim];
        var transposed_shape   = new size_t[ndim];
        for (var i = 0; i < ndim; i++)
        {
            if (dims == null) {
                transposed_strides[i] = _strides[(i + 1) % ndim];
                transposed_shape[i]   = _shape[(i + 1) % ndim];
            } else {
                transposed_strides[i] = _strides[_dim_from_dim (dims[i])];
                transposed_shape[i]   = _shape[_dim_from_dim (dims[i])];
            }
        }
        return new Array<T> (scalar_size, transposed_shape, transposed_strides, data);
    }

    public Array<T>
    swap (int from_dim = 0, int to_dim = 1)
        requires (_dim_from_dim (from_dim) < ndim)
        requires (_dim_from_dim (to_dim)   < ndim)
    {
        var dims = new int[ndim];
        for (var i = 0; i < ndim; i++) {
            dims[i] = i; // identity
        }

        // swap dimensions
        dims[_dim_from_dim (from_dim)] = _dim_from_dim (to_dim);
        dims[_dim_from_dim (to_dim)]   = _dim_from_dim (from_dim);

        return transpose (dims);
    }

    public string
    to_string()
    {
        StringBuilder sb = new StringBuilder();
        sb.append("<Array>");
        sb.append("(");
        sb.append_printf("Type=%s,", this.scalar_type.name());
        sb.append_printf("data=%p,", _data);
        sb.append(")");
        return sb.str;
    }

}

}
