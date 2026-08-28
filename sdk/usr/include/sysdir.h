/*
 * sysdir.h -- machorun's clean-room stand-in.
 *
 * NOT Apple's header, and it could not be: `sysdir` is not published in ANY
 * apple-oss-distributions release. It is not in Libc (the whole 1,602-path tree
 * at the pinned tag contains no `sysdir` anything), not in Libinfo, not in
 * xnu. The interface exists only in the shipped SDK, so `sdk/MANIFEST.tsv`
 * lists it as `local` -- same category as `mach/vm_map.h`, and for the same
 * reason: the upstream this repository is allowed to redistribute does not
 * carry it.
 *
 * SO EVERY NUMBER BELOW IS PINNED BY TEST RATHER THAN BY TRANSCRIPTION.
 * `sdk/tests/abi_probe.c` prints all 26 enumerators, and
 * `scripts/sdk_abi_probe.sh` compiles that probe TWICE -- on macOS against
 * Apple's own SDK, on Linux against this header -- and requires the two
 * outputs to be byte-identical. A value I got wrong fails on Apple's SDK
 * saying so. That is the same standard `sdk/local/TargetConditionals.h` is
 * held to, and it is stronger than "I read Apple's copy carefully", because
 * the check runs again every time anybody touches this file.
 *
 * WHAT MACHORUN ACTUALLY DOES WITH THESE. Both routines are implemented in
 * darwin/src/posix.c and both return 0 -- an EMPTY enumeration. Linux has no
 * Darwin domains: no ~/Library/Caches, no /System, no user-versus-local
 * distinction. 0 is the API's own "no more results", so a correct caller's
 * loop simply does not execute, which is the only answer that cannot be
 * mistaken for a real path. The enumerators are therefore ACCEPTED AND
 * IGNORED, not interpreted -- see docs/UNIMPLEMENTED.md#sysdir-empty, which
 * also records what is not known (what CoreFoundation does with an empty
 * enumeration).
 *
 * The header is here anyway because the alternative is worse in the way this
 * project has been bitten by before: libSystem already EXPORTS both symbols,
 * so without a declaration a caller gets "implicit declaration of function"
 * and, in Swift, no `sysdir` module at all -- a gap that looks like a missing
 * implementation when the implementation is present.
 */

#ifndef __SYSTEM_DIRECTORIES_H__
#define __SYSTEM_DIRECTORIES_H__

#include <os/base.h>
#include <sys/cdefs.h>

/* The directory being asked about. Values 1..22 are contiguous; the two
 * "all of them" queries are at 100 and 101 with a deliberate gap, which is
 * why this cannot be written as a bare sequence. */
OS_ENUM(sysdir_search_path_directory, unsigned int,
    SYSDIR_DIRECTORY_APPLICATION            = 1,
    SYSDIR_DIRECTORY_DEMO_APPLICATION       = 2,
    SYSDIR_DIRECTORY_DEVELOPER_APPLICATION  = 3,
    SYSDIR_DIRECTORY_ADMIN_APPLICATION      = 4,
    SYSDIR_DIRECTORY_LIBRARY                = 5,
    SYSDIR_DIRECTORY_DEVELOPER              = 6,
    SYSDIR_DIRECTORY_USER                   = 7,
    SYSDIR_DIRECTORY_DOCUMENTATION          = 8,
    SYSDIR_DIRECTORY_DOCUMENT               = 9,
    SYSDIR_DIRECTORY_CORESERVICE            = 10,
    SYSDIR_DIRECTORY_AUTOSAVED_INFORMATION  = 11,
    SYSDIR_DIRECTORY_DESKTOP                = 12,
    SYSDIR_DIRECTORY_CACHES                 = 13,
    SYSDIR_DIRECTORY_APPLICATION_SUPPORT    = 14,
    SYSDIR_DIRECTORY_DOWNLOADS              = 15,
    SYSDIR_DIRECTORY_INPUT_METHODS          = 16,
    SYSDIR_DIRECTORY_MOVIES                 = 17,
    SYSDIR_DIRECTORY_MUSIC                  = 18,
    SYSDIR_DIRECTORY_PICTURES               = 19,
    SYSDIR_DIRECTORY_PRINTER_DESCRIPTION    = 20,
    SYSDIR_DIRECTORY_SHARED_PUBLIC          = 21,
    SYSDIR_DIRECTORY_PREFERENCE_PANES       = 22,
    SYSDIR_DIRECTORY_ALL_APPLICATIONS       = 100,
    SYSDIR_DIRECTORY_ALL_LIBRARIES          = 101,
);

/* A MASK, not an enum: the caller ORs these together, and _ALL is 0x0ffff
 * rather than the OR of the four defined bits, so that domains Apple adds
 * later are included by an existing caller. */
OS_OPTIONS(sysdir_search_path_domain_mask, unsigned int,
    SYSDIR_DOMAIN_MASK_USER                 = (1UL << 0),
    SYSDIR_DOMAIN_MASK_LOCAL                = (1UL << 1),
    SYSDIR_DOMAIN_MASK_NETWORK              = (1UL << 2),
    SYSDIR_DOMAIN_MASK_SYSTEM               = (1UL << 3),
    SYSDIR_DOMAIN_MASK_ALL                  = 0x0ffff,
);

/* The iteration cursor. Zero means "no more results" -- which is both the
 * terminating value and what machorun's implementation returns immediately. */
typedef unsigned int sysdir_search_path_enumeration_state;

__BEGIN_DECLS

extern sysdir_search_path_enumeration_state
sysdir_start_search_path_enumeration(sysdir_search_path_directory_t dir,
                                     sysdir_search_path_domain_mask_t domainMask);

/* `path` must have room for PATH_MAX bytes. machorun's implementation writes
 * a NUL there rather than leaving the caller's buffer untouched, so a caller
 * that ignores the return value reads an empty string instead of a stale one. */
extern sysdir_search_path_enumeration_state
sysdir_get_next_search_path_enumeration(sysdir_search_path_enumeration_state state,
                                        char *path);

__END_DECLS

#endif /* __SYSTEM_DIRECTORIES_H__ */
