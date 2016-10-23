namespace Vast {
    public struct Slice {
        ssize_t start;
        ssize_t end;
        ssize_t step;
        bool has_end;
        bool has_start;

        public Slice (ssize_t start, ssize_t end, ssize_t step=1) {
            this.start = start;
            this.end = end;
            this.step = step;
            this.has_end = true;
            this.has_start = true;
        }

        /* [:end:step] */
        public Slice.till (ssize_t end, ssize_t step=1) {
            this.start = 0;
            this.end = end;
            this.step = step;
            this.has_end = true;
            this.has_start = false;
        }

        /* [start::step] */
        public Slice.from (ssize_t start, ssize_t step=1) {
            this.start = start;
            this.end = 0;
            this.step = step;
            this.has_end = false;
            this.has_start = true;
        }
        /* [::step] */
        public Slice.every (ssize_t step=1) {
            this.start = 0;
            this.end = 0;
            this.step = step;
            this.has_end = false;
            this.has_start = false;
        }

        public bool check(size_t shape) {
            if(has_start) {
                if(start < 0) return false;
                if(start > shape) return false;
            }
            if(has_end) {
                if(end < 0) return false;
                if(end > shape) return false;
            }
            return true;
        }

        public void wrap(size_t shape) {
            if(has_start) {
                if(start < 0) start += (ssize_t) shape;
            } else {
                if(step > 0)
                    start = 0;
                else
                    start = (ssize_t) shape - 1;
            }
            if(has_end) {
                if(end < 0) end += (ssize_t) shape;
            } else {
                if(step > 0)
                    end = (ssize_t) shape;
                else
                    end = -1;
            }
        }

        public static Slice [] indices(Slice [] index, Array array) throws IndexError {
            var result = new Slice[array.ndim];
            for(var i = 0; i < array.ndim; i ++) {
                if(i < index.length)
                    result[i] = index[i];
                else
                    result[i] = Slice.every();
            }
            for(var i = 0; i < array.ndim; i ++) {
                result[i].wrap(array.shape[i]);
            }
            for(var i = 0; i < array.ndim; i ++) {
                if(!result[i].check(array.shape[i])) {
                    throw new IndexError.OUT_OF_BOUNDS("Slices %s is out of bounds", Slice.array_to_string(result));
                }
            }
            return result;
        }

        public string to_string() {
            if(has_start && has_end)
                return "%td:%td:%td".printf(start, end, step);
            if(has_start)
                return "%td::%td".printf(start, step);
            if(has_end)
                return ":%td:%td".printf(end, step);
            return "::%td".printf(step);
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
}
