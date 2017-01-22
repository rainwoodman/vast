#ifndef __VAST_CL_TENSOR_H__
#define __VAST_CL_TENSOR_H__

typedef struct _VastTensor VastTensor;

struct __attribute__ ((packed)) _VastTensor
{
    // size_t is platform-dependant, so instead we use 64 bit fields.
    unsigned long scalar_type;
    unsigned long scalar_size;
    unsigned long dimension;
    unsigned long shape[32];
    long          strides[32];
    unsigned long origin;
};

/**
 * vast_tensor_get_offset_for_index:
 * @self: The #VastTensor
 * @index: an index which size is given by #
 *
 * Returns:
 */
inline size_t
vast_tensor_get_offset_for_index (VastTensor *self, unsigned int *index)
{
    size_t offset;
    int i;

    offset = self->origin;

    for (i = 0; i < self->dimension; i++) {
        offset += index[i] * self->strides[i];
    }

    return offset;
}

/**
 * vast_tensor_foreach:
 * @arr: The #VastTensor being iterated
 * @arr_offset: Offset in bytes to retreive the corresponding element in the
 * from the actual tensor pointer
 *
 * Iterate in row-major order the given tensor or tensors if varidic arguments
 * are being used. If more arguments are being used, they alternate among
 * #VastTensor and #size_t types.
 */
#define vast_tensor_foreach(arr,arr_offset,...)

#endif /* __VAST_CL_TENSOR_H__ */
