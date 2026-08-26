/* tlv.c -- Darwin thread-local variables.
 *
 * Nothing about ELF TLS carries over. Each _Thread_local variable has a
 * 24-byte descriptor in __DATA,__thread_vars; generated code loads word 0 and
 * calls it with the descriptor in x0, expecting this thread's address for that
 * variable back in x0 -- with every other register preserved, which is why the
 * entry point is hand-written assembly in tlv_asm.S.
 *
 * The loader patches thunk and key directly rather than implementing dyld's
 * self-installing __tlv_bootstrap. offset comes from the file untouched.
 * The per-thread block is the concatenation [__thread_data || __thread_bss].
 */
#define _GNU_SOURCE
#include "machorun.h"

#include <pthread.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    pthread_key_t  key;
    const uint8_t *init;      /* __thread_data bytes, in the parse mapping */
    size_t         init_size;
    size_t         total;     /* init_size + bss, i.e. the whole block */
    const char    *image;
} tlv_template;

static tlv_template templates[MR_MAX_IMAGES];
static int          ntemplates;

void *mr_tlv_get_addr_c(struct tlv_descriptor *desc);   /* called from tlv_asm.S */
void *mr_tlv_get_addr(struct tlv_descriptor *desc);     /* the asm entry point */

void *mr_tlv_get_addr_c(struct tlv_descriptor *desc)
{
    uint8_t *block = pthread_getspecific((pthread_key_t)desc->key);
    if (!block) {
        tlv_template *t = NULL;
        for (int i = 0; i < ntemplates; i++)
            if (templates[i].key == (pthread_key_t)desc->key) { t = &templates[i]; break; }
        if (!t)
            mr_die("TLV descriptor at %p names pthread key %lu, which no image registered",
                   (void *)desc, desc->key);
        block = calloc(1, t->total ? t->total : 1);
        if (!block) mr_die("out of memory allocating a %zu-byte TLV block for %s",
                           t->total, t->image);
        if (t->init_size) memcpy(block, t->init, t->init_size);
        if (pthread_setspecific(t->key, block) != 0)
            mr_die("pthread_setspecific failed for the TLV block of %s", t->image);
    }
    return block + desc->offset;
}

static void tlv_free(void *p) { free(p); }

void mr_tlv_setup(mr_image *im)
{
    const struct section_64 *vars = NULL, *data = NULL, *bss = NULL;
    uint64_t block_lo = UINT64_MAX, block_hi = 0;
    tlv_template *t;
    pthread_key_t key;

    for (int i = 0; i < im->nsegs; i++) {
        const mr_segment *s = &im->segs[i];
        for (uint32_t j = 0; j < s->nsects; j++) {
            const struct section_64 *sec = &s->sects[j];
            switch (sec->flags & SECTION_TYPE) {
            case S_THREAD_LOCAL_VARIABLES: vars = sec; break;
            case S_THREAD_LOCAL_REGULAR:   data = sec; break;
            case S_THREAD_LOCAL_ZEROFILL:  bss = sec;  break;
            default: break;
            }
        }
    }

    if (!vars) {
        if (im->mh_flags & MH_HAS_TLV_DESCRIPTORS)
            mr_log("%s: MH_HAS_TLV_DESCRIPTORS but no __thread_vars section", im->path);
        return;
    }
    if (vars->size % sizeof(struct tlv_descriptor) != 0)
        mr_die("%s: __thread_vars is 0x%llx bytes, not a multiple of the 24-byte descriptor",
               im->path, (unsigned long long)vars->size);

    if (data) { block_lo = data->addr; block_hi = data->addr + data->size; }
    if (bss) {
        if (bss->addr < block_lo) block_lo = bss->addr;
        if (bss->addr + bss->size > block_hi) block_hi = bss->addr + bss->size;
    }
    if (block_lo == UINT64_MAX) { block_lo = 0; block_hi = 0; }

    if (ntemplates >= MR_MAX_IMAGES) mr_die("too many images with TLV");
    if (pthread_key_create(&key, tlv_free) != 0)
        mr_die("%s: pthread_key_create for TLV failed", im->path);

    t = &templates[ntemplates++];
    t->key = key;
    t->image = im->path;
    t->init_size = data ? (size_t)data->size : 0;
    t->total = (size_t)(block_hi - block_lo);
    t->init = data && data->offset ? mr_file_at(im, data->offset, data->size, "__thread_data")
                                   : NULL;
    if (t->init_size && !t->init) t->init_size = 0;

    im->tlv_key = (uint32_t)key;
    im->tlv_registered = 1;

    {
        uint64_t addr = vars->addr + (uint64_t)im->slide;
        size_t n = (size_t)(vars->size / sizeof(struct tlv_descriptor));
        for (size_t i = 0; i < n; i++) {
            struct tlv_descriptor *d = (struct tlv_descriptor *)(addr + i * sizeof(*d));
            d->thunk = mr_tlv_get_addr;
            d->key = (unsigned long)key;
        }
        mr_log("%s: %zu TLV descriptors patched, block is %zu bytes (%zu initialised)",
               im->path, n, t->total, t->init_size);
    }
}
