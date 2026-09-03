#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>

/*
 * Loader-process probe for the same RTLD_DEFAULT dlsym path machorun uses
 * for `_glibc_*` (name + 7). Run it under the composed LD_PRELOAD so a
 * miss is the ELF helper / visibility story and a hit isolates the
 * remaining failure to machorun's from->is_runtime gate.
 */
int main(int argc, char **argv)
{
    int failed = 0;

    if (argc < 2) {
        fprintf(stderr, "usage: host_preload_dlsym_probe SYMBOL...\n");
        return 2;
    }
    for (int i = 1; i < argc; i++) {
        void *symbol = dlsym(RTLD_DEFAULT, argv[i]);
        if (symbol == NULL) {
            fprintf(stderr, "dlsym miss: %s (%s)\n", argv[i], dlerror());
            failed = 1;
            continue;
        }
        printf("dlsym hit: %s\n", argv[i]);
    }
    return failed;
}
