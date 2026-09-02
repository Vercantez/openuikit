#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <dlfcn.h>
#include <sys/mman.h>
static int g;
int main(int argc, char**argv){
    int stackvar;
    void *m = malloc(64);
    void *big = malloc(4*1024*1024);
    void *mm = mmap(0, 65536, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANON, -1, 0);
    void *lib = dlsym(RTLD_DEFAULT, "printf");
    printf("pagesize   = %ld\n", sysconf(_SC_PAGESIZE));
    printf("text(main) = %018p  bits=%d\n", (void*)main, 64-__builtin_clzll((unsigned long long)(uintptr_t)main));
    printf("data(g)    = %018p  bits=%d\n", (void*)&g, 64-__builtin_clzll((unsigned long long)(uintptr_t)&g));
    printf("heap small = %018p  bits=%d\n", m, 64-__builtin_clzll((unsigned long long)(uintptr_t)m));
    printf("heap big   = %018p  bits=%d\n", big, 64-__builtin_clzll((unsigned long long)(uintptr_t)big));
    printf("mmap anon  = %018p  bits=%d\n", mm, 64-__builtin_clzll((unsigned long long)(uintptr_t)mm));
    printf("libc printf= %018p  bits=%d\n", lib, 64-__builtin_clzll((unsigned long long)(uintptr_t)lib));
    printf("stack      = %018p  bits=%d\n", (void*)&stackvar, 64-__builtin_clzll((unsigned long long)(uintptr_t)&stackvar));
    return 0;
}
