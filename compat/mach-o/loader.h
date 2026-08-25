/*
 * compat/mach-o/loader.h  --  objc4-linux
 *
 * There is no Mach-O here. But objc4 uses `const struct mach_header *` as its
 * opaque per-image identity token in ~37 places, including public SPI
 * signatures in <objc/objc-internal.h> that Swift's runtime calls. Renaming it
 * would fork the ABI. So we keep the name and make it OUR record: libobjc
 * allocates one of these per ELF image at registration time and hands out
 * pointers to it. Nothing ever dereferences it except `->filetype`
 * (objc-private.h `isBundle()`), which we set ourselves.
 *
 * See docs/UNIMPLEMENTED.md. The layout mirrors Mach-O's so that any code that
 * reads `magic` to sanity-check an image still sees something coherent.
 */
#ifndef _OBJC4LINUX_MACHO_LOADER_H
#define _OBJC4LINUX_MACHO_LOADER_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Our own magic: "ELF!" little-endian-ish. Deliberately NOT MH_MAGIC_64, so a
 * stray Mach-O parser fails loudly instead of misreading our record. */
#define OBJC4LINUX_IMAGE_MAGIC 0x21464c45u

struct mach_header {
    uint32_t magic;
    int32_t  cputype;
    int32_t  cpusubtype;
    uint32_t filetype;
    uint32_t ncmds;
    uint32_t sizeofcmds;
    uint32_t flags;
};

struct mach_header_64 {
    uint32_t magic;
    int32_t  cputype;
    int32_t  cpusubtype;
    uint32_t filetype;
    uint32_t ncmds;
    uint32_t sizeofcmds;
    uint32_t flags;
    uint32_t reserved;
};

/* filetype values objc4 tests against. */
#define MH_OBJECT   0x1
#define MH_EXECUTE  0x2
#define MH_DYLIB    0x6
#define MH_BUNDLE   0x8
#define MH_DYLINKER 0x7

#define MH_MAGIC    0xfeedfaceu
#define MH_CIGAM    0xcefaedfeu
#define MH_MAGIC_64 0xfeedfacfu
#define MH_CIGAM_64 0xcffaedfeu

#define SEG_TEXT      "__TEXT"
#define SEG_DATA      "__DATA"
#define SEG_OBJC      "__OBJC"
#define SEG_LINKEDIT  "__LINKEDIT" 

/* Load commands / segments: referenced only by code we compile out. Declared
 * so that headers mentioning them parse. */
struct load_command      { uint32_t cmd; uint32_t cmdsize; };
struct segment_command   { uint32_t cmd; uint32_t cmdsize; char segname[16];
                           uint32_t vmaddr, vmsize, fileoff, filesize;
                           int32_t maxprot, initprot; uint32_t nsects, flags; };
struct segment_command_64 { uint32_t cmd; uint32_t cmdsize; char segname[16];
                           uint64_t vmaddr, vmsize, fileoff, filesize;
                           int32_t maxprot, initprot; uint32_t nsects, flags; };
struct section           { char sectname[16]; char segname[16];
                           uint32_t addr, size, offset, align, reloff, nreloc, flags,
                           reserved1, reserved2; };
struct section_64        { char sectname[16]; char segname[16];
                           uint64_t addr, size; uint32_t offset, align, reloff,
                           nreloc, flags, reserved1, reserved2, reserved3; };

union lc_str { uint32_t offset; };

struct dylib {
    union lc_str name;
    uint32_t timestamp;
    uint32_t current_version;
    uint32_t compatibility_version;
};
struct dylib_command { uint32_t cmd; uint32_t cmdsize; struct dylib dylib; };

#define LC_SEGMENT        0x1
#define LC_LOAD_DYLIB     0xc
#define LC_ID_DYLIB       0xd
#define LC_LOAD_WEAK_DYLIB 0x18
#define LC_REEXPORT_DYLIB  0x1f
#define LC_LOAD_UPWARD_DYLIB 0x23
#define LC_SEGMENT_64     0x19
#define LC_UUID           0x1b

#ifdef __cplusplus
}
#endif

#endif
