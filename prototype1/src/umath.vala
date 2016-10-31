namespace Vast {

    public class UMath
    {
        public static void init()
        {
            UFuncFactory.register_ufunc("sin", new Sin());
            UFuncFactory.register_ufunc("mul", new Multiply());
        }

    } 

    private class Sin : UFunc
    {
        construct {
            register({dtype("f8")}, {dtype("f8")}, sin_dd);
            register({dtype("f4")}, {dtype("f4")}, sin_ff);
        }

        public Sin()
        {
            base(1, 1);
        }

        private void sin_dd(void ** from, void ** to)
        {
            *(double*)(to[0]) = Math.sin(*(double*)(from[0]));
        }

        private void sin_ff(void ** from, void ** to)
        {
            *(float*)(to[0]) = Math.sin(*(float*)(from[0]));
        }
    }

    private class Multiply : UFunc
    {
        construct {
            register({dtype("f8"), dtype("f8")}, {dtype("f8")}, mul_ddd);
            register({dtype("f4"), dtype("f4")}, {dtype("f4")}, mul_fff);
        }

        public Multiply()
        {
            base(2, 1);
        }

        private void mul_ddd(void ** from, void ** to)
        {
            *(double*)(to[0]) = (*(double*)(from[0])) * (*(double*)(from[1]));
        }

        private void mul_fff(void ** from, void ** to)
        {
            *(float*)(to[0]) = (*(float*)(from[0])) * (*(float*)(from[1]));
        }
    }
}
