namespace Vast {

    public struct FieldDescr
    {
        public string name;
        public TypeDescr dtype;
        public ssize_t offset;
        public FieldDescr(string name, TypeDescr dtype, ssize_t offset=-1)
        {
            this.name = name;
            this.dtype = dtype;
            this.offset = offset;
        }
    }

    public class RecordType : TypeDescr
    {

        public HashTable <string, FieldDescr?> fields;

        construct {
            fields = new HashTable<string, FieldDescr?> (str_hash, str_equal);
        }

        public RecordType (FieldDescr [] fields)
        {
            base(0);

            bool with_offset = false;
            for(var i = 0; i < fields.length; i ++) {
                if(fields[i].offset != -1) {
                    with_offset = true;
                }    
            }
            ssize_t offset = 0;
            for(var i = 0; i < fields.length; i ++) {
                if(with_offset) offset = fields[i].offset;

                this.fields[fields[i].name] = FieldDescr(fields[i].name, fields[i].dtype, offset);

                offset += (ssize_t)(fields[i].dtype.elsize);
            }
        }

        public override string to_string() 
        {
            var sb = new StringBuilder();
            sb.append_printf("RecordType(");
            this.fields.foreach((key, val) => {
                    sb.append_printf("%s:", val.name);
                    sb.append_printf("%s", val.dtype.to_string());
                    sb.append_printf("%td,", val.offset);
                }
            );
            sb.append_printf(")");
            return sb.str;
        }
    }

}
