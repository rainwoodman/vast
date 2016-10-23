namespace Vast {
    public class Numeric {

        /* safe */
        private static void f4_to_f8(float * from, double * to) { *to = * from; }
        private static void i4_to_i8(int32 * from, int64 * to) { *to = * from; }
        private static void u4_to_i8(uint32 * from, int64 * to) { *to = * from; }
        private static void i4_to_f8(int32 * from, double * to) { *to = * from; }
        private static void u4_to_f8(uint32 * from, double * to) { *to = * from; }
        private static void u4_to_u8(uint32 * from, uint64 * to) { *to = *from; }

        private static void register_safe_casts() {

            TypeFactory.register_cast(dtype("f4"), dtype("f8"), f4_to_f8, CastStyle.SAFE);
            TypeFactory.register_cast(dtype("i4"), dtype("i8"), i4_to_i8, CastStyle.SAFE);
            TypeFactory.register_cast(dtype("u4"), dtype("i8"), u4_to_i8, CastStyle.SAFE);
            TypeFactory.register_cast(dtype("i4"), dtype("f8"), i4_to_f8, CastStyle.SAFE);
            TypeFactory.register_cast(dtype("u4"), dtype("f8"), u4_to_f8, CastStyle.SAFE);
            TypeFactory.register_cast(dtype("u4"), dtype("u8"), u4_to_u8, CastStyle.SAFE);
        }

        /* unsafe, same class */

        private static void i8_to_i4(int64 * from, int32 * to) { *to = *from; }
        private static void u8_to_u4(uint64 * from, uint32 * to) { *to = *from; }
        private static void f8_to_f4(double * from, float * to) { *to = *from; }

        private static void register_unsafe_casts1() {
            TypeFactory.register_cast(dtype("i8"), dtype("i4"), i8_to_i4, CastStyle.UNSAFE);
            TypeFactory.register_cast(dtype("u8"), dtype("u4"), u8_to_u4, CastStyle.UNSAFE);
            TypeFactory.register_cast(dtype("f8"), dtype("f4"), f8_to_f4, CastStyle.UNSAFE);
        }

        /* unsafe, loosing precision */
        private static void i8_to_f8( int64 * from, double * to) { *to = *from; }
        private static void u8_to_f8(uint64 * from, double * to) { *to = *from; }
        private static void i8_to_f4( int64 * from,  float * to) { *to = *from; }
        private static void u8_to_f4(uint64 * from,  float * to) { *to = *from; }
        private static void i4_to_f4( int32 * from,  float * to) { *to = *from; }
        private static void u4_to_f4(uint32 * from,  float * to) { *to = *from; }

        private static void register_unsafe_casts2() {
            TypeFactory.register_cast(dtype("i8"), dtype("f8"), i8_to_f8, CastStyle.UNSAFE);
            TypeFactory.register_cast(dtype("u8"), dtype("f8"), u8_to_f8, CastStyle.UNSAFE);
            TypeFactory.register_cast(dtype("i8"), dtype("f4"), i8_to_f4, CastStyle.UNSAFE);
            TypeFactory.register_cast(dtype("u8"), dtype("f4"), u8_to_f4, CastStyle.UNSAFE);

            TypeFactory.register_cast(dtype("i4"), dtype("f4"), i4_to_f4, CastStyle.UNSAFE);
            TypeFactory.register_cast(dtype("u4"), dtype("f4"), u4_to_f4, CastStyle.UNSAFE);
        }


        /* unsafe, overflow */
        private static void u8_to_i8(uint64 * from, int64 * to) { *to = *from; }
        private static void i8_to_u8(int64 * from, uint64 * to) { *to = *from; }
        private static void f8_to_i8(double * from, int64 * to) { *to = *from; }
        private static void f4_to_i8(float * from, int64 * to) { *to = *from; }
        private static void f8_to_u8(double * from, uint64 * to) { *to = *from; }
        private static void f4_to_u8(float * from, uint64 * to) { *to = *from; }

        private static void u8_to_i4(uint64 * from, int32 * to) { *to = *from; }
        private static void i8_to_u4(int64 * from, uint32 * to) { *to = *from; }
        private static void f4_to_i4(float * from, int32 * to) { *to = *from; }
        private static void f4_to_u4(float * from, uint32 * to) { *to = *from; }

        private static void register_unsafe_casts3() {
            TypeFactory.register_cast(dtype("u8"), dtype("i8"), u8_to_i8, CastStyle.UNSAFE);
            TypeFactory.register_cast(dtype("i8"), dtype("u8"), i8_to_u8, CastStyle.UNSAFE);
            TypeFactory.register_cast(dtype("f8"), dtype("i8"), f8_to_i8, CastStyle.UNSAFE);
            TypeFactory.register_cast(dtype("f4"), dtype("i8"), f4_to_i8, CastStyle.UNSAFE);
            TypeFactory.register_cast(dtype("f8"), dtype("u8"), f8_to_u8, CastStyle.UNSAFE);
            TypeFactory.register_cast(dtype("f4"), dtype("u8"), f4_to_u8, CastStyle.UNSAFE);

            TypeFactory.register_cast(dtype("u8"), dtype("i4"), u8_to_i4, CastStyle.UNSAFE);
            TypeFactory.register_cast(dtype("i8"), dtype("u4"), i8_to_u4, CastStyle.UNSAFE);
            TypeFactory.register_cast(dtype("f4"), dtype("i4"), f4_to_i4, CastStyle.UNSAFE);
            TypeFactory.register_cast(dtype("f4"), dtype("u4"), f4_to_u4, CastStyle.UNSAFE);
        }


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

            register_safe_casts();
            register_unsafe_casts1();
            register_unsafe_casts2();
            register_unsafe_casts3();
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

    }
}
