public class Vast.StringFormatter : Vast.Formatter
{
    public StringFormatter (Tensor tensor)
    {
        Object (tensor: tensor);
    }

    private inline void
    _append_from_index (DataOutputStream @out, ssize_t[] index, Cancellable? cancellable = null) throws Error
    {
        // scalar style
        @out.put_byte ('\n', cancellable);
        if (index.length == tensor.rank) {
            @out.put_byte ('[');
            @out.put_string (tensor.get_value (index).strdup_contents (), cancellable);
            @out.put_byte (']', cancellable);
        }

        // vector style
        else if (index.length == tensor.rank - 1) {
            @out.put_byte ('[');
            for (var i = 0; i < tensor.shape[index.length]; i++) {
                if (i > 0)
                    @out.put_byte (' ');
                // index and print the scalar
                ssize_t[] subindex = index;
                subindex += i;
                @out.put_string (tensor.get_value (subindex).strdup_contents (), cancellable);
                if (i < tensor.shape[index.length] - 1)
                    @out.put_byte ('\n', cancellable);
            }
            @out.put_byte (']', cancellable);
        }

        // matrix style
        else if (index.length == tensor.rank - 2) {
            @out.put_byte ('[');
            // last dim is printed vertically
            for (var j = 0; j < tensor.shape[index.length + 1]; j++) {
                if (j > 0) {
                    @out.put_byte (' ', cancellable);
                }
                for (var i = 0; i < tensor.shape[index.length]; i++) {
                    if (i > 0) {
                        @out.put_byte (' ', cancellable);
                    }
                    @out.put_byte (j == 0 ? '[' : ' ');

                    // index and print the scalar
                    ssize_t[] subindex = index;
                    subindex += i;
                    subindex += j;
                    @out.put_string (tensor.get_value (subindex).strdup_contents (), cancellable);

                    if (j == tensor.shape[index.length + 1] - 1) {
                        @out.put_byte (']', cancellable);
                    } else {
                        @out.put_byte (',', cancellable);
                    }
                }
                if (j < tensor.shape[index.length + 1] - 1) {
                    @out.put_byte ('\n', cancellable);
                }
            }
            @out.put_byte (']', cancellable);
        }

        // embedded matrix style (humans can't see beyond!)
        else {
            @out.put_byte ('[');
            for (var i = 0; i < tensor.shape[index.length]; i++) {
                ssize_t[] subindex = index;
                subindex += i;
                _append_from_index (@out, subindex, cancellable);
            }
            @out.put_byte (']', cancellable);
        }
    }

    public override bool to_stream (OutputStream @out, Cancellable? cancellable = null) throws Error
    {
        _append_from_index (new DataOutputStream (@out), {}, cancellable);
        return true;
    }
}
