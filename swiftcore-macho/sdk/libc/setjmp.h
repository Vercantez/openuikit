/* setjmp.h — clean-room. Darwin arm64 jmp_buf shape per the ARM64 ABI
 * (x19-x28, fp, lr, sp + d8-d15, saved as 64-bit words). Reached only because
 * CoreFoundation.h includes it at top level; nothing in the Swift stdlib's
 * CF surface uses setjmp, so only the type needs to be right-sized. */
#ifndef _SETJMP_H_
#define _SETJMP_H_
#include <sys/cdefs.h>
__BEGIN_DECLS
#define _JBLEN ((14 + 8 + 2) * 2)
typedef int jmp_buf[_JBLEN];
typedef int sigjmp_buf[_JBLEN + 1];
int  setjmp(jmp_buf);
void longjmp(jmp_buf, int) __dead2;
int  sigsetjmp(sigjmp_buf, int);
void siglongjmp(sigjmp_buf, int) __dead2;
int  _setjmp(jmp_buf);
void _longjmp(jmp_buf, int) __dead2;
__END_DECLS
#endif /* _SETJMP_H_ */
