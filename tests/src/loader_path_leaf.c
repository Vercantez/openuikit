/* The leaf that gets found -- or that gets found INSTEAD.
 *
 * Built TWICE from this one file, into two directories, with LEAF_WHERE
 * naming which copy this is. That is the whole point of the fixture: the two
 * copies share a basename, so a dlopen that resolves @loader_path against the
 * wrong image does not fail, it succeeds and returns the other one.
 */
#ifndef LEAF_WHERE
#error "build this with -DLEAF_WHERE=\"...\" -- an unlabelled copy proves nothing"
#endif

const char *leaf_where(void);
const char *leaf_where(void) { return LEAF_WHERE; }
