/* tlv_asm.S -- the TLV thunk entry point.
 *
 * Contract, measured from the call site (docs/MACHO_NOTES.md §7):
 *   x0 in  = &tlv_descriptor
 *   x0 out = this thread's address for that variable
 *   every other register preserved.
 *
 * The compiler emits `ldr x8,[x0]; blr x8` around this call and does NOT treat
 * it as a normal call for register allocation, so the C slow path must not be
 * allowed to clobber anything. Save every caller-saved register, call C,
 * restore all of them except x0.
 */
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
