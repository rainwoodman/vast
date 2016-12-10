namespace Vast.Math
{
    public void
    add (Array x, Array y, Array z)
    {
        var x_iter = x.iterator ();
        var y_iter = y.iterator ();
        var z_iter = z.iterator ();
        while (x_iter.next () && y_iter.next () && z_iter.next ()) {
            *(double*) z_iter.get_pointer () = *(double*) x_iter.get_pointer () + *(double*) y_iter.get_pointer ();
        }
    }

    public void
    negative (Array x, Array z)
        requires (x.size == z.size)
    {
        var x_iter = x.iterator ();
        var z_iter = z.iterator ();
        while (x_iter.next () && z_iter.next ()) {
            *(double*) z_iter.get_pointer () = -*(double*) x_iter.get_pointer ();
        }
    }

    public void
    multiply (Array x, Array y, Array z)
    {
        var x_iter = x.iterator ();
        var y_iter = y.iterator ();
        var z_iter = z.iterator ();
        while (x_iter.next () && y_iter.next () && z_iter.next ()) {
            *(double*) z_iter.get_pointer () = *(double*) x_iter.get_pointer () * *(double*) y_iter.get_pointer ();
        }
    }

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

    public void
    sin_gradient_z_x (Array x, Array z)
    {
        cos (x, z);
    }

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

    public void
    cos_gradient_z_x (Array x, Array z)
    {
        sin (x, z);
        negative (z, z);
    }

    public void
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
    }

    public void
    power_gradient_z_x (Array x, Array y, Array z)
    {
        z.fill_value (-1);
        add (y, z, z);      // z = a - z = a - 1
        power (x, z, z);    // z = x ^ z = x ^ (a - 1)
        multiply (y, z, z); // z = a * z = a * x ^ (a - 1)
    }

    public void
    power_gradient_z_y (Array x, Array y, Array z)
    {
        // x ^ y * log (x) -> log (x ^ (x ^ y))
        power (x, y, z);
        power (x, z, z); // FIXME: we bust infinity here :(
        log (z, z);
    }

    public void
    log (Array x, Array z)
    {
        var x_iter = x.iterator ();
        var z_iter = z.iterator ();
        while (x_iter.next () && z_iter.next ()) {
            *(double*) z_iter.get_pointer () = GLib.Math.log (*(double*) x_iter.get_pointer ());
        }
    }
}
