namespace Vast {

    public void init()
    {
        TypeFactory.init();
        UFuncFactory.init();

        Numeric.init();
        UMath.init();
    }

    public TypeDescr dtype(string str)
    {
        return TypeFactory.from_string(str);
    }

    public UFunc ufunc(string str)
    {
        return UFuncFactory.from_string(str);
    }

    public Array range(ssize_t start, ssize_t end, ssize_t step, TypeDescr? dtype=null)
    {
        var _dtype = dtype;
        if (_dtype == null) {
            _dtype = Vast.dtype("i8");
        }
        return new Array.range(_dtype, start, end, step);
    }

    public Array empty(size_t [] shape, TypeDescr? dtype=null)
    {
        var _dtype = dtype;
        if (_dtype == null) {
            _dtype = Vast.dtype("f8");
        }
        return new Array.empty(dtype, shape);
    }

    public Array zeros(size_t [] shape, TypeDescr? dtype=null)
    {
        var _dtype = dtype;
        if (_dtype == null) {
            _dtype = Vast.dtype("f8");
        }
        return new Array.zeros(dtype, shape);
    }

    public class Function : GLib.Object
    {
        public Function(int nin, int nout)
        {

        }

        public virtual Function? get_gradient()
        {
            return null;
        }
    }

    public class Variable : GLib.Object
    {
        public Variable(size_t shape[], GLib.Type type)
        {

        }
    }
}
