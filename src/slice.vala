namespace Vast {
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
}
