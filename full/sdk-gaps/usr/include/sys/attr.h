#ifndef _SYS_ATTR_H_
#define _SYS_ATTR_H_
/* Minimal Darwin <sys/attr.h>. The SDK's OWN _FoundationCShims/io_shims.h
   includes it (line 22) and the same SDK does not ship it -- an internally
   inconsistent sysroot. Only the attrlist shape and two typedefs are needed
   to satisfy the include; the getattrlist() calls are never reached here. */
#include <sys/types.h>
typedef u_int32_t attrgroup_t;
struct attrlist {
    u_short bitmapcount; u_int16_t reserved;
    attrgroup_t commonattr, volattr, dirattr, fileattr, forkattr;
};
#define ATTR_BIT_MAP_COUNT 5
typedef struct attrreference { int32_t attr_dataoffset; u_int32_t attr_length; } attrreference_t;
enum vtype { VNON, VREG, VDIR, VBLK, VCHR, VLNK, VSOCK, VFIFO, VBAD, VSTR, VCPLX };
typedef enum vtype fsobj_type_t;
#endif
