namespace Vast {

public class Array<ScalarType>: Object
{
    public int ndim {get; construct; }
    public size_t scalar_size {get; construct;}
    public Type scalar_type {get; construct;}

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
    size_t _shape[32];
    ssize_t _strides[32];

    public size_t size {get; construct; }
    public int8 * data {get; construct; }
    public Object? base {get; set; }

    construct
    {
        this.size = 1;
        for(var i = 0; i < ndim; i ++) {
            this.size *= this.shape[i];
        }

        if(this.base == null && this.data == null) {
            this.data = new int8[this.size * this.scalar_size];
        }
    }

    ~Array()
    {
        if(this.base == null) {
            delete data;
        }
    }

    public Array(size_t scalar_size, size_t[] shape)
    {
        base (scalar_size: scalar_size, ndim: shape.length, shape: shape, strides: null);
    }

    public Array.full(size_t scalar_size,
        size_t [] shape,
        [CCode (array_length=false)]
        ssize_t []? strides = null,
        Object ? @base = null,
        void * data = null
        )
    {

        base(
            scalar_size: scalar_size,
            scalar_type : typeof(ScalarType),
            ndim : shape.length,
            shape : shape,
            strides : strides,
            @base : @base,
            data : data
            );
    }

    private inline size_t _offset_for_index (ssize_t[] index)
        requires (index.length == ndim)
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
        return (ScalarType) (this.data + _offset_for_index (index));
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
        Memory.copy(this.data + _offset_for_index (index), val, sizeof(ScalarType));
    }

    public string
    to_string()
    {
        StringBuilder sb = new StringBuilder();
        sb.append("<Array>");
        sb.append("(");
        sb.append_printf("Type=%s,", this.scalar_type.name());
        sb.append_printf("base=%p,", this.@base);
        sb.append_printf("data=%p,", this.data);
        sb.append(")");
        return sb.str;
    }

}

}
