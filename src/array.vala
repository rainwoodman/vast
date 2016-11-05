namespace Vast {

public class Array<ScalarType>: Object
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

    private bool _is_view;

    private int8 * _data;

    public int8 * data {
        get {
            return _data;
        }
        construct {
            if (value == null) {
                _data = new int8[this.size * this.scalar_size];
                _is_view = false;
            } else {
                _data    = value;
                _is_view = true;
            }
        }
    }

    ~Array()
    {
        if (!_is_view) {
            delete data;
        }
    }

    public Array (size_t     scalar_size,
                  size_t[]   shape,
                  [CCode (array_length=false)]
                  ssize_t[]? strides = null,
                  void*      data    = null)
    {
        base(
            scalar_type : typeof(ScalarType),
            scalar_size: scalar_size,
            ndim : shape.length,
            shape : shape,
            strides : strides,
            data : data
            );
    }

    private inline size_t
    _offset_for_index (ssize_t[] index) requires (index.length == ndim)
    {
        size_t p = 0;
        for(var i = 0; i < this.ndim; i ++) {
            p += (size_t) (index[i] < 0 ? shape[i] + index[i] : index[i]) * strides[i];
        }
        return p;
    }

    public unowned ScalarType
    get_scalar(ssize_t [] index)
    {
        return (ScalarType) (_data + _offset_for_index (index));
    }

    public ArrayIterator<ScalarType> iterator()
    {
        return new ArrayIterator<ScalarType>(this);
    }

    public void
    set_scalar(ssize_t [] index, ScalarType val)
    {
        /* What is the best way of doing this the vala way?
         * get triggers a dup function, but looks like there
         * is no clear way doing lvalue?*/
        Memory.copy(_data + _offset_for_index (index), val, scalar_size);
    }

    public string
    to_string()
    {
        StringBuilder sb = new StringBuilder();
        sb.append("<Array>");
        sb.append("(");
        sb.append_printf("Type=%s,", this.scalar_type.name());
        sb.append_printf ("is_view=%s,", this._is_view ? "yes" : "no");
        sb.append_printf("data=%p,", _data);
        sb.append(")");
        return sb.str;
    }

}

}
