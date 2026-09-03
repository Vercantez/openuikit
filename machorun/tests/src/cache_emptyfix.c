/* cache_emptyfix -- load a dylib whose LC_DYLD_INFO_ONLY is all zeros.
 *
 * The executable does not bind a symbol out of the dylib (the dylib's
 * export_size is zero after empty-dyld-info). LC_LOAD_DYLIB + LC_RPATH
 * still map it, which is the Gate B case: libCombine.dylib is a linked
 * dependency that must LOAD, not exit 74. See docs/FIXTURES.md.
 */
#include <stdio.h>

int main(void)
{
    printf("emptyfix loaded\n");
    return 0;
}
