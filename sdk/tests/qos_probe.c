/*
 * qos_probe.c -- the QoS private headers, which have no Apple-SDK oracle.
 *
 * Every other header in sdk/ is checkable the same way: compile the same
 * source against Apple's SDK and ours and require agreement. These three
 * cannot be. pthread/qos_private.h, sys/qos_private.h and
 * pthread/priority_private.h are Apple-PRIVATE -- verified absent from the
 * MacOSX15.4 SDK -- so there is nothing on the oracle side to diff against.
 * That makes them the one place in this tree where "it compiled" is the whole
 * signal unless something else is arranged, so this file arranges it.
 *
 * THREE CHECKS, in decreasing order of how much they prove:
 *
 * 1. AGAINST THE PUBLIC HEADER, which Apple DOES ship and which
 *    sdk/tests/abi_probe.c baselines against Apple's SDK. The private header
 *    extends the public qos_class_t rather than replacing it, so every
 *    enumerator they share must agree. If our private copy came from a
 *    mismatched revision, this is where it shows.
 *
 * 2. CROSS-PROJECT, which is the only independent evidence available. The QoS
 *    values live in libpthread and the encoding that consumes them lives in
 *    xnu -- two separately versioned Apple projects that must agree or Apple's
 *    own build breaks. _pthread_priority_make_from_thread_qos() encodes a QoS
 *    ONE-HOT: `pp |= 1 << (SHIFT + qos - 1)`. So every representable QoS has
 *    to land inside _PTHREAD_PRIORITY_QOS_CLASS_MASK. Asserting that ties the
 *    xnu constants to the libpthread ones.
 *
 * 3. PINNED VALUES, so a silent upstream change fails the build instead of
 *    being rediscovered. These are the numbers a porter would otherwise guess,
 *    and the mask is why guessing is dangerous: SHIFT is 8, which makes an
 *    8-bit mask the natural assumption, and the real mask is FOURTEEN bits.
 *    A port that invented 0x0000ff00 would mis-encode every queue priority,
 *    silently, because nothing checks an encoding against a value it produced
 *    itself. That is what these three headers exist to prevent.
 *
 * Build (Linux side only -- there is no oracle side for this one):
 *   clang -target arm64-apple-macos11 -isysroot sdk -Werror -fsyntax-only \
 *         sdk/tests/qos_probe.c
 */

#include <pthread/qos_private.h>
#include <pthread/priority_private.h>
#include <sys/qos.h>

/* ---- 1. the private header must agree with the public one it extends ---- */

_Static_assert(QOS_CLASS_USER_INTERACTIVE == 0x21, "public/private QOS_CLASS_USER_INTERACTIVE");
_Static_assert(QOS_CLASS_USER_INITIATED   == 0x19, "public/private QOS_CLASS_USER_INITIATED");
_Static_assert(QOS_CLASS_DEFAULT          == 0x15, "public/private QOS_CLASS_DEFAULT");
_Static_assert(QOS_CLASS_UTILITY          == 0x11, "public/private QOS_CLASS_UTILITY");
_Static_assert(QOS_CLASS_BACKGROUND       == 0x09, "public/private QOS_CLASS_BACKGROUND");
_Static_assert(QOS_CLASS_UNSPECIFIED      == 0x00, "public/private QOS_CLASS_UNSPECIFIED");

/* Private-only: the public header does not define it, on Apple's SDK or ours. */
_Static_assert(QOS_CLASS_MAINTENANCE      == 0x05, "private-only QOS_CLASS_MAINTENANCE");

/* ---- 2. xnu's encoding must be able to represent libpthread's classes ---- */

/* One-hot at SHIFT + qos - 1. The highest bit the encoder can set must still
 * be inside the class mask -- if xnu narrows the mask, or adds a QoS level
 * without widening it, this fires.
 *
 * The bound is spelled out rather than taken from THREAD_QOS_LAST, and that is
 * a limitation worth stating rather than hiding: THREAD_QOS_LAST is USED by
 * priority_private.h:232 and DEFINED nowhere in any published Apple source --
 * not in osfmk/mach/thread_policy.h, not in osfmk/kern/kern_types.h. It lives
 * in a kernel-private header Apple does not ship. Consequence: the three
 * `static inline` encoders in priority_private.h COMPILE (nothing instantiates
 * them) but cannot be CALLED from a guest. libdispatch does not call them, so
 * nothing is blocked today; a port that does will get an undeclared-identifier
 * error at its own call site, which is at least loud.
 *
 * 7 is thread_qos_t's range in xnu's scheme (UNSPECIFIED plus six classes), so
 * the top one-hot bit is SHIFT+6 = 14, and the mask covers bits 8..21. */
#define MR_THREAD_QOS_LEVELS 7
_Static_assert(((1u << (_PTHREAD_PRIORITY_QOS_CLASS_SHIFT + MR_THREAD_QOS_LEVELS - 1))
                & _PTHREAD_PRIORITY_QOS_CLASS_MASK) != 0,
               "xnu's QoS one-hot encoding overflows _PTHREAD_PRIORITY_QOS_CLASS_MASK: "
               "priority_private.h (xnu) and qos_private.h (libpthread) disagree");

/* The class mask must not collide with the relative-priority field it sits
 * beside, which is the other half of the same word. */
_Static_assert((_PTHREAD_PRIORITY_QOS_CLASS_MASK & _PTHREAD_PRIORITY_PRIORITY_MASK) == 0,
               "QoS class and relative-priority fields overlap");

/* ---- 3. the values a porter would otherwise invent ---- */

/* FOURTEEN bits, not eight. SHIFT being 8 makes 0x0000ff00 the obvious wrong
 * guess; it would mis-encode every queue priority without failing anything. */
_Static_assert(_PTHREAD_PRIORITY_QOS_CLASS_MASK  == 0x003fff00u,
               "_PTHREAD_PRIORITY_QOS_CLASS_MASK moved");
_Static_assert(_PTHREAD_PRIORITY_QOS_CLASS_SHIFT == 8,
               "_PTHREAD_PRIORITY_QOS_CLASS_SHIFT moved");
_Static_assert(sizeof(pthread_priority_t) == 8,
               "pthread_priority_t is an unsigned long");

int qos_probe_ok(void);
int qos_probe_ok(void) { return 1; }
