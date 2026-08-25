/* compat/mach/message.h -- objc4-linux. See mach/mach.h. */
#ifndef _OBJC4LINUX_MACH_MESSAGE_H
#define _OBJC4LINUX_MACH_MESSAGE_H
#include <mach/mach.h>
typedef int mach_msg_return_t;
typedef int mach_msg_option_t;
typedef unsigned int mach_msg_bits_t;
typedef unsigned int mach_msg_id_t;
typedef struct { mach_msg_bits_t msgh_bits; mach_msg_size_t msgh_size;
                 mach_port_t msgh_remote_port, msgh_local_port, msgh_voucher_port;
                 mach_msg_id_t msgh_id; } mach_msg_header_t;
#define MACH_MSG_SUCCESS 0
#endif
