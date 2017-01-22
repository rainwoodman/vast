using Gocl;

public extern struct Vast.ClTensor
{
    public ClTensor.from_tensor (Vast.Tensor arr);
    uint scalar_size;
    uint dimension;
    uint shape[32];
    int strides[32];
    uint origin;
}

public int main (string[] args)
{
    Test.init (ref args);

    Test.add_func ("/gocl", () => {
        var context = Context.get_default_cpu_sync ();
        var device  = context.get_device_by_index (0);

        string kernel_contents;
        try {
            FileUtils.get_contents (Test.build_filename (Test.FileType.DIST, "..", "src", "cl", "kernels", "sin.cl"),
                                    out kernel_contents);
        } catch (Error err) {
            assert_not_reached ();
        }

        var program = new Program (context, {kernel_contents});

        assert (program.build_sync ("-I%s".printf (Test.build_filename (Test.FileType.DIST, "..", "src"))));
        assert (Gocl.ProgramBuildStatus.SUCCESS == program.get_build_status (device));

        var kernel = program.get_kernel ("vast_sin");
        assert (kernel != null);
        assert (kernel is Gocl.Kernel);

        // allocate on the GPU
        var x_buf = new Buffer (context, BufferFlags.READ_WRITE, 10 * 10 * sizeof (double), 0);

        // map into virtual memory
        var mapped_buf = x_buf.map_as_bytes_sync (device.get_default_queue (),
                                                  BufferMapFlags.READ | BufferMapFlags.WRITE,
                                                  0,
                                                  (size_t) x_buf.size,
                                                  null);
        assert (null != mapped_buf);

        var x = new Vast.Tensor (typeof (double),
                                sizeof (double),
                                {10, 10},
                                {},
                                0,
                                mapped_buf);

        x.fill_from_value (Math.PI / 2);

        for (var i = 0; i < 10 * 10; i++) {
            assert (Math.PI / 2 == ((double[])mapped_buf.get_data ())[i]);
        }

        var z_buf = new Buffer (context, BufferFlags.READ_WRITE, 10 * 10 * sizeof (double), 0);

        var z = new Vast.Tensor (typeof (double),
                                sizeof (double),
                                {10, 10},
                                {},
                                0,
                                z_buf.map_as_bytes_sync (device.get_default_queue (), BufferMapFlags.READ, 0, 10 * 10 * sizeof (double), null));

        var x_cl_arr = Vast.ClTensor.from_tensor (x);
        var z_cl_arr = Vast.ClTensor.from_tensor (z);

        assert (sizeof (double) == x_cl_arr.scalar_size);
        assert (2 == x_cl_arr.dimension);
        assert (10 == x_cl_arr.shape[0]);
        assert (10 == x_cl_arr.shape[1]);
        assert (10 == x_cl_arr.strides[0]);
        assert (1 == x_cl_arr.strides[1]);
        assert (0 == x_cl_arr.origin);

        kernel.set_argument (0, sizeof (Vast.ClTensor), &x_cl_arr);
        kernel.set_argument_buffer (1, x_buf);

        kernel.set_argument (2, sizeof (Vast.ClTensor), &z_cl_arr);
        kernel.set_argument_buffer (3, z_buf);

        assert (kernel.run_in_device_sync (device, null));

        foreach (var ptr in z) {
            assert (1.0 == *(double*) ptr);
        }

        assert (x_buf.unmap_bytes (device.get_default_queue (), mapped_buf, null));
    });

    return Test.run ();
}
