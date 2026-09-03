/* cache_emptyfix_lib -- the dylib for cache_layout_emptyfix.
 *
 * libCombine.dylib's shape: a __DATA_CONST segment with file bytes,
 * LC_DYLD_INFO_ONLY present, every size zero, no LC_DYLD_CHAINED_FIXUPS.
 * Integers only — no pointers — so a classic-target link already has
 * rebase/bind/weak/lazy of 0. tests/build_fixtures.sh then runs
 * pack_macho.py empty-dyld-info to zero export_size as well (and to
 * rewrite chained-to-empty if ld64.lld insists on LC_DYLD_CHAINED_FIXUPS).
 */
__attribute__((used, section("__DATA_CONST,__const")))
const int emptyfix_table[8] = { 1, 2, 3, 4, 5, 6, 7, 8 };
