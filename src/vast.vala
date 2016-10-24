namespace Vast {

    public void init()
    {
        TypeFactory.init();
        Numeric.init();
        UFuncFactory.init();
    }

    public TypeDescr dtype(string str)
    {
        return TypeFactory.from_string(str);
    }

    public UFunc ufunc(string str)
    {
        return UFuncFactory.from_string(str);
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
