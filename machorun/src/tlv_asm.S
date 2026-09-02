/* tlv_asm.S -- the TLV thunk entry point.
 *
 * Contract, measured from the call site (docs/MACHO_NOTES.md §7):
 *   the descriptor pointer is the first argument (x0 / rdi)
 *   the per-thread address comes back in the return register (x0 / rax)
 *   every other register is preserved.
 *
 * The compiler does NOT treat this as a normal call for register allocation
 * (arm64: `ldr x8,[x0]; blr x8`; x86_64: `movq foo@TLVP(%rip), %rdi; callq *(%rdi)`),
 * so the C slow path must not clobber caller-saved GP or SIMD. Save them, call
 * C, restore all except the return register.
 */
#if defined(__x86_64__)
    .text
    .globl  mr_tlv_get_addr
    .type   mr_tlv_get_addr, @function
    .p2align 4
mr_tlv_get_addr:
    pushq   %rbp
    movq    %rsp, %rbp
    andq    $-16, %rsp
    subq    $192, %rsp
    movq    %rcx, 0(%rsp)
    movq    %rdx, 8(%rsp)
    movq    %rsi, 16(%rsp)
    movq    %rdi, 24(%rsp)
    movq    %r8,  32(%rsp)
    movq    %r9,  40(%rsp)
    movq    %r10, 48(%rsp)
    movq    %r11, 56(%rsp)
    movdqu  %xmm0, 64(%rsp)
    movdqu  %xmm1, 80(%rsp)
    movdqu  %xmm2, 96(%rsp)
    movdqu  %xmm3, 112(%rsp)
    movdqu  %xmm4, 128(%rsp)
    movdqu  %xmm5, 144(%rsp)
    movdqu  %xmm6, 160(%rsp)
    movdqu  %xmm7, 176(%rsp)
    call    mr_tlv_get_addr_c
    movdqu  64(%rsp), %xmm0
    movdqu  80(%rsp), %xmm1
    movdqu  96(%rsp), %xmm2
    movdqu  112(%rsp), %xmm3
    movdqu  128(%rsp), %xmm4
    movdqu  144(%rsp), %xmm5
    movdqu  160(%rsp), %xmm6
    movdqu  176(%rsp), %xmm7
    movq    0(%rsp), %rcx
    movq    8(%rsp), %rdx
    movq    16(%rsp), %rsi
    movq    24(%rsp), %rdi
    movq    32(%rsp), %r8
    movq    40(%rsp), %r9
    movq    48(%rsp), %r10
    movq    56(%rsp), %r11
    movq    %rbp, %rsp
    popq    %rbp
    ret
    .size   mr_tlv_get_addr, . - mr_tlv_get_addr
    .section .note.GNU-stack,"",@progbits

#elif defined(__aarch64__)
    .text
    .globl  mr_tlv_get_addr
    .type   mr_tlv_get_addr, %function
    .p2align 2
mr_tlv_get_addr:
    stp     x29, x30, [sp, #-304]!
    mov     x29, sp
    stp     x1,  x2,  [sp, #16]
    stp     x3,  x4,  [sp, #32]
    stp     x5,  x6,  [sp, #48]
    stp     x7,  x8,  [sp, #64]
    stp     x9,  x10, [sp, #80]
    stp     x11, x12, [sp, #96]
    stp     x13, x14, [sp, #112]
    stp     x15, x16, [sp, #128]
    stp     x17, x18, [sp, #144]
    stp     q0,  q1,  [sp, #160]
    stp     q2,  q3,  [sp, #192]
    stp     q4,  q5,  [sp, #224]
    stp     q6,  q7,  [sp, #256]

    bl      mr_tlv_get_addr_c

    ldp     q6,  q7,  [sp, #256]
    ldp     q4,  q5,  [sp, #224]
    ldp     q2,  q3,  [sp, #192]
    ldp     q0,  q1,  [sp, #160]
    ldp     x17, x18, [sp, #144]
    ldp     x15, x16, [sp, #128]
    ldp     x13, x14, [sp, #112]
    ldp     x11, x12, [sp, #96]
    ldp     x9,  x10, [sp, #80]
    ldp     x7,  x8,  [sp, #64]
    ldp     x5,  x6,  [sp, #48]
    ldp     x3,  x4,  [sp, #32]
    ldp     x1,  x2,  [sp, #16]
    ldp     x29, x30, [sp], #304
    ret
    .size   mr_tlv_get_addr, . - mr_tlv_get_addr

    .section .note.GNU-stack,"",%progbits
#else
#error tlv_asm.S: host is neither x86_64 nor aarch64
#endif
