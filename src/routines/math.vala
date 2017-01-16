namespace Vast.Math
{
    public void
    add (Tensor x, Tensor y, Tensor z)
    {
        var x_iter = x.iterator ();
        var y_iter = y.iterator ();
        var z_iter = z.iterator ();
        while (x_iter.next () && y_iter.next () && z_iter.next ()) {
            *(double*) z_iter.get_pointer () = *(double*) x_iter.get_pointer () + *(double*) y_iter.get_pointer ();
        }
    }

    public void
    negative (Tensor x, Tensor z)
        requires (x.size == z.size)
    {
        var x_iter = x.iterator ();
        var z_iter = z.iterator ();
        while (x_iter.next () && z_iter.next ()) {
            *(double*) z_iter.get_pointer () = -*(double*) x_iter.get_pointer ();
        }
    }

    public void
    multiply (Tensor x, Tensor y, Tensor z)
    {
        var x_iter = x.iterator ();
        var y_iter = y.iterator ();
        var z_iter = z.iterator ();
        while (x_iter.next () && y_iter.next () && z_iter.next ()) {
            *(double*) z_iter.get_pointer () = *(double*) x_iter.get_pointer () * *(double*) y_iter.get_pointer ();
        }
    }

    [Vast (gradient_z_x_function = "math_cos")]
    public void
    sin (Tensor x, Tensor z)
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
    cos (Tensor x, Tensor z)
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
    cos_gradient_z_x (Tensor x, Tensor z)
    {
        sin (x, z);
        negative (z, z);
    }

    public void
    power (Tensor x, Tensor y, Tensor z)
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
    power_gradient_z_x (Tensor x, Tensor y, Tensor z)
    {
        z.fill_from_value (-1);
        add (y, z, z);      // z = a - z = a - 1
        power (x, z, z);    // z = x ^ z = x ^ (a - 1)
        multiply (y, z, z); // z = a * z = a * x ^ (a - 1)
    }

    public void
    power_gradient_z_y (Tensor x, Tensor y, Tensor z, Tensor tmp)
    {
        // x ^ y * log (x)
        power (x, y, z);
        log (x, tmp);
        multiply (z, tmp, z);
    }

    public void
    log (Tensor x, Tensor z)
    {
        var x_iter = x.iterator ();
        var z_iter = z.iterator ();
        while (x_iter.next () && z_iter.next ()) {
            *(double*) z_iter.get_pointer () = GLib.Math.log (*(double*) x_iter.get_pointer ());
        }
    }
}
