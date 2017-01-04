public class Vast.GIOperation : Vast.Operation
{
    public GI.FunctionInfo function_info { get; construct; }

    public GIOperation (GI.FunctionInfo function_info)
    {
        var args = new string[function_info.get_n_args ()];
        for (var i = 0; i < function_info.get_n_args (); i++) {
            var arg = function_info.get_arg (i);
            args[i] = arg.get_name ();
        }
        Object (name:          function_info.get_name (),
                arguments:     args,
                function_info: function_info);
    }

    public override void
    invokev (Array[] arrays) throws Error
        requires (arrays.length >= 2)
    {
        var in_args    = new GI.Argument[arrays.length];
        var return_arg = GI.Argument () { v_pointer = arrays[arrays.length - 1] };
        for (var i = 0; i < arrays.length; i++) {
            in_args[i] = GI.Argument () { v_pointer = arrays[i] };
        }
        _function_info.invoke (in_args,
                               {},
                               return_arg);
    }

    public override Operation?
    find_partial_derivative (string out_variable, string in_variable)
    {
        var gradient_identifier = function_info.get_attribute ("vast.gradient-%s-%s-function".printf (out_variable, in_variable)) ??
                                  "%s_gradient_%s_%s".printf (function_info.get_name (), out_variable, in_variable);

        var gradient_info = GI.Repository.get_default ().find_by_name (function_info.get_namespace (),
                                                                       gradient_identifier);
        if (gradient_info == null) {
            return null;
        } else if (gradient_info.get_type () != GI.InfoType.FUNCTION) {
            error ("The '%s' symbol from '%s' namespace is not a function.", gradient_identifier, function_info.get_namespace ());
        }

        return new GIOperation ((GI.FunctionInfo) gradient_info);
    }
}
