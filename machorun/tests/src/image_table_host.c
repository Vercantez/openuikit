#include "machorun.h"

#include <assert.h>
#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/wait.h>
#include <unistd.h>

static void expect_loader_failure(void (*body)(void))
{
    pid_t child = fork();
    int status = 0;
    assert(child >= 0);
    if (child == 0) {
        body();
        _exit(99);
    }
    assert(waitpid(child, &status, 0) == child);
    assert(WIFEXITED(status));
    assert(WEXITSTATUS(status) == 70);
}

static void overflow_element_count(void)
{
    size_t capacity = 0;
    (void)mr_grow_array(NULL, &capacity, SIZE_MAX, 2, "test image vector");
}

static void overflow_image_count(void)
{
    mr_image image = { 0 };
    MR.nimages = INT_MAX;
    mr_image_append(&image);
}

int main(void)
{
    enum { image_count = 257 };
    mr_image *objects = calloc(image_count, sizeof(*objects));
    mr_image *early_handle;

    assert(objects != NULL);
    for (int i = 0; i < image_count; i++) {
        mr_image_append(&objects[i]);
        assert(MR.images[i] == &objects[i]);
    }
    early_handle = MR.images[3];
    assert(MR.nimages == image_count);
    assert(MR.image_capacity >= image_count);
    assert(early_handle == &objects[3]);
    assert(MR.images[3] == early_handle);

    expect_loader_failure(overflow_element_count);
    expect_loader_failure(overflow_image_count);

    printf("MACHORUN_IMAGE_TABLE_HOST_OK images=%d capacity=%zu "
           "handles=stable overflow=fail-closed\n",
           MR.nimages, MR.image_capacity);
    free(MR.images);
    free(objects);
    return 0;
}
