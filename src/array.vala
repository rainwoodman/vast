namespace Vast {

    public errordomain IndexError {
        OUT_OF_BOUNDS,
    }

    public errordomain CastError {
        UNSUPPORTED,
    }

    public class Array : Object
    {
        public int ndim {get; construct; }
        public TypeDescr dtype {get; construct; }
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
                for(var i = 0; i < this.ndim; i ++) {
                    _strides[i] = value[i];
                }
            }
        }
        size_t _shape[32];
        ssize_t _strides[32];

        public size_t size {get; construct; }
        public void * data;
        public Object base {get; set; }

        construct {
            this.size = 1;
            for(var i = 0; i < ndim; i ++) {
                this.size *= this.shape[i];
            }
        }

        public Array.full(int ndim,
                TypeDescr dtype,
                size_t * shape, 
                ssize_t * strides=null)
        {
            var astrides = new ssize_t [ndim];

            if(strides == null) {
                strides = astrides;
                if(ndim > 0) {
                    strides[ndim - 1] = (ssize_t) dtype.elsize;

                    for(var i = ndim - 2; i >= 0; i --) {
                        strides[i] = strides[i+1] * (ssize_t) shape[i+1];
                    }
                }
            }

            base(ndim : ndim, dtype : dtype,
                shape : shape, strides : strides
                );
        }
                
        ~Array() {
            if(this.@base == null) {
                delete this.data;
            }
        }

        public Array.empty(TypeDescr dtype, size_t [] shape)
        {
            this.full(shape.length, dtype, shape, null);
            this.data = (void*) new uint8[dtype.elsize * this.size];
            this.base = null;
        }

        public Array.zeros(TypeDescr dtype, size_t [] shape)
        {
            this.full(shape.length, dtype, shape, null);
            size_t bytes = dtype.elsize * this.size;
            this.data = (void*) new uint8[bytes];
            Memory.set(this.data, 0, bytes);
            this.base = null;
        }

        public Array.range(TypeDescr dtype, ssize_t start, ssize_t end, ssize_t step=1)
        {
            ssize_t size = (end - start) / step;

            message("%td", size);
            assert(size >= 0);

            size_t shape[1] = {(size_t)size};
            
            this.empty(dtype, shape);
            unowned CastFunction cast = TypeFactory.find_cast(Vast.dtype("i8"), dtype, CastStyle.UNSAFE);

            int64 i = (int64) start;

            foreach(var p in this) {
                message("%td", i);
                cast(&i, p);
                i += step;
            }
        }

        public ArrayIterator iterator()
        {
            return new ArrayIterator(this);
        }

        public Array view(Slice [] index) throws IndexError
        {
            var slices = Slice.indices(index, this);

            assert(slices.length == this.ndim);
            
            ssize_t offset = 0;
            size_t [] shape = new size_t[this.ndim];
            ssize_t [] strides = new ssize_t[this.ndim];

            for(var i = 0; i < this.ndim; i ++) {
                offset += slices[i].start * this.strides[i];
                shape[i] = (slices[i].end - slices[i].start) / slices[i].step;
                strides[i] = slices[i].step * this.strides[i];
            }

            var data = (void*) (((uint8*) this.data) + offset);
            var result = new Array.full(this.ndim, this.dtype, shape, strides);
            result.base = this;
            result.data = data;
            return result;
        }

        public Array reshape(size_t [] shape)
        {
            var result = new Array.full(shape.length, this.dtype, shape);
            /*FIXME: this is wrong if the array has non-contignous strides */
            /* we shall check if the dimensions are dense by comparing shape and strides */
            /* dense dimensions can be reshaped ?*/
            result.base = this;
            result.data = data;
            return result;
        }

        public Array transpose(int [] index)
        {
            var shape = new size_t [this.ndim];
            var strides = new ssize_t [this.ndim];
            for(var i = 0; i < this.ndim; i ++)
            {
                shape[i] = this.shape[index[i]];
                strides[i] = this.strides[index[i]];
            }
            var result = new Array.full(this.ndim, this.dtype, shape, strides);
            result.base = this;
            result.data = data;
            return result; 
        }

        public void * peek(ssize_t [] index)
        {
            assert(index.length == this.ndim);
            ssize_t offset = 0;
            for(var i = 0; i < this.ndim; i ++) {
                offset += index[i] * this.strides[i];
            }
            return (void*) (((uint8*) this.data) + offset);
        }

        public Array cast(TypeDescr dtype) throws CastError {
            unowned CastFunction cast = TypeFactory.find_cast(this.dtype, dtype);
            if(cast == null) {
                throw new CastError.UNSUPPORTED("from %s to %s is unsupported",
                            this.dtype.to_string(), dtype.to_string()
                    );
            }
            var result = new Array.empty(dtype, this._shape[0:this.ndim]);
            var i1 = this.iterator();
            var i2 = result.iterator();
            while(i1.next() && i2.next()) {
                cast(i1.get(), i2.get());
            }
            return result;
        }
        public string to_string() {
            var sb = new StringBuilder();
            sb.append("[ ");
            foreach(var p in this) {
                sb.append_printf("%s ", this.dtype.format(p));
            }
            sb.append("]");
            return sb.str;
        }
    }

    public class UFunc : Object
    {
        size_t nin;
        size_t nout;
    }
}
