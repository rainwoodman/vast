public class Vast.Function : Object
{
    public GI.FunctionInfo function_info { get; construct; }

    public Function (GI.FunctionInfo function_info)
    {
        base (function_info: function_info);
    }

    public unowned Array
    invoke (Array[] arrays)
        requires (arrays.length >= 2)
    {
        var in_args    = new GI.Argument[arrays.length];
        var return_arg = GI.Argument () { v_pointer = arrays[arrays.length - 1] };
        for (var i = 0; i < arrays.length; i++) {
            in_args[i] = GI.Argument () { v_pointer = arrays[i] };
        }
        try {
            _function_info.invoke (in_args,
                                   {},
                                   return_arg);
            return (Array) return_arg.v_pointer;
        } catch (GI.InvokeError err) {
            error ("Could not call '%s.%s': %s.", _function_info.get_namespace (), _function_info.get_name (), err.message);
        }
    }
}
