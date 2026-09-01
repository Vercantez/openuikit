/* image_table.c -- the process-wide, pointer-stable Mach-O image registry. */
#include "machorun.h"

#include <limits.h>

void mr_image_append(mr_image *im)
{
    size_t required;

    if (!im) mr_die("cannot register a null Mach-O image");
    /* nimages remains int because the loader's existing iteration and ordinal
     * APIs use int.  This is a representation bound, not a preallocated image
     * ceiling, and is checked before the addition can overflow. */
    if (MR.nimages == INT_MAX)
        mr_die("Mach-O image count exceeds the loader's INT_MAX representation");
    required = (size_t)MR.nimages + 1;
    MR.images = mr_grow_array(MR.images, &MR.image_capacity, required,
                              sizeof(*MR.images), "Mach-O image table");
    MR.images[MR.nimages++] = im;
}
