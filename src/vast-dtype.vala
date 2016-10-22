namespace Vast {

    public class TypeDescr : Object
    {
        public size_t elsize {
            get() {
                return 0;
            }
        }
        public size_t shape[];
    }

    public struct FieldDescr
    {
        public const string name;
        public TypeDescr dtype;
        public ssize_t offset;
        public FieldDescr(const string name, TypeDescr dtype, ssize_t offset=-1)
        {
            this.name = name;
            this.dtype = dtype;
            this.offset = offset;
        }
    }

    public class RecordTypeDescr : TypeDescr
    {

        public HashTable <string, FieldDescr> fields;

        construct {
            fields = HashTable<string.FieldDescr> (str_hash, str_equal);
        }

        public RecordTypeDescr (const FieldDescr [] fields)
        {
            for(var i = 0; i < fields.lenth; i ++) {
                ssize_t offset;
                this.fields[fields[i].name] = FieldDescr(fields[i];
            }
        }

        public to_string() {
            for
        }
    }

