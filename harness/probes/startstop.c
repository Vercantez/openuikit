#define _GNU_SOURCE
#include <stddef.h>
#include <stdio.h>
#include <link.h>
#include <elf.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>
#include <string.h>

extern const void *__start_objc_classlist[] __attribute__((weak));
extern const void *__stop_objc_classlist[]  __attribute__((weak));

static int cb(struct dl_phdr_info *info, size_t sz, void *data) {
    printf("image: name='%s' addr=%p phnum=%d\n", info->dlpi_name, (void*)info->dlpi_addr, info->dlpi_phnum);
    return 0;
}
int main(void) {
    printf("__start_objc_classlist=%p __stop_objc_classlist=%p  n=%td\n",
           (void*)__start_objc_classlist, (void*)__stop_objc_classlist,
           (ptrdiff_t)(__stop_objc_classlist - __start_objc_classlist));
    dl_iterate_phdr(cb, 0);
    return 0;
}
