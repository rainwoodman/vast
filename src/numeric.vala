namespace Vast {
    public class Numeric {

        public static void init()
        {
            var instance = new Numeric();
            assert(instance != null);

            TypeFactory.init();
            TypeFactory.register_type("f4", new Float32());
            TypeFactory.register_type("f8", new Float64());
            TypeFactory.register_type("i4", new Int32());
            TypeFactory.register_type("i8", new Int64());
            TypeFactory.register_type("u4", new UInt32());
            TypeFactory.register_type("u8", new UInt64());

            TypeFactory.register_cast(dtype("u8"), dtype("u4"), u8_to_u4, CastStyle.UNSAFE);
            TypeFactory.register_cast(dtype("u4"), dtype("u8"), u4_to_u8, CastStyle.SAFE);
            TypeFactory.register_cast(dtype("f8"), dtype("f4"), f8_to_f4, CastStyle.UNSAFE);
            TypeFactory.register_cast(dtype("f4"), dtype("f8"), f4_to_f8, CastStyle.SAFE);
        }

        private class Float32: TypeDescr
        {
            public Float32() { base(sizeof(float)); }
            public override string format(void * ptr)
            {
                return ((float*)ptr).to_string();
            }
        }
        private class Float64: TypeDescr
        {
            public Float64() { base(sizeof(double)); }
            public override string format(void * ptr)
            {
                return ((double*)ptr).to_string();
            }
        }
        private class Int32: TypeDescr
        {
            public Int32() { base(sizeof(int32)); }
            public override string format(void * ptr)
            {
                return ((int32*)ptr).to_string();
            }
        }
        private class Int64: TypeDescr
        {
            public Int64() { base(sizeof(int64)); }
            public override string format(void * ptr)
            {
                return ((int64*)ptr).to_string();
            }
        }
        private class UInt32: TypeDescr
        {
            public UInt32() { base(sizeof(uint32)); }
            public override string format(void * ptr)
            {
                return ((uint32*)ptr).to_string();
            }
        }
        private class UInt64: TypeDescr
        {
            public UInt64() { base(sizeof(uint64)); }
            public override string format(void * ptr)
            {
                return ((uint64*)ptr).to_string();
            }
        }

        private static void u8_to_u4(void * from, void * to)
        {

            *((uint32*) to) = *((uint64*) from);
        }

        private static void u4_to_u8(void * from, void * to)
        {
            *((uint64*) to) = *((uint32*) from);
        }

        private static void f8_to_f4(void * from, void * to)
        {

            *((float*) to) = *((double*) from);
        }

        private static void f4_to_f8(float * from, double * to)
        {
            *to = * from;
        }
    }
}
