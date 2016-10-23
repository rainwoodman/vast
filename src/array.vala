namespace Vast {
    public class Array: Object
    {
        public TypeDescr dtype;

        public Object? base;
        
        public void * data;

        public Array(TypeDescr dtype, size_t [] shape)
        {
        }

    }

    public class UFunc : GLib.Object
    {

    }
}
