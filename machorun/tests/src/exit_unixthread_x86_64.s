// exit_unixthread_x86_64 -- LC_UNIXTHREAD x86_64 twin of tests/src/exit_raw.s.
//
// Same program as exit_raw_x86_64.s (write + Darwin BSD exit via `syscall`),
// but this file is linked -static so the entry is an LC_UNIXTHREAD register
// block (flavor x86_THREAD_STATE64 = 4, RIP at uint64 index 16) rather than
// LC_MAIN. It lives beside the arm64 source, not instead of it: the thread
// state the linker emits is arch-specific and cannot share a .s with arm64.
// macOS 11+ SIGKILLs static executables; the fixture is parse-only (NO-ORACLE).
// See docs/FIXTURES.md and docs/X86_64.md.

.text
.globl _start
_start:
    movl    $1, %edi
    leaq    msg(%rip), %rsi
    movl    $15, %edx
    movl    $0x2000004, %eax
    syscall

    movl    $7, %edi
    movl    $0x2000001, %eax
    syscall

    ud2

.section __TEXT,__cstring
msg:
    .asciz "raw syscall ok\n"
