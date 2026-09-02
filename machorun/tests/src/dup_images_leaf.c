/* The leaf whose static's ADDRESS is the whole signal: one address means one
 * image, two means the loader mapped the same library twice. Built twice with
 * -DDUP_KIND=link|copy so the two halves of dup_images.c have distinct symbols
 * and can be linked into one executable. */
#define CAT2(a, b) a##b
#define CAT(a, b) CAT2(a, b)
static int token;
int *CAT(CAT(dup_, DUP_KIND), _token)(void) { return &token; }
