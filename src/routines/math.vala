namespace Vast.Math
{
    public unowned Array
    add (Array x, Array y, Array z)
    {
        var x_iter = x.iterator ();
        var y_iter = y.iterator ();
        var z_iter = z.iterator ();
        while (x_iter.next () && y_iter.next () && z_iter.next ()) {
            *(double*) z_iter.get_pointer () = *(double*) x_iter.get_pointer () + *(double*) y_iter.get_pointer ();
        }
        return z;
    }

    public unowned Array
    negative (Array x, Array z)
        requires (x.size == z.size)
    {
        var x_iter = x.iterator ();
        var z_iter = z.iterator ();
        while (x_iter.next () && z_iter.next ()) {
            *(double*) z_iter.get_pointer () = -*(double*) x_iter.get_pointer ();
        }
        return z;
    }

    public unowned Array
    multiply (Array x, Array y, Array z)
    {
        var x_iter = x.iterator ();
        var y_iter = y.iterator ();
        var z_iter = z.iterator ();
        while (x_iter.next () && y_iter.next () && z_iter.next ()) {
            *(double*) z_iter.get_pointer () = *(double*) x_iter.get_pointer () * *(double*) y_iter.get_pointer ();
        }
        return z;
    }

    [Vast (gradient_z_x_function = "math_cos")]
    public unowned Array
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
        return z;
    }

    public unowned Array
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
        return z;
    }

    public unowned Array
    cos_gradient_z_x (Array x, Array z)
    {
        return negative (sin (x, z), z);
    }

    public unowned Array
    power (Array x, Array y, Array z)
        requires (x.size == y.size)
        requires (x.size == z.size)
    {
        var x_iter = x.iterator ();
        var y_iter = y.iterator ();
        var z_iter = z.iterator ();
        if (x.scalar_type == typeof (double) && y.scalar_type == typeof (double) && z.scalar_type == typeof (double)) {
            while (x_iter.next () && y_iter.next () && z_iter.next ()) {
                *(double*) z_iter.get_pointer () = GLib.Math.pow (*(double*) x_iter.get_pointer (),
                                                                  *(double*) y_iter.get_pointer ());
            }
        } else if (x.scalar_type == typeof (float) && y.scalar_type == typeof (double) && z.scalar_type == typeof (float)) {
            while (x_iter.next () && y_iter.next () && z_iter.next ()) {
                *(float*) z_iter.get_pointer () = GLib.Math.powf (*(float*) x_iter.get_pointer (),
                                                                  *(float*) y_iter.get_pointer ());
            }
        } else {
            while (x_iter.next () && y_iter.next () && z_iter.next ()) {
                z_iter.set_from_value (GLib.Math.pow (x_iter.get_value_as (typeof (double)).get_double (),
                                                      y_iter.get_value_as (typeof (double)).get_double ()));
            }
        }
        return z;
    }

    public unowned Array
    power_gradient_z_x (Array x, Array y, Array z)
    {
        // y * x ^ (y - 1)
        z.fill_from_value (-1);
        return multiply (y, power (x, add (y, z, z), z), z);
    }

    public unowned Array
    power_gradient_z_y (Array x, Array y, Array z, Array tmp)
    {
        // x ^ y * log (x)
        return multiply (power (x, y, z), log (x, tmp), z);
    }

    public unowned Array
    log (Array x, Array z)
    {
        var x_iter = x.iterator ();
        var z_iter = z.iterator ();
        while (x_iter.next () && z_iter.next ()) {
            *(double*) z_iter.get_pointer () = GLib.Math.log (*(double*) x_iter.get_pointer ());
        }
        return z;
    }
}
