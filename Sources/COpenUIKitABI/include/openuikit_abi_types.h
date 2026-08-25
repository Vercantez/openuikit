/* openuikit_abi_types.h — the TYPES half of the OpenUIKit C ABI.
 *
 * This header is single-sourced: the Swift side imports it as the
 * `COpenUIKitABI` module, and the Objective-C facade #includes it. So the
 * callback vtable's layout can never drift between the two halves — a bridge
 * that redeclares its structs on both sides is a bridge that will one day be
 * silently off by one field.
 *
 * The FUNCTIONS live in ObjCFacade/include/OpenUIKitABI.h, which Swift
 * deliberately does NOT import: those entry points are *defined* in Swift with
 * @_cdecl, and importing their C declarations too would be a redeclaration.
 *
 * Nothing here mentions Objective-C. That is the entire point of the design —
 * see docs/OBJC_FACADE.md.
 */

#ifndef OPENUIKIT_ABI_TYPES_H
#define OPENUIKIT_ABI_TYPES_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* An opaque, reference-counted handle to a Swift object.
 *
 * OWNERSHIP: the Core Foundation Create Rule, verbatim.
 *   * A function whose name contains `_create` returns a handle you own (+1).
 *     Balance it with openuikit_release().
 *   * EVERY other handle-returning function returns a BORROWED handle (+0).
 *     It is valid only while something else keeps the object alive; call
 *     openuikit_retain() if you need to keep it.
 * There are no other rules and no exceptions. See docs/OBJC_FACADE.md.
 */
typedef void *OUKHandle;

/* An opaque pointer to the Objective-C object that peers a Swift object.
 * The Swift side stores it UNOWNED and never retains or releases it. */
typedef void *OUKPeer;

/* The Objective-C callback vtable: the *only* way Swift calls back into
 * Objective-C. One function pointer per overridable hook; the Objective-C
 * implementation of each is a one-liner that objc_msgSend's the peer, so the
 * ObjC runtime — not this table — does the polymorphism. Adding a UIKit
 * subclass therefore costs zero entries here.
 *
 * `size` is sizeof(openuikit_objc_hooks) as the CALLER saw it, so the Swift
 * side can tell which trailing members are present. Set it and never remove
 * or reorder a member. */
typedef struct openuikit_objc_hooks {
    uint32_t size;

    /* -[UIView layoutSubviews] */
    void (*layout_subviews)(OUKPeer peer);

    /* -[UIView drawRect:] — rect is the view's bounds, in points. */
    void (*draw_rect)(OUKPeer peer, double x, double y, double w, double h);

    /* Target-action: perform `action` (a selector NAME, UTF-8, e.g.
     * "buttonTapped:") on `peer` with `sender` (a BORROWED OUKHandle).
     * `arity` is the selector's trailing-colon count, 0 or 1. */
    void (*perform_action)(OUKPeer peer, const char *action,
                           OUKHandle sender, int32_t arity);

    /* -[UIViewController loadView] / viewDidLoad */
    void (*load_view)(OUKPeer peer);
    void (*view_did_load)(OUKPeer peer);

    /* Called when a Swift object with a peer is about to be deallocated,
     * so the facade can drop its side table entry. Never sent for a peer
     * that already called openuikit_clear_peer(). */
    void (*peer_orphaned)(OUKPeer peer);
} openuikit_objc_hooks;

/* UIControl.Event raw values (UIKit's own bit numbers). Mirrored here only so
 * the ObjC header can name them; the Swift side re-derives them. */
enum {
    OUKControlEventTouchDown              = 1u << 0,
    OUKControlEventTouchUpInside          = 1u << 6,
    OUKControlEventTouchUpOutside         = 1u << 7,
    OUKControlEventValueChanged           = 1u << 12,
    OUKControlEventPrimaryActionTriggered = 1u << 13,
    OUKControlEventAllEvents              = 0xFFFFFFFFu
};

/* UIControl.State raw values. */
enum {
    OUKControlStateNormal      = 0u,
    OUKControlStateHighlighted = 1u << 0,
    OUKControlStateDisabled    = 1u << 1,
    OUKControlStateSelected    = 1u << 2
};

/* UIFont.Weight, in the order OpenUIKit declares it. */
enum {
    OUKFontWeightUltraLight = 0, OUKFontWeightThin, OUKFontWeightLight,
    OUKFontWeightRegular, OUKFontWeightMedium, OUKFontWeightSemibold,
    OUKFontWeightBold, OUKFontWeightHeavy, OUKFontWeightBlack
};

/* NSTextAlignment, in the order OpenUIKit declares it. */
enum {
    OUKTextAlignmentLeft = 0, OUKTextAlignmentCenter, OUKTextAlignmentRight,
    OUKTextAlignmentJustified, OUKTextAlignmentNatural
};

/* UIButton.ButtonType. */
enum { OUKButtonTypeCustom = 0, OUKButtonTypeSystem = 1 };

/* sizeof(openuikit_objc_hooks) as the C compiler sees it. Both halves call it
 * to check they agree; declared here (not in OpenUIKitABI.h) because it is the
 * one ABI function Swift *imports* rather than defines. */
uint32_t openuikit_abi_hooks_size(void);

#ifdef __cplusplus
}
#endif
#endif /* OPENUIKIT_ABI_TYPES_H */
