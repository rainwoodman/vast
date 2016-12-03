#include <glib-object.h>

void*
_vast_array_value_get_data (GValue *val)
{
    return &val->data[0];
}
