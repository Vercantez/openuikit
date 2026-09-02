/*
 * compat/System/pthread_machdep.h -- objc4-linux.
 * Darwin's direct thread-specific-data slots (_pthread_getspecific_direct).
 * Linux has no reserved TSD slots; the pthreads threading back-end uses
 * pthread_getspecific() instead, which is what Apple's own
 * runtime/Threading/pthreads.h already does.
 */
#ifndef _OBJC4LINUX_PTHREAD_MACHDEP_H
#define _OBJC4LINUX_PTHREAD_MACHDEP_H
#endif
