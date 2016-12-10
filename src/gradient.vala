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
        var gradient_identifier = function.function_info.get_attribute ("vast.gradient_%s_%s".printf (out_variable, in_variable)) ??
                                  "%s_gradient_%s_%s".printf (function.function_info.name, out_variable, in_variable);

        var gradient_info = GI.Repository.get_default ().find_by_name ("Vast", gradient_identifier);
        if (gradient_info == null) {
            error ("Could not retreive '%s' from the '%s' namespace.", gradient_identifier, "Vast");
        }

        var gradient_symbol_name = function.function_info.get_attribute ("vast.gradient_%s_%s_cname".printf (out_variable, in_variable)) ??
                                   "%s_%s".printf ("vast", gradient_identifier);

        void* gradient_symbol;
        if (!function.function_info.typelib.symbol (gradient_symbol_name, out gradient_symbol)) {
            error ("Could not retrieve symbol '%s' from the typelib.", gradient_symbol_name);
        }

        return new Function ((GI.FunctionInfo) gradient_info, gradient_symbol);
    }
}
