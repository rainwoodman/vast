public class Vast.Function : Object
{
    private GI.FunctionInfo _function_info;
    private void*           _callable_symbol;

    public Function (GI.FunctionInfo function_info, void* callable_symbol)
    {
        _function_info   = function_info;
        _callable_symbol = callable_symbol;
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
}
