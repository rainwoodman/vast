#include <glib.h>
#include <glib-object.h>

#include "vast.h"

VastTensor *
vast_tensor_construct_zeroed (GType   object_type,
                              GType   scalar_type,
                              gsize   scalar_size,
                              gsize   dimension,
                              gsize  *shape,
                              gssize *strides,
                              gsize   origin)
{
    gint i;
    gsize len;

    len = scalar_size;
    for (i = 0; i < dimension; i++) {
        len *= shape[i];
    }

    return vast_tensor_construct (object_type,
                                  scalar_type,
                                  scalar_size,
                                  dimension,
                                  shape,
                                  strides,
                                  origin,
                                  g_bytes_new_take (g_malloc0 (len), len));
}

VastTensor *
vast_tensor_construct_wrap_scalar (GType    object_type,
                                   GType    scalar_type,
                                   gsize    scalar_size,
                                   gpointer scalar)
{
    return vast_tensor_construct (object_type,
                                  scalar_type,
                                  scalar_size,
                                  0,
                                  NULL,
                                  NULL,
                                  0,
                                  g_bytes_new_take (scalar, scalar_size));
}

void*
_vast_tensor_value_get_data (GValue *val)
{
    return &val->data[0];
}
