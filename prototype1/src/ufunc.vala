
namespace Vast {

    public errordomain UFuncError {
        UNSUPPORTED,
    }

    public delegate void UFunction (void ** input, void** output);
    
    public class UFunc : Object
    {
        public string? name;

        public struct UFunctionHandler {
            TypeDescr [] dtype_in;
            TypeDescr [] dtype_out;
            unowned UFunction func;
        }

        public int nin {get; construct;}
        public int nout {get; construct;}

        List<UFunctionHandler?> list;

        public UFunc(int nin, int nout)
        {
            base(nin : nin, nout : nout);
            this.name = null;
        }

        public void register(TypeDescr [] dtype_in, TypeDescr [] dtype_out, UFunction func)
        {
            UFunctionHandler us = UFunctionHandler();
            us.dtype_in = dtype_in;
            us.dtype_out = dtype_out;
            us.func = func;

            list.prepend(us);
        }

        public virtual string to_string() {
            if(name != null)
                return name;
            return "UFunc";
        }

        private UFunctionHandler? find_ufunc(TypeDescr [] dtype_in, TypeDescr [] dtype_out)
        {
            
            foreach(var entry in list) {
                if(!compare_dtypes(dtype_in, entry.dtype_in)) continue;
                if(!compare_dtypes(dtype_out, entry.dtype_out)) continue;
                return entry;
            }
            return null;
        }
        public void apply(Array [] from, Array [] to) throws UFuncError, BroadcastError
        {
            assert (from.length == nin);
            assert (to.length == nout);
            
            var handler = find_ufunc(get_dtypes(from), get_dtypes(to));

            if(handler == null)
                throw new UFuncError.UNSUPPORTED("No suitable ufunc is found for %s", this.to_string());

            var bfrom = broadcast(from);
            var ifrom = new MultiIterator(bfrom);
            var ito = new MultiIterator(to);

            while(ifrom.next() && ito.next()) {
                handler.func(ifrom.get(), ito.get());
            }
        }
    }
    public errordomain BroadcastError {
        INCOMPATIBLE_SHAPE,
    }
    private string format_shapes(Array [] src) {
        var sb = new StringBuilder();
        for(var i = 0; i < src.length; i ++) {
            sb.append("[");
            for(var d = 0; d < src[i].ndim; d ++) {
                sb.append_printf("%td, ", src[i].shape[d]);
            }
            sb.append("]");
            sb.append(" ");
        }
        return sb.str;
    }

    private Array [] broadcast(Array [] src) throws BroadcastError
    {
        var dst = new Array [src.length];
        var max_ndim = 0;
        for(var i = 0; i < src.length; i ++) {
            if(max_ndim < src[i].ndim) max_ndim = src[i].ndim;
        }
        var shape = new size_t [max_ndim];
        for(var d = 0; d < max_ndim; d ++) {
            shape[d] = 1;
        }
        for(var i = 0; i < src.length; i ++) {
            for(var d = 0; d < src[i].ndim; d ++) {
                if(shape[d] == 1) {
                    shape[d] = src[i].shape[d];
                    continue;
                }
                if(src[i].shape[d] != shape[d]) {
                    throw new BroadcastError.INCOMPATIBLE_SHAPE("shape is incompatible: %s", format_shapes(src));
                }
            }
        }

        for(var i = 0; i < src.length; i ++) {
            var strides = new ssize_t [max_ndim];
            for(var d = 0; d < max_ndim; d ++) {
                if(d < src[i].ndim && shape[d] == src[i].shape[d]) {
                    strides[d] = src[i].strides[d];
                } else {
                    strides[d] = 0;
                }
            }
            dst[i] = new Array.full(max_ndim, src[i].dtype, shape, strides);
            dst[i].data = src[i].data;
            dst[i].base = src[i];
        }
        return dst;
    }
    private class MultiIterator
    {
        ArrayIterator [] iterators;
        void * [] dataptrs;

        public MultiIterator(Array [] array)
        {
            iterators = new ArrayIterator [array.length];
            for(var i = 0; i < array.length; i ++) {
                iterators[i] = array[i].iterator();
            }
            dataptrs = new void* [array.length];
        }

        public bool next()
        {
            var flag = true;
            for(var i = 0; i < iterators.length; i ++) {
                flag &= iterators[i].next();
            }
            return flag;
        }

        public void ** get()
        {
            for(var i = 0; i < iterators.length; i ++) {
                dataptrs[i] = iterators[i].get();
            }
            return dataptrs;
        }
    }

    private TypeDescr [] get_dtypes(Array [] array)
    {
        var result = new TypeDescr[array.length];
        for(var i = 0; i < array.length; i ++) {
            result[i] = array[i].dtype;
        }
        return result;
    }
    private bool compare_dtypes(TypeDescr [] d1, TypeDescr [] d2)
    {
        for(var i = 0; i < d1.length; i ++) {
            if(d1[i] != d2[i]) return false;
        }
        return true;
    }


}
