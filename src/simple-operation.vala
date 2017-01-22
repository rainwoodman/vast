namespace Vast
{
    public delegate void SimpleOperationCallback (Array[] arrays);
}

public class Vast.SimpleOperation : Vast.Operation
{
    private SimpleOperationCallback _callback;

    public SimpleOperation (string name, string[] arguments, owned SimpleOperationCallback callback) {
        Object (name: name, arguments: arguments);
        _callback = (owned) callback;
    }

    public override void
    invokev (Array[] arrays)
    {
        _callback (arrays);
    }
}
