namespace Vast {

    public class ArrayIterator
    {
        public Array array;

        public ssize_t [] cursor;
        private ssize_t offset;

        public bool ended;
        private bool started;
        public ArrayIterator(Array array)
        {
            this.array = array;
            this.cursor = new ssize_t[array.ndim];
            this.reset();
        }

        public bool next()
        {
            if(! this.started) {
                this.started = true;
                return !this.ended;
            }
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
            this.started = false;
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



}
