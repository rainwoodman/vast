
namespace Vast {

    public errordomain UFuncError {
        UNSUPPORTED,
    }

    public delegate void UFunction (void ** input, void** output);
    
    public class MultiIterator
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
            throws UFuncError
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
            UFunctionHandler? found = null;
            
            foreach(var entry in list) {
                if(!compare_dtypes(dtype_in, entry.dtype_in)) continue;
                if(!compare_dtypes(dtype_out, entry.dtype_out)) continue;
                return entry;
            }
            return null;
        }
        public void apply(Array [] from, Array [] to) throws UFuncError
        {
            assert (from.length == nin);
            assert (to.length == nout);
            
            var handler = find_ufunc(get_dtypes(from), get_dtypes(to));

            if(handler == null)
                throw new UFuncError.UNSUPPORTED("No suitable ufunc is found for %s", this.to_string());

            var ifrom = new MultiIterator(from);
            var ito = new MultiIterator(to);

            while(ifrom.next() && ito.next()) {
                handler.func(ifrom.get(), ito.get());
            }
        }
    }

    private class Sin : UFunc
    {
        construct {
            register({dtype("f8")}, {dtype("f8")}, sin_dd);
            register({dtype("f4")}, {dtype("f4")}, sin_ff);
        }

        public Sin()
        {
            base(1, 1);
        }

        private void sin_dd(void ** from, void ** to)
        {
            *(double*)(to[0]) = Math.sin(*(double*)(from[0]));
        }

        private void sin_ff(void ** from, void ** to)
        {
            *(float*)(to[0]) = Math.sin(*(float*)(from[0]));
        }
    }

    public class UFuncFactory : Object
    {
        
        static HashTable<string, UFunc> table;

        static construct {
            table = new HashTable<string, UFunc>(str_hash, str_equal);
        }

        public static void init() {
            /* initializes the class */
            var o = new UFuncFactory();
            assert (o != null);

            register_ufunc("sin", new Sin());
        }

        public static void register_ufunc(string str, UFunc ufunc)
        {
            table.insert(str, ufunc);
            ufunc.name = str;
        } 

        public static UFunc from_string(string str)
        {
            var item = table.get(str);
            if(item != null) return item;

            assert_not_reached();
        }
    }
}
