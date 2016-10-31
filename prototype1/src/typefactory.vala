namespace Vast {

    public enum CastStyle {
        SAFE,
        UNSAFE,
    }

    public delegate void CastFunction(void * from, void * to);

    public class TypeFactory : Object
    {

        internal static const size_t MAX_TYPE = 128;
        public struct CastFunctionStruct {
            CastStyle type;
            unowned CastFunction cast;
        }

        internal static CastFunctionStruct[,] cast_table;
        internal static HashTable<string, TypeDescr> table;

        static construct {
            table = new HashTable<string, TypeDescr>(str_hash, str_equal);
            cast_table = new CastFunctionStruct[MAX_TYPE, MAX_TYPE];

        }

        public static void init() {
            /* initializes the class */
            var o = new TypeFactory();
            assert (o != null);
        }

        public static TypeDescr from_string(string str) 
        {
            var item = table.get(str);
            if(item != null) return item;

            assert_not_reached();
        }

        internal static int ntypes;
        public static void register_type(string str, TypeDescr dtype)
        {
            table.insert(str, dtype);
            dtype.id = ntypes;
            dtype.name = str;
            ntypes ++;
        }

        public static void register_cast(TypeDescr from, TypeDescr to, CastFunction cast, CastStyle type)
        {
            assert(from.id >= 0);
            assert(to.id >= 0);

            cast_table[from.id, to.id].cast = cast;
            cast_table[from.id, to.id].type = type;
        }

        public static unowned CastFunction? find_cast(TypeDescr from, TypeDescr to, CastStyle type=CastStyle.SAFE)
        {
            assert(from.id >= 0);
            assert(to.id >= 0);
            if(type == CastStyle.SAFE && cast_table[from.id, to.id].type != type) {
                return null;
            }
            return cast_table[from.id, to.id].cast;
        }
    }

}
