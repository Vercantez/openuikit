/* Minimal ObjC-runtime stand-in: enough for Swift's ObjC interop codegen to
   LINK on Linux. SEL is just the uniqued selector-name pointer, which is all
   a source-level (non-msgSend) dispatch scheme needs.

   READ THIS FIRST: linking is not enough. `-enable-objc-interop` also changes
   the *class metadata layout* Swift emits, and the Linux libswiftCore.so is
   built without interop and cannot read it -- so the resulting program
   segfaults on any dynamic cast to a protocol, `type(of:)`, reflection, or
   generic instantiation. `interop_limits.sh` measures both facts. Nothing in
   this file (or in GNUstep libobjc2) can fix that; see docs/OBJC_RUNTIME.md.
   This shim is kept because it is the reproduction of the measurement, not
   because it is a supported build mode. */
#include <stddef.h>
struct objc_cache_t { unsigned long long a, b; };
struct objc_cache_t _objc_empty_cache = {0, 0};

/* Swift's root class for ObjC interop; opaque here. */
struct fake_class { void *isa, *super, *cache, *vtable, *data; };
struct fake_class OBJC_METACLASS_$__TtCs12_SwiftObject = {0,0,&_objc_empty_cache,0,0};
struct fake_class OBJC_CLASS_$__TtCs12_SwiftObject =
    {&OBJC_METACLASS_$__TtCs12_SwiftObject, 0, &_objc_empty_cache, 0, 0};

void *objc_opt_self(void *obj) { return obj; }
const char *sel_getName(const char *sel) { return sel; }
const char *sel_registerName(const char *name) { return name; }

/* swiftCore on Linux is built without ObjC interop, so the whole
   "unknown object" family (the one that would branch between the Swift and
   ObjC runtimes on Darwin) is absent. For a pure-Swift object graph every
   one of them is exactly its native counterpart. */
void *swift_retain(void *);
void swift_release(void *);
void *swift_retain_n(void *, unsigned);
void swift_release_n(void *, unsigned);
void *swift_weakInit(void *, void *);
void *swift_weakAssign(void *, void *);
void *swift_weakLoadStrong(void *);
void *swift_weakTakeStrong(void *);
void swift_weakDestroy(void *);
void *swift_weakCopyInit(void *, void *);
void *swift_weakTakeInit(void *, void *);
void *swift_weakCopyAssign(void *, void *);
void *swift_weakTakeAssign(void *, void *);
void *swift_unownedRetain(void *);
void swift_unownedRelease(void *);
void *swift_unownedRetainStrong(void *);
void swift_unownedRetainStrongAndRelease(void *);
void swift_unownedCheck(void *);

void *swift_unknownObjectRetain(void *o) { return swift_retain(o); }
void swift_unknownObjectRelease(void *o) { swift_release(o); }
void *swift_unknownObjectRetain_n(void *o, unsigned n) { return swift_retain_n(o, n); }
void swift_unknownObjectRelease_n(void *o, unsigned n) { swift_release_n(o, n); }

void *swift_unknownObjectWeakInit(void *r, void *v) { return swift_weakInit(r, v); }
void *swift_unknownObjectWeakAssign(void *r, void *v) { return swift_weakAssign(r, v); }
void *swift_unknownObjectWeakLoadStrong(void *r) { return swift_weakLoadStrong(r); }
void *swift_unknownObjectWeakTakeStrong(void *r) { return swift_weakTakeStrong(r); }
void swift_unknownObjectWeakDestroy(void *r) { swift_weakDestroy(r); }
void *swift_unknownObjectWeakCopyInit(void *d, void *s) { return swift_weakCopyInit(d, s); }
void *swift_unknownObjectWeakTakeInit(void *d, void *s) { return swift_weakTakeInit(d, s); }
void *swift_unknownObjectWeakCopyAssign(void *d, void *s) { return swift_weakCopyAssign(d, s); }
void *swift_unknownObjectWeakTakeAssign(void *d, void *s) { return swift_weakTakeAssign(d, s); }

/* The unowned *slot* family (Init/Assign/LoadStrong/...) has no native
   counterpart on Linux — swiftCore only exports the retain/release
   primitives and manipulates UnownedReference slots inline. Reimplemented
   here over those primitives; an UnownedReference is one pointer. */
typedef struct { void *value; } UnownedRef;

void *swift_unknownObjectUnownedInit(void *rp, void *v) {
    UnownedRef *r = (UnownedRef *)rp;
    r->value = v;
    if (v) swift_unownedRetain(v);
    return rp;
}
void *swift_unknownObjectUnownedAssign(void *rp, void *v) {
    UnownedRef *r = (UnownedRef *)rp;
    void *old = r->value;
    if (v) swift_unownedRetain(v);
    r->value = v;
    if (old) swift_unownedRelease(old);
    return rp;
}
void *swift_unknownObjectUnownedLoadStrong(void *rp) {
    void *v = ((UnownedRef *)rp)->value;
    if (v) swift_unownedRetainStrong(v);
    return v;
}
void *swift_unknownObjectUnownedTakeStrong(void *rp) {
    void *v = ((UnownedRef *)rp)->value;
    if (v) swift_unownedRetainStrongAndRelease(v);
    return v;
}
void swift_unknownObjectUnownedDestroy(void *rp) {
    void *v = ((UnownedRef *)rp)->value;
    if (v) swift_unownedRelease(v);
}
void *swift_unknownObjectUnownedCopyInit(void *dp, void *sp) {
    void *v = ((UnownedRef *)sp)->value;
    ((UnownedRef *)dp)->value = v;
    if (v) swift_unownedRetain(v);
    return dp;
}
void *swift_unknownObjectUnownedTakeInit(void *dp, void *sp) {
    ((UnownedRef *)dp)->value = ((UnownedRef *)sp)->value;
    return dp;
}
void *swift_unknownObjectUnownedCopyAssign(void *dp, void *sp) {
    return swift_unknownObjectUnownedAssign(dp, ((UnownedRef *)sp)->value);
}
void *swift_unknownObjectUnownedTakeAssign(void *dp, void *sp) {
    UnownedRef *d = (UnownedRef *)dp;
    void *old = d->value;
    d->value = ((UnownedRef *)sp)->value;
    if (old) swift_unownedRelease(old);
    return dp;
}
void *swift_unknownObjectUnownedRetain(void *o) { return swift_unownedRetain(o); }
void swift_unknownObjectUnownedRelease(void *o) { swift_unownedRelease(o); }
void *swift_unknownObjectUnownedRetainStrong(void *o) { return swift_unownedRetainStrong(o); }
void swift_unknownObjectUnownedRetainStrongAndRelease(void *o) { swift_unownedRetainStrongAndRelease(o); }
void swift_unknownObjectUnownedCheck(void *o) { swift_unownedCheck(o); }
