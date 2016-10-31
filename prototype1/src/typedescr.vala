namespace Vast {
    public errordomain ParseError {
        BAD_FORMAT;
    }
    public class TypeDescr : Object
    {
        /**
            id is used to look up cast functions.
            -1 if not registered with a factory.
        */
        public int id;
        public string? name;

        public size_t elsize;
        public size_t [] shape;

        public TypeDescr (size_t elsize, size_t[]? shape = null)
        {
            base();

            if (shape == null) {
                this.shape = new size_t [0];
            } else {
                this.shape = shape;
            }
            this.elsize = elsize;
            this.id = -1;
            this.name = null;
        }

        public virtual string to_string()
        {
            if(this.name != null) {
                return this.name;
            }
            return "TypeDescr(id=%d, shape.length=%d, elsize=%td)"
             .printf(this.id, this.shape.length, this.elsize);
        }

        public virtual string format(void * ptr)
        {
            return "";
        }
        public virtual void parse(string str, void * ptr) throws ParseError
        {
            return;
        }
    }
}
