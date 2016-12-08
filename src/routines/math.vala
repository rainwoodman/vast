namespace Vast.Math
{
    [Vast (gradient = "math_cos")]
    public void
    sin (Array x, Array z)
        requires (x.size == z.size)
    {
        var x_iter = x.iterator ();
        var z_iter = z.iterator ();
        if (x.scalar_type == typeof (double) && z.scalar_type == typeof (double)) {
            while (x_iter.next () && z_iter.next ()) {
                *(double*) z_iter.get_pointer () = GLib.Math.sin (*(double*) x_iter.get_pointer ());
            }
        } else if (x.scalar_type == typeof (float) && z.scalar_type == typeof (float)) {
            while (x_iter.next () && z_iter.next ()) {
                *(float*) z_iter.get_pointer () = GLib.Math.sinf (*(float*) x_iter.get_pointer ());
            }
        } else {
            while (x_iter.next () && z_iter.next ()) {
                z_iter.set_from_value (GLib.Math.sin (x_iter.get_value_as (typeof (double)).get_double ()));
            }
        }
    }

    [Vast (gradient = "-math_sin")]
    public void
    cos (Array x, Array z)
        requires (x.size == z.size)
    {
        var x_iter = x.iterator ();
        var z_iter = z.iterator ();
        if (x.scalar_type == typeof (double) && z.scalar_type == typeof (double)) {
            while (x_iter.next () && z_iter.next ()) {
                *(double*) z_iter.get_pointer () = GLib.Math.cos (*(double*) x_iter.get_pointer ());
            }
        } else if (x.scalar_type == typeof (float) && z.scalar_type == typeof (float)) {
            while (x_iter.next () && z_iter.next ()) {
                *(float*) z_iter.get_pointer () = GLib.Math.cosf (*(float*) x_iter.get_pointer ());
            }
        } else {
            while (x_iter.next () && z_iter.next ()) {
                z_iter.set_from_value (GLib.Math.cos (x_iter.get_value_as (typeof (double)).get_double ()));
            }
        }
    }
}
