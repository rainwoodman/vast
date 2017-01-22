#include "vast-cl-tensor.h"

G_DEFINE_BOXED_TYPE (VastClTensor, vast_cl_tensor, vast_cl_tensor_copy, vast_cl_tensor_free)

/**
 * vast_cl_tensor_init_from_tensor:
 * @self: The #VastClTensor
 * @arr: The #VastTensor
 *
 * Pack the meta-data of a #VastTensor into a struct suitable for OpenCL. The
 * actual data has to be passed separately, preferably via a mapped buffer.
 */
void
vast_cl_tensor_init_from_tensor (VastClTensor *self, VastTensor *arr)
{
    gint i;

    g_return_if_fail (self != NULL);
    g_return_if_fail (VAST_IS_TENSOR (arr));

    // TODO: check for endianess of device against native

    self->scalar_size = vast_tensor_get_scalar_size (arr);
    self->dimension   = vast_tensor_get_dimension (arr);

    for (i = 0; i < 32; i++) {
        self->shape[i]   = vast_tensor_get_shape (arr)[i];
        self->strides[i] = vast_tensor_get_strides (arr)[i];
    }

    self->origin = vast_tensor_get_origin (arr);
}

VastClTensor *
vast_cl_tensor_copy (const VastClTensor *self)
{
    VastClTensor *ret;

    g_return_val_if_fail (self != NULL, NULL);

    ret = g_malloc (sizeof (VastClTensor));
    memcpy (ret, self, sizeof (VastClTensor));

    return ret;
}

void
vast_cl_tensor_free (VastClTensor *self)
{
    g_free (self);
}
