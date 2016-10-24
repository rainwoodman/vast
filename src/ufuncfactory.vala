namespace Vast {

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
