public class Vast.ArrayIterator<T> : Object
{
    public Array<T> array { get; construct; }

    [CCode (array_length = false)]
    public ssize_t [] cursor;
    private ssize_t offset;

    public bool ended;
    private bool started;

    public ArrayIterator (Array array)
    {
        base (array: array);
        cursor = new ssize_t[array.dimension];
        reset ();
    }

    public bool
    next ()
    {
        if (! started) {
            started = true;
            return !ended;
        }
        if (array.dimension == 0) {
            /* special case for scalar. This could have been merged with below? */
            ended = true;
            return !ended;
        }
        ssize_t dim = (ssize_t) array.dimension - 1;
        cursor[dim] ++;
        while (dim >= 0 && cursor[dim] == array.shape[dim]) {
            cursor[dim] = 0;
            dim --;
            if (dim >= 0) {
                cursor[dim] ++;
            } else {
                ended = true;
            }
        }
        offset = 0;
        for (var i = 0; i < cursor.length; i ++) {
            offset += cursor[i] * array.strides[i];
        }
        return !ended;
    }

    public unowned T
    get () {
        return (T) ((uint8*) array.data.get_data () + offset);
    }

    public void
    set (T val) {
        Memory.copy ((uint8*) array.data.get_data () + offset, val, sizeof (T));
    }

    public void
    reset ()
    {
        ended = false;
        started = false;
        var zero = new ssize_t[array.dimension];
        for (var i = 0; i < zero.length; i ++) {
            zero[i] = 0;
        }
        move (zero);
    }

    public void
    move (ssize_t [] cursor)
    {
        offset = 0;
        for (var i = 0; i < cursor.length; i ++) {
            cursor[i] = cursor[i];
            offset += cursor[i] * array.strides[i];
        }
        ended = false;
        for (var i = 0; i < cursor.length; i ++) {
            if (cursor[i] >= array.shape[i]) {
                ended = true;
                break;
            }
        }
    }

    public bool
    end ()
    {
        return ended;
    }
}
