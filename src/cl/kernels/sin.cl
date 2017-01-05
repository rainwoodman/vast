#include <cl/vast.h>

__kernel void
vast_sin (VastTensor       x,
          __global double *x_data,
          VastTensor       z,
          __global double *z_data)
{
    size_t x_offset;
    size_t z_offset;
    vast_tensor_foreach (x, x_offset, z, z_offset)
        *(x + x_offset) = sin (*(z + z_offset));
    }
}
