using GLib;

public class Vast.MultiIterator : Object
{
    private Array[] _arrays;
    private Iterator[] _iterators;
    private void * [] _dataptrs;

    public unowned Array** arrays {
        get { return _arrays; }
        construct {
            int n;
            unowned Array p;
            /* the length from a null terminated array.
             * vala can probably do this conversion automatically. */
            for(n = 0; (p = value[n]) != null; n++ ) {
                continue;
            }
            _arrays = new Array[n];
            for(n = 0; (p = value[n]) != null; n++ ) {
                _arrays[n] = value[n]; 
            }
        }
    }

    construct {
        _iterators = new Iterator [_arrays.length];
        _dataptrs = new void * [_arrays.length];
        for(var i = 0; i < _arrays.length; i ++) {
            _iterators[i] = new Iterator(_arrays[i]);
            _dataptrs[i] = null;
        }
        message("initialized with %d arrays", _arrays.length);
    }

    public MultiIterator (
        Array[] arrays
    )
    {
        var arrays_null_terminated = new Array[arrays.length + 1];
        
        for(var i = 0; i < arrays.length; i ++) {
            arrays_null_terminated[i] = arrays[i];
        }
        arrays_null_terminated[arrays.length] = null;
        base (arrays: arrays_null_terminated);
    }

    /* ** avoid vala array duplication when the receiver declares var */
    public void**
    get ()
    {
        for (var i = 0; i < _arrays.length; i++) {
            _dataptrs[i] = _iterators[i].get();
        }
        return _dataptrs;
    }

    public bool
    next ()
    {
        var flag = true;
        for(var i = 0; i < _iterators.length; i ++) {
            flag &= _iterators[i].next();
        }
        return flag;
    }
}
