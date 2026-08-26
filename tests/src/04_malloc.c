/* 04_malloc -- rung (d): the Darwin allocator surface.
 *
 * malloc / calloc / realloc / free / strdup / malloc_size-free behaviour.
 * Everything printed is derived from contents, never from an address, so the
 * output is identical on macOS and under machorun.
 *
 * Loader/libSystem must provide: _malloc, _calloc, _realloc, _free, _strdup,
 * _memset, _memcpy, _strlen, _posix_memalign.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(void) {
    char *p = malloc(64);
    if (!p) return 1;
    memset(p, 'A', 63);
    p[63] = '\0';
    printf("malloc len=%zu first=%c last=%c\n", strlen(p), p[0], p[62]);

    int *c = calloc(16, sizeof(int));
    if (!c) return 2;
    int sum = 0;
    for (int i = 0; i < 16; i++) sum += c[i];
    printf("calloc zeroed sum=%d\n", sum);

    for (int i = 0; i < 16; i++) c[i] = i * i;
    c = realloc(c, 32 * sizeof(int));
    if (!c) return 3;
    printf("realloc kept c[15]=%d\n", c[15]);

    char *d = strdup("duplicated");
    if (!d) return 4;
    printf("strdup=%s len=%zu\n", d, strlen(d));

    void *a = NULL;
    if (posix_memalign(&a, 4096, 8192) != 0) return 5;
    printf("posix_memalign aligned=%d\n", ((unsigned long)a & 4095) == 0);

    free(a);
    free(d);
    free(c);
    free(p);

    /* Churn: allocator must survive a mixed workload. */
    void *v[128];
    for (int i = 0; i < 128; i++) v[i] = malloc((size_t)(i * 37 + 1));
    for (int i = 0; i < 128; i += 2) free(v[i]);
    for (int i = 0; i < 128; i += 2) v[i] = malloc(9000);
    for (int i = 0; i < 128; i++) free(v[i]);
    printf("churn ok\n");
    return 0;
}
