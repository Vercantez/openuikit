/* macho.h -- the on-disk Mach-O format, as arm64 Apple toolchains emit it.
 *
 * Deliberately self-contained: no Apple headers, no mach-o headers at all. Every
 * constant here is one that docs/MACHO_NOTES.md measured on a real binary.
 * Structures are read straight out of a file mapping, so every field is a
 * fixed-width little-endian type and every struct is packed by construction.
 */
#ifndef MACHORUN_MACHO_H
#define MACHORUN_MACHO_H

#include <stdint.h>

/* ---------------------------------------------------------------- magic */
#define MH_MAGIC_64   0xfeedfacfu
#define MH_CIGAM_64   0xcffaedfeu
#define MH_MAGIC_32   0xfeedfaceu
#define FAT_MAGIC     0xcafebabeu   /* big-endian file, 32-bit fat_arch  */
#define FAT_CIGAM     0xbebafecau
#define FAT_MAGIC_64  0xcafebabfu
#define FAT_CIGAM_64  0xbfbafecau

#define CPU_TYPE_ARM64          0x0100000c
#define CPU_SUBTYPE_ARM64_ALL   0
#define CPU_SUBTYPE_ARM64E      2
#define CPU_SUBTYPE_MASK        0xff000000u

/* ------------------------------------------------------------- filetype */
#define MH_EXECUTE  0x2
#define MH_DYLIB    0x6
#define MH_BUNDLE   0x8

/* ---------------------------------------------------------------- flags */
#define MH_NOUNDEFS            0x00000001
#define MH_DYLDLINK            0x00000004
#define MH_TWOLEVEL            0x00000080
#define MH_WEAK_DEFINES        0x00008000
#define MH_BINDS_TO_WEAK       0x00010000
#define MH_PIE                 0x00200000
#define MH_HAS_TLV_DESCRIPTORS 0x00800000

/* -------------------------------------------------------- load commands */
#define LC_REQ_DYLD             0x80000000u
#define LC_SEGMENT_64           0x19
#define LC_SYMTAB               0x02
#define LC_DYSYMTAB             0x0b
#define LC_LOAD_DYLIB           0x0c
#define LC_ID_DYLIB             0x0d
#define LC_LOAD_DYLINKER        0x0e
#define LC_UNIXTHREAD           0x05
#define LC_UUID                 0x1b
#define LC_CODE_SIGNATURE       0x1d
#define LC_SEGMENT_SPLIT_INFO   0x1e
#define LC_FUNCTION_STARTS      0x26
#define LC_DATA_IN_CODE         0x29
#define LC_SOURCE_VERSION       0x2a
#define LC_BUILD_VERSION        0x32
#define LC_LOAD_WEAK_DYLIB      (0x18 | LC_REQ_DYLD)
#define LC_RPATH                (0x1c | LC_REQ_DYLD)
#define LC_REEXPORT_DYLIB       (0x1f | LC_REQ_DYLD)
#define LC_LAZY_LOAD_DYLIB      0x20
#define LC_LOAD_UPWARD_DYLIB    (0x23 | LC_REQ_DYLD)
#define LC_DYLD_INFO            0x22
#define LC_DYLD_INFO_ONLY       (0x22 | LC_REQ_DYLD)
#define LC_MAIN                 (0x28 | LC_REQ_DYLD)
#define LC_DYLD_EXPORTS_TRIE    (0x33 | LC_REQ_DYLD)
#define LC_DYLD_CHAINED_FIXUPS  (0x34 | LC_REQ_DYLD)

/* ---------------------------------------------------------- vm / section */
#define VM_PROT_READ    1
#define VM_PROT_WRITE   2
#define VM_PROT_EXECUTE 4
#define SG_READ_ONLY    0x10

#define SECTION_TYPE                0x000000ff
#define S_REGULAR                   0x0
#define S_ZEROFILL                  0x1
#define S_CSTRING_LITERALS          0x2
#define S_NON_LAZY_SYMBOL_POINTERS  0x6
#define S_LAZY_SYMBOL_POINTERS      0x7
#define S_SYMBOL_STUBS              0x8
#define S_MOD_INIT_FUNC_POINTERS    0x9
#define S_MOD_TERM_FUNC_POINTERS    0xa
#define S_THREAD_LOCAL_REGULAR      0x11
#define S_THREAD_LOCAL_ZEROFILL     0x12
#define S_THREAD_LOCAL_VARIABLES    0x13
#define S_INIT_FUNC_OFFSETS         0x16

/* ------------------------------------------------------------- structures */
struct mach_header_64 {
    uint32_t magic, cputype, cpusubtype, filetype, ncmds, sizeofcmds, flags, reserved;
};

struct load_command { uint32_t cmd, cmdsize; };

struct segment_command_64 {
    uint32_t cmd, cmdsize;
    char     segname[16];
    uint64_t vmaddr, vmsize, fileoff, filesize;
    uint32_t maxprot, initprot, nsects, flags;
};

struct section_64 {
    char     sectname[16], segname[16];
    uint64_t addr, size;
    uint32_t offset, align, reloff, nreloc, flags, reserved1, reserved2, reserved3;
};

struct dylib_command {
    uint32_t cmd, cmdsize, name_offset, timestamp, current_version, compat_version;
};

struct rpath_command { uint32_t cmd, cmdsize, path_offset; };

struct entry_point_command { uint32_t cmd, cmdsize; uint64_t entryoff, stacksize; };

struct dyld_info_command {
    uint32_t cmd, cmdsize;
    uint32_t rebase_off, rebase_size;
    uint32_t bind_off, bind_size;
    uint32_t weak_bind_off, weak_bind_size;
    uint32_t lazy_bind_off, lazy_bind_size;
    uint32_t export_off, export_size;
};

struct linkedit_data_command { uint32_t cmd, cmdsize, dataoff, datasize; };

struct symtab_command { uint32_t cmd, cmdsize, symoff, nsyms, stroff, strsize; };

struct nlist_64 {
    uint32_t n_strx;
    uint8_t  n_type, n_sect;
    uint16_t n_desc;
    uint64_t n_value;
};

struct fat_header { uint32_t magic, nfat_arch; };            /* big-endian */
struct fat_arch   { uint32_t cputype, cpusubtype, offset, size, align; };
struct fat_arch_64 { uint32_t cputype, cpusubtype; uint64_t offset, size; uint32_t align, reserved; };

/* --------------------------------------------------------- chained fixups */
struct dyld_chained_fixups_header {
    uint32_t fixups_version, starts_offset, imports_offset, symbols_offset;
    uint32_t imports_count, imports_format, symbols_format;
};

struct dyld_chained_starts_in_image {
    uint32_t seg_count;
    uint32_t seg_info_offset[1];   /* [seg_count] */
};

struct dyld_chained_starts_in_segment {
    uint32_t size;
    uint16_t page_size;            /* a property of the TABLES, not of the kernel */
    uint16_t pointer_format;
    uint64_t segment_offset;       /* from the image base (mach header), not a vmaddr */
    uint32_t max_valid_pointer;
    uint16_t page_count;
    uint16_t page_start[1];        /* [page_count] */
};

#define DYLD_CHAINED_PTR_START_NONE   0xFFFF
#define DYLD_CHAINED_PTR_START_MULTI  0x8000

#define DYLD_CHAINED_PTR_ARM64E            1
#define DYLD_CHAINED_PTR_64                2
#define DYLD_CHAINED_PTR_32                3
#define DYLD_CHAINED_PTR_32_CACHE          4
#define DYLD_CHAINED_PTR_32_FIRMWARE       5
#define DYLD_CHAINED_PTR_64_OFFSET         6
#define DYLD_CHAINED_PTR_ARM64E_KERNEL     7
#define DYLD_CHAINED_PTR_64_KERNEL_CACHE   8
#define DYLD_CHAINED_PTR_ARM64E_USERLAND   9

#define DYLD_CHAINED_IMPORT           1
#define DYLD_CHAINED_IMPORT_ADDEND    2
#define DYLD_CHAINED_IMPORT_ADDEND64  3

/* ------------------------------------------------------- classic opcodes */
#define REBASE_TYPE_POINTER                 1
#define REBASE_OPCODE_MASK                  0xF0
#define REBASE_IMMEDIATE_MASK               0x0F
#define REBASE_OPCODE_DONE                              0x00
#define REBASE_OPCODE_SET_TYPE_IMM                      0x10
#define REBASE_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB       0x20
#define REBASE_OPCODE_ADD_ADDR_ULEB                     0x30
#define REBASE_OPCODE_ADD_ADDR_IMM_SCALED               0x40
#define REBASE_OPCODE_DO_REBASE_IMM_TIMES               0x50
#define REBASE_OPCODE_DO_REBASE_ULEB_TIMES              0x60
#define REBASE_OPCODE_DO_REBASE_ADD_ADDR_ULEB           0x70
#define REBASE_OPCODE_DO_REBASE_ULEB_TIMES_SKIPPING_ULEB 0x80

#define BIND_TYPE_POINTER                   1
#define BIND_TYPE_TEXT_ABSOLUTE32           2
#define BIND_TYPE_TEXT_PCREL32              3
#define BIND_OPCODE_MASK                    0xF0
#define BIND_IMMEDIATE_MASK                 0x0F
#define BIND_OPCODE_DONE                                0x00
#define BIND_OPCODE_SET_DYLIB_ORDINAL_IMM               0x10
#define BIND_OPCODE_SET_DYLIB_ORDINAL_ULEB              0x20
#define BIND_OPCODE_SET_DYLIB_SPECIAL_IMM               0x30
#define BIND_OPCODE_SET_SYMBOL_TRAILING_FLAGS_IMM       0x40
#define BIND_OPCODE_SET_TYPE_IMM                        0x50
#define BIND_OPCODE_SET_ADDEND_SLEB                     0x60
#define BIND_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB         0x70
#define BIND_OPCODE_ADD_ADDR_ULEB                       0x80
#define BIND_OPCODE_DO_BIND                             0x90
#define BIND_OPCODE_DO_BIND_ADD_ADDR_ULEB               0xA0
#define BIND_OPCODE_DO_BIND_ADD_ADDR_IMM_SCALED         0xB0
#define BIND_OPCODE_DO_BIND_ULEB_TIMES_SKIPPING_ULEB    0xC0
#define BIND_OPCODE_THREADED                            0xD0

#define BIND_SYMBOL_FLAGS_WEAK_IMPORT       0x1
#define BIND_SYMBOL_FLAGS_NON_WEAK_DEFINITION 0x8

#define BIND_SPECIAL_DYLIB_SELF              0
#define BIND_SPECIAL_DYLIB_MAIN_EXECUTABLE  -1
#define BIND_SPECIAL_DYLIB_FLAT_LOOKUP      -2
#define BIND_SPECIAL_DYLIB_WEAK_LOOKUP      -3

/* ----------------------------------------------------------- export trie */
#define EXPORT_SYMBOL_FLAGS_KIND_MASK          0x03
#define EXPORT_SYMBOL_FLAGS_KIND_REGULAR       0x00
#define EXPORT_SYMBOL_FLAGS_KIND_THREAD_LOCAL  0x01
#define EXPORT_SYMBOL_FLAGS_KIND_ABSOLUTE      0x02
#define EXPORT_SYMBOL_FLAGS_WEAK_DEFINITION    0x04
#define EXPORT_SYMBOL_FLAGS_REEXPORT           0x08
#define EXPORT_SYMBOL_FLAGS_STUB_AND_RESOLVER  0x10

/* ------------------------------------------------------------------ TLV */
struct tlv_descriptor {
    void         *(*thunk)(struct tlv_descriptor *);
    unsigned long key;
    unsigned long offset;
};

#endif /* MACHORUN_MACHO_H */
