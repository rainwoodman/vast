namespace Vast {
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
            this.name = "UnnamedType";
        }

        public virtual string to_string()
        {
            return "TypeDescr(name=%s, id=%d, shape.length=%d, elsize=%td)"
             .printf(this.name, this.id, this.shape.length, this.elsize);
        }
    }

}
