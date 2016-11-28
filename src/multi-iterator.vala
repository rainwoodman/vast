using GLib;

public class Vast.MultiIterator : Object
{
    private Array[] _arrays;

    public Array* arrays {
        get { return _arrays; }
        construct { /*_arrays = value;*/ }
    }

    [CCode (array_length = false)]
    private ssize_t*[] cursor;

    [CCode (array_length = false)]
    private size_t[] offset;

    public MultiIterator (Array[] arrays)
    {
        base (arrays: arrays);
    }

    [CCode (array_length = false)]
    public (unowned void*)[]
    get ()
    {
        var ret = new (unowned void*)[_arrays.length];
        for (var i = 0; i < _arrays.length; i++) {
            ret[i] = (uint8*) _arrays[i].data.get_data () + offset[i];
        }
        return ret;
    }

    public bool
    next ()
    {
        return false;
    }
}
