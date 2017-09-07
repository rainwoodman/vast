namespace Vast
{
    public unowned Array
    concatenate (Array x, Array y, Array z, ssize_t axis = 0)
        requires (x.shape[axis] + y.shape[axis] == z.shape[axis])
    {
        var x_iter = x.index ({0}).iterator ();
        var y_iter = y.index ({0}).iterator ();
        var z_iter = z.iterator ();
        if (Value.type_compatible (x.scalar_type, z.scalar_type)) {
            while (x_iter.next () && z_iter.next ()) {
                z_iter.set_from_pointer (x_iter.get_pointer ());
            }
        } else {
            while (x_iter.next () && z_iter.next ()) {
                z_iter.set_from_value (x_iter.get_value ());
            }
        }
        if (Value.type_compatible (y.scalar_type, z.scalar_type)) {
            while (y_iter.next () && z_iter.next ()) {
                z_iter.set_from_pointer (y_iter.get_pointer ());
            }
        } else {
            // TODO: type cast
            while (y_iter.next () && z_iter.next ()) {
                z_iter.set_from_value (y_iter.get_value ());
            }
        }
        return z;
    }
}
