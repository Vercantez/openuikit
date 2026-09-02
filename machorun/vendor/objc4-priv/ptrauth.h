/*
 * compat/ptrauth.h  --  objc4-linux
 *
 * Apple's <ptrauth.h> is not shipped by Ubuntu's clang (verified: clang 18
 * on aarch64-unknown-linux-gnu has no such header). objc4 includes it
 * unconditionally from objc-ptrauth.h.
 *
 * MEASURED: __has_feature(ptrauth_calls) is 0 on aarch64 Linux, so all 91
 * ptrauth_* uses in the tree sit in dead branches. This header supplies
 * exactly Apple's !ptrauth_calls fallback semantics: everything is identity.
 *
 * PAC on Linux (-mbranch-protection=pac-ret) is a different, uninstrumented
 * mechanism; nothing here enables it.
 */
#ifndef _OBJC4LINUX_PTRAUTH_H
#define _OBJC4LINUX_PTRAUTH_H

#include <stdint.h>

#if __has_feature(ptrauth_calls)
#   error "objc4-linux: compiler claims ptrauth_calls; use the real <ptrauth.h>"
#endif

typedef uintptr_t ptrauth_extra_data_t;
typedef uintptr_t ptrauth_generic_signature_t;

/* Apple declares this as an enum type usable as a template parameter;
 * objc-ptrauth.h has `template <unsigned d, ptrauth_key key = ...>`. */
typedef unsigned ptrauth_key;

#define ptrauth_key_asia                    0
#define ptrauth_key_asib                    1
#define ptrauth_key_asda                    2
#define ptrauth_key_asdb                    3
#define ptrauth_key_function_pointer        ptrauth_key_asia
#define ptrauth_key_return_address          ptrauth_key_asib
#define ptrauth_key_frame_pointer           ptrauth_key_asdb
#define ptrauth_key_block_function          ptrauth_key_asia
#define ptrauth_key_cxx_vtable_pointer      ptrauth_key_asda
#define ptrauth_key_method_list_pointer     ptrauth_key_asda
#define ptrauth_key_objc_isa_pointer        ptrauth_key_asda
#define ptrauth_key_objc_super_pointer      ptrauth_key_asda
#define ptrauth_key_process_dependent_code  ptrauth_key_asia
#define ptrauth_key_process_dependent_data  ptrauth_key_asda
#define ptrauth_key_process_independent_code ptrauth_key_asia
#define ptrauth_key_process_independent_data ptrauth_key_asda

#define ptrauth_strip(__value, __key)                       __value
#define ptrauth_blend_discriminator(__pointer, __integer)    ((uintptr_t)0)
#define ptrauth_sign_constant(__value, __key, __data)       __value
#define ptrauth_sign_unauthenticated(__value, __key, __data) __value
#define ptrauth_auth_and_resign(__value, __old_key, __old_data, __new_key, __new_data) __value
#define ptrauth_auth_function(__value, __old_key, __old_data) __value
#define ptrauth_auth_data(__value, __old_key, __old_data)   __value
#define ptrauth_string_discriminator(__string)              ((int)0)
#define ptrauth_type_discriminator(__type)                  ((int)0)
#define ptrauth_sign_generic_data(__value, __data)          ((ptrauth_generic_signature_t)0)
#define ptrauth_function_pointer_type_discriminator(__type) ((uintptr_t)0)

#define __ptrauth_function_pointer
#define __ptrauth_return_address
#define __ptrauth_block_invocation_pointer
#define __ptrauth_block_copy_helper
#define __ptrauth_block_destroy_helper
#define __ptrauth_block_byref_copy_helper
#define __ptrauth_block_byref_destroy_helper
#define __ptrauth_objc_method_list_imp
#define __ptrauth_cxx_vtable_pointer
#define __ptrauth_objc_isa_pointer
#define __ptrauth_objc_super_pointer
#define __ptrauth_objc_class_ro
#define __ptrauth_objc_method_list_pointer
#define __ptrauth_objc_sel
#define __ptrauth_objc_class_method_list_imp
#define __ptrauth_objc_class_method_list_pointer
#define __ptrauth_objc_method_list_types
#define __ptrauth_restricted_intptr(key, address, discriminator)
#define __ptrauth(key, address, discriminator)

#define ptrauth_nop_cast(__type, __expr)                    ((__type)(__expr))

#endif
