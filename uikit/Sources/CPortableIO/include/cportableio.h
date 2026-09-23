#ifndef CPORTABLEIO_H
#define CPORTABLEIO_H
#include <stddef.h>

/* Reads an entire file. Returns malloc'd buffer (caller frees with
   cpio_free) and sets *out_size. Returns NULL on failure. */
unsigned char *cpio_read_file(const char *path, size_t *out_size);
void cpio_free(unsigned char *buf);

/* Writes an entire file. Returns non-zero on success. */
int cpio_write_file(const char *path, const unsigned char *buf, size_t size);

/* Writes a NUL-terminated string to stderr, followed by a newline. */
void cpio_log_stderr(const char *msg);

/* Returns the value of an environment variable, or NULL. */
const char *cpio_getenv(const char *name);

/* Terminates the process. Needed by Foundation-free executables. */
void cpio_exit(int code);

/* A small opaque mutex for Swift state which is deliberately non-actor
   isolated (for example UIPasteboard, which UIKit marks Sendable). */
void *cpio_mutex_create(void);
void cpio_mutex_destroy(void *mutex);
void cpio_mutex_lock(void *mutex);
void cpio_mutex_unlock(void *mutex);

/* NSTextStorage.EditActions for the Apple-toolchain NSTextStorage, which is
   an Objective-C class (OpenUIKit/NSTextStorage.swift): its edited mask must
   be an Objective-C type, and Swift cannot declare an Objective-C option set.
   Same raw values as iOS 26.1's NSTextStorageEditActions. The C name is
   distinct so it never meets AppKit's NSTextStorageEditActions on the macOS
   host; Objective-C sources spell the SDK names through UIKitObjCSupport.h.
   Clang on Apple targets only; unused by the builds that keep the portable NSTextStorage. */
#if defined(__clang__) && defined(__APPLE__)
typedef enum __attribute__((flag_enum, enum_extensibility(open))) OUKTextStorageEditActions : unsigned long {
    OUKTextStorageEditedAttributes __attribute__((swift_name("editedAttributes"))) = (1 << 0),
    OUKTextStorageEditedCharacters __attribute__((swift_name("editedCharacters"))) = (1 << 1),
} OUKTextStorageEditActions;

/* UIControlState (UIControl.h, iOS 26.1 SDK values and Swift names:
   UIKit.apinotes gives UIControlStateNormal the Swift name `normal`). On
   Apple toolchains OpenUIKit's `UIControl.State` IS this C option set, and
   UIKitObjCSupport.h spells it `UIControlState`, so an Objective-C pod's
   `-setBorderColor:forState:animated:` (Artsy-UIButtons) takes the very type
   Swift code passes (MEASURED building Eidolon's Kiosk: "'normal' is
   unavailable" / no conversion between the two option sets). */
typedef enum __attribute__((flag_enum, enum_extensibility(open))) OUKControlState : unsigned long {
    OUKControlStateNormal __attribute__((swift_name("normal"))) = 0,
    OUKControlStateHighlighted __attribute__((swift_name("highlighted"))) = (1 << 0),
    OUKControlStateDisabled __attribute__((swift_name("disabled"))) = (1 << 1),
    OUKControlStateSelected __attribute__((swift_name("selected"))) = (1 << 2),
    OUKControlStateFocused __attribute__((swift_name("focused"))) = (1 << 3),
    OUKControlStateApplication __attribute__((swift_name("application"))) = 0x00FF0000,
    OUKControlStateReserved __attribute__((swift_name("reserved"))) = 0xFF000000,
} OUKControlState;
#endif

#endif
