namespace Vast {

    public errordomain IndexError {
        OUT_OF_BOUNDS,
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
                    result[i].end = array.shape[i];
                    result[i].step = 1;
                }
            }
            for(var i = 0; i < array.ndim; i ++) {
                if(result[i].start < 0) result[i].start += array.shape[i];
                if(result[i].end < 0) result[i].end == array.shape[i];
            }
            for(var i = 0; i < array.ndim; i ++) {
                if(results[i].start < 0 || results[i].start > array.shape[i]
                || results[i].end < 0 || results[i].end > array.shape[i]) {
                    throw new IndexError.OUT_OF_BOUNDS("Slices %s is out of bounds", Slice.v_to_string(result));
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
        }
    }

    public class Array : Object
    {
        public size_t ndim {get; construct; }
        public TypeDescr dtype {get; construct; }
        [CCode (has_array_length = false) ]
        public size_t [] shape {
            get {
                return _shape;
            }
            construct {
                for(var i = 0; i < this.ndim; i ++) {
                    _shape[i] = value[i];
                }
            }
        }
        [CCode (has_array_length = false) ]
        public ssize_t [] strides {
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
        public void * data {get; set; }
        public Object base {get; set; }

        construct {
            this.size = 1;
            for(var i = 0; i < ndim; i ++) {
                this.size *= this.shape[i];
            }
        }

        public Array.full(size_t ndim,
                TypeDescr dtype,
                [CCode (has_array_length = false)]
                size_t [] shape, 
                [CCode (has_array_length = false)]
                ssize_t [] strides)
        {
            base(ndim : ndim, dtype : dtype,
                shape : shape, strides : strides
                );
        }
                
        ~Array() {
            if(self.@base == null) {
                delete this.data;
            }
        }

        public Array.empty_with_strides(TypeDescr dtype, size_t [] shape, ssize_t [] strides)
        {
            this.full(shape.length, dtype, shape, strides);

            this.data = (void*) new uint8[dtype.elsize * this.size];
        }
        public Array.empty(TypeDescr dtype, size_t [] shape)
        {
            var strides = new ssize_t [shape.length];

            strides[shape.length - 1] = (ssize_t) dtype.elsize;

            for(var i = strides.length - 2; i >= 0; i --) {
                strides[i] = strides[i+1] * (ssize_t) shape[i+1];
            }
            this.empty_with_strides(dtype, shape, strides);
        }

        public new Array get(Slice [] index) throws IndexError
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

        public string to_string() {
            StringBuilder sb = new StringBuilder();
            foreach(var i in this) {
                sb.append_printf("%s ", this.dtype.format(i));
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
