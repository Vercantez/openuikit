// 01_exit_raw -- rung (a): no libSystem *calls* at all.
//
// Entry is _start (LC_MAIN entryoff points here, not at a C main). The program
// writes to fd 1 and exits using Darwin's raw syscall convention:
//   syscall number in x16, `svc #0x80`, BSD numbers (write=4, exit=1).
//
// It still links libSystem so that dyld can resolve dyld_stub_binder and the
// binary is a normal dynamic Mach-O -- but no libSystem function is ever
// called. This is deliberately the one fixture that machorun's core bet does
// NOT cover: on Linux/arm64 `svc` traps to the Linux kernel, which reads the
// syscall number from x8 and uses Linux numbering. See docs/FIXTURES.md.

.text
.globl _start
.p2align 2
_start:
    // write(1, msg, 15)
    mov     x0, #1
    adrp    x1, msg@PAGE
    add     x1, x1, msg@PAGEOFF
    mov     x2, #15          // strlen("raw syscall ok\n"), NUL excluded
    mov     x16, #4
    svc     #0x80

    // exit(7)
    mov     x0, #7
    mov     x16, #1
    svc     #0x80

    // unreachable
    brk     #0

.section __TEXT,__cstring
msg:
    .asciz "raw syscall ok\n"
