public class Vast.Function : Object
{
    private GI.FunctionInfo _function_info;
    private void*           _callable_symbol;

    public Function (GI.FunctionInfo function_info, void* callable_symbol)
    {
        _function_info   = function_info;
        _callable_symbol = callable_symbol;
    }

    public GI.FunctionInfo
    get_function_info ()
    {
        return _function_info;
    }

    public void
    invoke (Array[] arrays)
    {
        GI.Argument[] in_args = {};
        for (var i = 0; i < arrays.length; i++) {
            in_args += GI.Argument () { v_pointer = arrays[i] };
        }
        try {
            _function_info.invoke (_callable_symbol,
                                   in_args,
                                   {},
                                   GI.Argument (),
                                   true,
                                   false);
        } catch (GI.InvokeError err) {
            error ("Could not call '%s.%s': %s.", _function_info.get_namespace (), _function_info.get_name (), err.message);
        }
    }

    public Function
    gradient ()
    {
        var gradient_name = _function_info.get_attribute ("vast.gradient");

        if (gradient_name == null) {
            error ("'%s.%s' does not define a gradient.", _function_info.get_namespace (), _function_info.get_name ());
        }

        var gradient_info = GI.Repository.get_default ().find_by_name ("Vast", gradient_name);

        if (gradient_info == null) {
            error ("The gradient 'Vast.%s' could not be found.", gradient_name);
        }

        if (gradient_info.get_type () != GI.InfoType.FUNCTION) {
            error ("The gradient 'Vast.%s' is not a function.", gradient_name);
        }

        unowned GI.Typelib tl = _function_info.get_typelib ();

        void* gradient_symbol;
        if (!tl.symbol ("vast_%s".printf (gradient_name), out gradient_symbol)) {
            error ("No such symbol 'vast_%s' defined in the typelib.", gradient_name);
        }

        return new Function ((GI.FunctionInfo) gradient_info, gradient_symbol);
    }
}
