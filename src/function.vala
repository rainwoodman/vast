public class Vast.Function : Object
{
    public GI.FunctionInfo function_info { get; construct; }

    public void* symbol { get; construct; }

    public Function (GI.FunctionInfo function_info, void* symbol)
    {
        base (function_info: function_info, symbol: symbol);
    }

    public void
    invoke (Array[] arrays)
    {
        GI.Argument[] in_args = {};
        for (var i = 0; i < arrays.length; i++) {
            in_args += GI.Argument () { v_pointer = arrays[i] };
        }
        try {
            _function_info.invoke (symbol,
                                   in_args,
                                   {},
                                   GI.Argument (),
                                   true,
                                   false);
        } catch (GI.InvokeError err) {
            error ("Could not call '%s.%s': %s.", _function_info.get_namespace (), _function_info.name, err.message);
        }
    }

    public Function
    gradient ()
    {
        var gradient_name = _function_info.get_attribute ("vast.gradient");

        if (gradient_name == null) {
            error ("'%s.%s' does not define a gradient.", _function_info.get_namespace (), _function_info.name);
        }

        var gradient_info = GI.Repository.get_default ().find_by_name ("Vast", gradient_name);

        if (gradient_info == null) {
            error ("The gradient 'Vast.%s' could not be found.", gradient_name);
        }

        if (gradient_info.get_type () != GI.InfoType.FUNCTION) {
            error ("The gradient 'Vast.%s' is not a function.", gradient_name);
        }

        void* gradient_symbol;
        if (!_function_info.typelib.symbol ("vast_%s".printf (gradient_name), out gradient_symbol)) {
            error ("No such symbol 'vast_%s' defined in the typelib.", gradient_name);
        }

        return new Function ((GI.FunctionInfo) gradient_info, gradient_symbol);
    }
}
