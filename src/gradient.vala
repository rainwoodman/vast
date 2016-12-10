public class Vast.Gradient : Object
{
    public Function function { get; construct; }

    public Gradient (Function function)
    {
        base (function: function);
    }

    public Function
    get_partial_derivative (string out_variable, string in_variable)
    {
        var gradient_identifier = function.function_info.get_attribute ("vast.gradient-%s-%s-function".printf (out_variable, in_variable)) ??
                                  "%s_gradient_%s_%s".printf (function.function_info.get_name (), out_variable, in_variable);

        var gradient_info = GI.Repository.get_default ().find_by_name (function.function_info.get_namespace (),
                                                                       gradient_identifier);
        if (gradient_info == null) {
            error ("Could not retreive '%s' from the '%s' namespace.", gradient_identifier, function.function_info.get_namespace ());
        }

        return new Function ((GI.FunctionInfo) gradient_info);
    }
}
