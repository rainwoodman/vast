#include <glib.h>
#include <glib-object.h>

GBytes*
_vast_array_bytes_new_zeroed (gsize len)
{
    return g_bytes_new_take (g_malloc0 (len), len);
}

void*
_vast_array_value_get_data (GValue *val)
{
    return &val->data[0];
}
