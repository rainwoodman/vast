namespace Vast {

public class Array<ScalarType>: Object
{
    public int ndim {get; construct; }
    public size_t elsize {get; construct;}
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
                    _strides[ndim - 1] = (ssize_t) this.elsize;

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
            this.data = new int8[this.size * this.elsize];
        }
    }

    ~Array()
    {
        if(this.base == null) {
            delete data;
        }
    }

    public Array()
    {

    }

    public Array.full(int ndim, 
        [CCode (array_length=false)]
        ssize_t [] shape,
        [CCode (array_length=false)]
        ssize_t []? strides = null,
        Object ? @base = null,
        void * data = null
        )
    {

        base(ndim : ndim,
            shape : shape,
            strides : strides,
            elsize : sizeof(ScalarType),
            scalar_type : typeof(ScalarType),
            @base : @base,
            data : data
            );
    }

    public unowned ScalarType
    get_scalar(ssize_t [] index)
    {
        assert(index.length == this.ndim);
        ssize_t p = 0;
        for(var i = 0; i < this.ndim; i ++) {
            p += index[i] * this.strides[i];
        }

        return (ScalarType) (this.data + p);
    }

    public void
    set_scalar(ssize_t [] index, ScalarType val)
    {
        assert(index.length == this.ndim);
        ssize_t p = 0;
        for(var i = 0; i < this.ndim; i ++) {
            p += index[i] * this.strides[i];
        }
        /* What is the best way of doing this the vala way?
         * get triggers a dup function, but looks like there
         * is no clear way doing lvalue?*/
        Memory.copy(this.data + p, val, sizeof(ScalarType));
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
