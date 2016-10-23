namespace Vast {
    public class Numeric {

        public static void init()
        {
            var instance = new Numeric();
            assert(instance != null);

            TypeFactory.init();
            TypeFactory.register_type("f4", new TypeDescr(4));
            TypeFactory.register_type("f8", new TypeDescr(8));
            TypeFactory.register_type("i4", new TypeDescr(4));
            TypeFactory.register_type("i8", new TypeDescr(8));
            TypeFactory.register_type("u4", new TypeDescr(4));
            TypeFactory.register_type("u8", new TypeDescr(8));

            TypeFactory.register_cast(dtype("u8"), dtype("u4"), u8_to_u4, CastStyle.UNSAFE);
            TypeFactory.register_cast(dtype("u4"), dtype("u8"), u4_to_u8, CastStyle.SAFE);
        }

        private static void u8_to_u4(CastOperand from, CastOperand to, size_t N)
        {

            uint8 * p1 = from.ptr;
            uint8 * p2 = from.ptr;
            for(var i = 0; i < N; i ++) {
                *((uint32*) p2) = *((uint64*) p1);
                p1 += from.step;
                p2 += from.step;
            }
        }

        private static void u4_to_u8(CastOperand from, CastOperand to, size_t N)
        {
            uint8 * p1 = from.ptr;
            uint8 * p2 = from.ptr;
            for(var i = 0; i < N; i ++) {
                *((uint64*) p2) = *((uint32*) p1);
                p1 += from.step;
                p2 += from.step;
            }
        }
    }
}
