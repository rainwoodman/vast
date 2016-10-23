/bin/bash: :q: command not found
        {
            var slices = (new ArrayIndexSlice(index)).indices(this);

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
            var result = new Array.full(this.ndim, this.dtype, this.shape, this.strides, data);
            result.base = this;

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
