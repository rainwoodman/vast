using GLib;
namespace Vast {
public void
value_to_memory (Value val, void * memory, Type scalar_type, size_t scalar_size)
{
    var dest_value = Value (scalar_type);
    if (val.transform (ref dest_value)) {
        if (scalar_type == typeof (string)) {
            Memory.copy (memory, val.get_string (), scalar_size);
        }

        else if (dest_value.fits_pointer ()) {
            Memory.copy (memory, dest_value.peek_pointer(), scalar_size);
        }

        else if (scalar_type == Type.BOXED) {
            Memory.copy (memory, dest_value.get_boxed (), scalar_size);
        }

        else if (scalar_type == typeof (char)) {
            var _ = dest_value.get_char ();
            Memory.copy (memory, (&_), scalar_size);
        }

        else if (scalar_type == typeof (uint8)) {
            var _ = dest_value.get_uchar ();
            Memory.copy (memory, (&_), scalar_size);
        }

        else if (scalar_type == typeof (int64)) {
            var _ = dest_value.get_int64 ();
            Memory.copy (memory, (&_), scalar_size);
        }

        else if (scalar_type == typeof (double)) {
            var _ = dest_value.get_double ();
            Memory.copy (memory, &_, scalar_size);
        }

        else {
            assert_not_reached ();
        }
    } else {
        error ("Could not transform '%s' into '%s'.", val.type ().name (),
                                                      dest_value.type ().name ());
    }
}
public Value
memory_to_value(void * memory, Type scalar_type, size_t scalar_size)
{
    var _value = Value (scalar_type);

    if (scalar_type == typeof (string)) {
        _value.set_string ((string) memory);
    }

    else if (_value.fits_pointer ()) {
        Memory.copy (_value.peek_pointer (), memory, scalar_size);
    }

    else if (scalar_type == Type.BOXED) {
        _value.set_boxed (memory);
    }

    else if (scalar_type == typeof (char)) {
        _value.set_char (*(char*) memory);
    }

    else if (scalar_type == typeof (uint8)) {
        _value.set_uchar (*(uchar*) memory);
    }

    else if (scalar_type == typeof (int64)) {
        _value.set_int64 (*(int64*) memory);
    }

    else if (scalar_type == typeof (double)) {
        _value.set_double (*((double*) memory));
    }

    else {
        assert_not_reached ();
    }

    return _value;

}
}
