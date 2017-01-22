#ifndef __VAST_CL_TENSOR_H__
#define __VAST_CL_TENSOR_H__

#include <vast.h>

#include <CL/cl.h>

G_BEGIN_DECLS

typedef struct _VastClTensor VastClTensor;

struct __attribute__ ((packed)) _VastClTensor
{
    cl_ulong scalar_type;
    cl_ulong scalar_size;
    cl_ulong dimension;
    cl_ulong shape[32];
    cl_long  strides[32];
    cl_ulong origin;
};

void           vast_cl_tensor_init_from_tensor (VastClTensor       *self,
                                                VastTensor         *arr);
VastClTensor * vast_cl_tensor_copy             (const VastClTensor *self);
void           vast_cl_tensor_free             (VastClTensor       *self);

G_END_DECLS

#endif /* __VAST_CL_TENSOR_H__ */
