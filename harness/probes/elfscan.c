#define _GNU_SOURCE
#include <stdio.h>
#include <stddef.h>
#include <link.h>
#include <elf.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>
#include <string.h>

// Recover a named ELF section's runtime address for a loaded image by reading
// the section header table from the on-disk file and adding dlpi_addr.
static void scan(const char *path, ElfW(Addr) base) {
    int fd = open(path, O_RDONLY);
    if (fd < 0) { printf("   (cannot open %s)\n", path); return; }
    struct stat st; fstat(fd, &st);
    void *m = mmap(0, st.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
    close(fd);
    if (m == MAP_FAILED) { printf("   (mmap failed)\n"); return; }
    ElfW(Ehdr) *eh = m;
    ElfW(Shdr) *sh = (void*)((char*)m + eh->e_shoff);
    const char *shstr = (char*)m + sh[eh->e_shstrndx].sh_offset;
    for (int i = 0; i < eh->e_shnum; i++) {
        const char *nm = shstr + sh[i].sh_name;
        if (strncmp(nm, "objc_", 5) == 0) {
            printf("   %-18s sh_addr=%#lx size=%lu -> runtime %p\n",
                   nm, (unsigned long)sh[i].sh_addr, (unsigned long)sh[i].sh_size,
                   (void*)(base + sh[i].sh_addr));
        }
    }
    munmap(m, st.st_size);
}
static int cb(struct dl_phdr_info *info, size_t sz, void *data) {
    const char *n = info->dlpi_name && *info->dlpi_name ? info->dlpi_name : "(main exe)";
    printf("image: %-40s base=%p\n", n, (void*)info->dlpi_addr);
    if (strstr(n, "probe") || strstr(n, "exe") || !info->dlpi_name[0])
        scan(info->dlpi_name[0] ? info->dlpi_name : "/proc/self/exe", info->dlpi_addr);
    return 0;
}
int main(void) { dl_iterate_phdr(cb, 0); return 0; }
