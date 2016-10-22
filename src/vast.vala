using GLib;
namespace Vast {

    public class Function : GLib.Object
    {
        public Function(int nin, int nout)
        {

        }

        virtual public get_gradient() {

        }
    }

    public class Variable : GLib.Object
    {
        public Variable(size_t shape[], GLib.Type type)
        {

        }
    }
}
