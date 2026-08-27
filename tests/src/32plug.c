/* The plugin 32_dlopen loads at runtime. Deliberately carries an initialiser,
 * a TLV and an exported symbol, because those are the three things a dlopen
 * has to do BEYOND mapping: run __mod_init_func, set up thread-local storage,
 * and make the export trie findable through a handle. */
#include <stdio.h>

int plug_state;
__thread int plug_tls;

__attribute__((constructor))
static void plug_init(void) { plug_state = 7; plug_tls = 11; }

int plug_answer(void);
int plug_answer(void) { return plug_state * 6; }

int plug_tls_value(void);
int plug_tls_value(void) { return plug_tls; }

/* Resolved from libSystem, which was loaded long before this image. A bind in
 * a dlopen'd image against an already-loaded one is the case that breaks if
 * fixups run in the wrong order. */
int plug_uses_libc(void);
int plug_uses_libc(void) { return (int)snprintf(0, 0, "%d", 12345); }
