// exit_raw_x86_64 -- Darwin x86_64 twin of tests/src/exit_raw.s.
//
// Entry is _start (LC_MAIN). Writes to fd 1 and exits using Darwin's raw
// x86_64 syscall convention, not libSystem:
//   class-2 number in %eax = 0x2000000 | BSD_number, then `syscall` (0f 05).
//   write=4, exit=1. Arguments are SysV: rdi, rsi, rdx.
// On Darwin this prints "raw syscall ok\n" and exits 7 -- same as the arm64
// svc #0x80 fixture. On Linux the same instruction traps to the Linux kernel
// with Linux numbering, which is the boundary of machorun's core bet (the
// loader diagnoses `syscall` in src/crash.c; it does not emulate it).
// Permanent XFAIL. See docs/FIXTURES.md.

.text
.globl _start
_start:
    movl    $1, %edi                 // fd
    leaq    msg(%rip), %rsi          // buf
    movl    $15, %edx                // strlen("raw syscall ok\n")
    movl    $0x2000004, %eax         // BSD write
    syscall

    movl    $7, %edi                 // status
    movl    $0x2000001, %eax         // BSD exit
    syscall

    ud2

.section __TEXT,__cstring
msg:
    .asciz "raw syscall ok\n"
