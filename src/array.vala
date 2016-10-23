namespace Vast {

    public errordomain IndexError {
        OUT_OF_BOUNDS,
    }
    public errordomain CastError {
        UNSUPPORTED,
    }
    public struct Slice {
        ssize_t start;
        ssize_t end;
        ssize_t step;
        public Slice (ssize_t start, ssize_t end, ssize_t step=1) {
            this.start = start;
            this.end = end;
            this.step = step;
        }
        public static Slice [] indices(Slice [] index, Array array) throws IndexError {
            var result = new Slice[array.ndim];
            for(var i = 0; i < array.ndim; i ++) {
                if(i < index.length)
                    result[i] = index[i];
                else
                    result[i] = Slice(0, 0, 0);
            }
            for(var i = 0; i < array.ndim; i ++) {
                if(result[i].start == 0
                && result[i].end == 0
                && result[i].step == 0) {
                    result[i].start = 0;
                    result[i].end = (ssize_t) array.shape[i];
                    result[i].step = 1;
                }
            }
            for(var i = 0; i < array.ndim; i ++) {
                if(result[i].start < 0) result[i].start += (ssize_t) array.shape[i];
                if(result[i].end < 0) result[i].end += (ssize_t) array.shape[i];
            }
            for(var i = 0; i < array.ndim; i ++) {
                if(result[i].start < 0 || result[i].start > array.shape[i]
                || result[i].end < 0 || result[i].end > array.shape[i]) {
                    throw new IndexError.OUT_OF_BOUNDS("Slices %s is out of bounds", Slice.array_to_string(result));
                }
            }
            return result;
        }

        public string to_string() {
            return "%td:%td:%td".printf(start, end, step);
        }
        public static string array_to_string(Slice [] index) {
            StringBuilder sb = new StringBuilder();
            sb.append("[");
            for(var i = 0; i < index.length; i ++) {
                sb.append(index[i].to_string());
                sb.append(", ");
            }
            sb.append("]");
            return sb.str;
        }
    }

    public class Array : Object
    {
        public size_t ndim {get; construct; }
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

        public Array.full(size_t ndim,
                TypeDescr dtype,
                size_t * shape, 
                ssize_t * strides=null)
        {
            var astrides = new ssize_t [ndim];

            if(strides == null) {
                strides = astrides;
                if(ndim > 0) {
                    strides[ndim - 1] = (ssize_t) dtype.elsize;

                    for(var i = (ssize_t) ndim - 2; i >= 0; i --) {
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

        public ArrayIterator iterator()
        {
            return new ArrayIterator(this);
        }

        public new Array get_item(Slice [] index) throws IndexError
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
            var result = new Array.full(this.ndim, this.dtype, this.shape, this.strides);
            result.base = this;
            result.data = data;
            return result;
        }

        public void * get_pointer(ssize_t [] index)
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
            message(result.size.to_string());
            var i1 = this.iterator();
            var i2 = result.iterator();
            while(!i1.ended) {
                cast(i1.get(), i2.get());
                i1.next();
                i2.next();
            }
            return result;
        }
        public string to_string() {
            var sb = new StringBuilder();
/*
            for(var i = this.iterator();!i.ended; i.next()) {
                var p = i.get();
                sb.append_printf("%s ", this.dtype.format(p));
            }
*/
            foreach(var p in this) {
                sb.append_printf("%s ", this.dtype.format(p));
            }
            return sb.str;
        }
    }

    public class ArrayIterator
    {
        public Array array;

        public ssize_t [] cursor;
        private ssize_t offset;

        public bool ended;

        public ArrayIterator(Array array)
        {
            this.array = array;
            this.cursor = new ssize_t[array.ndim];
            this.ended = false;
            this.reset();
        }

        public bool next()
        {
            ssize_t dim = (ssize_t) array.ndim - 1;
            this.cursor[dim] ++;
            while(dim >= 0 && this.cursor[dim] == array.shape[dim]) {
                this.cursor[dim] = 0;
                dim --;
                if(dim >= 0) {
                    this.cursor[dim] ++;
                } else {
                    this.ended = true;
                }
            }
            this.offset = 0;
            for(var i = 0; i < this.cursor.length; i ++) {
                this.offset += this.cursor[i] * this.array.strides[i];
            }
            return !this.ended;
        }

        public void * get() {
            return (void*) (((int8*) array.data) + offset);
        }

        public void reset()
        {
            this.ended = false;
            var zero = new ssize_t[array.ndim];
            for(var i = 0; i < zero.length; i ++) {
                zero[i] = 0;
            }
            this.move(zero);
        }

        public void move(ssize_t [] cursor)
        {
            this.offset = 0;
            for(var i = 0; i < this.cursor.length; i ++) {
                this.cursor[i] = cursor[i];
                this.offset += this.cursor[i] * this.array.strides[i];
            }
            this.ended = true; 
            for(var i = 0; i < cursor.length; i ++) {
                if(cursor[i] < array.shape[i]) {
                    this.ended = false;
                    break;
                }
            }
        }

        public bool end()
        {
            return this.ended;
        }
        
    }

    public class UFunc : GLib.Object
    {

    }
}
