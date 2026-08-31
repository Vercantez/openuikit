#ifndef OPEN_FOUNDATION_INTERNATIONALIZATION_GLOB_H
#define OPEN_FOUNDATION_INTERNATIONALIZATION_GLOB_H

/*
 * swift-foundation-icu's Darwin-only AppleLanguageBreakFactory includes
 * <glob.h>, although every glob use in the pinned source is inside #if 0.
 * The reduced Darwin SDK intentionally does not ship that otherwise unused
 * header.  Keep the source unmodified and provide the Darwin declarations so
 * the upstream translation unit remains buildable.
 */
#include <stddef.h>

typedef struct {
    size_t gl_pathc;
    char **gl_pathv;
    size_t gl_offs;
} glob_t;

#define GLOB_APPEND   0x0001
#define GLOB_NOESCAPE 0x2000
#define GLOB_NOSORT   0x0020
#define GLOB_TILDE    0x0800

#ifdef __cplusplus
extern "C" {
#endif
int glob(const char *, int, int (*)(const char *, int), glob_t *);
void globfree(glob_t *);
#ifdef __cplusplus
}
#endif

#endif
