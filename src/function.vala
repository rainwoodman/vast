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
        var in_args = new GI.Argument[arrays.length + 1];
        for (var i = 0; i < arrays.length; i++) {
            in_args[i] = GI.Argument () { v_pointer = arrays[i] };
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
}
