/* OpenUIKitBridge.m — Swift -> Objective-C dispatch.
 *
 * THIS FILE IS THE ANSWER TO "CAN AN OBJC APP SUBCLASS UIVIEW?".
 *
 * The Swift engine holds one C function pointer per override point. Each one
 * is implemented here as a single `objc_msgSend`, so the *ObjC runtime* picks
 * the implementation: if the app subclassed UIView and overrode
 * -layoutSubviews, its override runs; if it did not, -[UIView layoutSubviews]
 * runs and forwards straight back down to the Swift superclass. The vtable
 * therefore has one entry per UIKit override point in the WHOLE framework, not
 * one per class — it does not grow as the facade grows.
 *
 * Calls are made through methodForSelector: rather than objc_msgSend directly,
 * because objc_msgSend's prototype differs between libobjc2 and Apple's
 * runtime and this file must compile on both.
 */

#import "UIKit.h"
#import <objc/runtime.h>
#import <objc/message.h>

#pragma mark - The hooks

static void ouk_layout_subviews(OUKPeer peer) {
    if (!peer) return;
    id obj = (__bridge id)peer;
    SEL sel = @selector(layoutSubviews);
    IMP imp = [obj methodForSelector:sel];
    if (imp) ((void (*)(id, SEL))imp)(obj, sel);
}

static void ouk_draw_rect(OUKPeer peer, double x, double y, double w, double h) {
    if (!peer) return;
    id obj = (__bridge id)peer;
    SEL sel = @selector(drawRect:);
    IMP imp = [obj methodForSelector:sel];
    if (imp) ((void (*)(id, SEL, CGRect))imp)(obj, sel, CGRectMake(x, y, w, h));
}

/* Target-action. The selector arrives as a NAME because the ABI is C; ObjC
 * turns it back into a real SEL, and dispatch is ordinary objc_msgSend.
 *
 * This is the one place the ObjC facade is strictly BETTER than OpenUIKit's
 * Swift API: a Swift target must hand-write an `ActionTable`
 * (docs/OBJC_RUNTIME.md), because Swift off Darwin has no by-name dispatch.
 * An ObjC target needs nothing — it has a runtime. */
static void ouk_perform_action(OUKPeer peer, const char *action,
                               OUKHandle sender, int32_t arity) {
    if (!peer || !action) return;
    id target = (__bridge id)peer;
    SEL sel = sel_registerName(action);
    if (![target respondsToSelector:sel]) return;   /* UIKit is silent here too */
    IMP imp = [target methodForSelector:sel];
    if (!imp) return;
    if (arity == 0) {
        ((void (*)(id, SEL))imp)(target, sel);
    } else {
        OUKPeer sp = sender ? openuikit_get_peer(sender) : NULL;
        id senderObj = sp ? (__bridge id)sp : nil;
        ((void (*)(id, SEL, id))imp)(target, sel, senderObj);
    }
}

static void ouk_load_view(OUKPeer peer) {
    if (!peer) return;
    id obj = (__bridge id)peer;
    SEL sel = @selector(loadView);
    IMP imp = [obj methodForSelector:sel];
    if (imp) ((void (*)(id, SEL))imp)(obj, sel);
}

static void ouk_view_did_load(OUKPeer peer) {
    if (!peer) return;
    id obj = (__bridge id)peer;
    SEL sel = @selector(viewDidLoad);
    IMP imp = [obj methodForSelector:sel];
    if (imp) ((void (*)(id, SEL))imp)(obj, sel);
}

/* A peered Swift object was deallocated. Under the domination rule this can
 * only happen while its peer is itself being torn down, so there is nothing to
 * clean up — but a bridge that never checks its invariants is a bridge that
 * breaks silently, so count them and let the proof app assert the count. */
static int32_t gOrphanedPeers = 0;
static void ouk_peer_orphaned(OUKPeer peer) { (void)peer; gOrphanedPeers++; }
int32_t OpenUIKitOrphanedPeerCount(void) { return gOrphanedPeers; }

#pragma mark - Bootstrap

void OpenUIKitObjCBootstrap(void) {
    static BOOL done = NO;
    if (done) return;
    done = YES;

    /* The struct comes from the SHARED header, so its layout is by
     * construction the same one the Swift side sees. `size` lets either half
     * be upgraded independently. */
    static openuikit_objc_hooks hooks;
    hooks.size            = (uint32_t)sizeof(openuikit_objc_hooks);
    hooks.layout_subviews = ouk_layout_subviews;
    hooks.draw_rect       = ouk_draw_rect;
    hooks.perform_action  = ouk_perform_action;
    hooks.load_view       = ouk_load_view;
    hooks.view_did_load   = ouk_view_did_load;
    hooks.peer_orphaned   = ouk_peer_orphaned;
    openuikit_set_objc_hooks(&hooks);

    /* NSAssert needs `self`/`_cmd`; this is a C function, so check by hand.
     * A mismatch here means the two halves compiled against different copies
     * of openuikit_abi_types.h, which is exactly the bug the shared header is
     * meant to make impossible — so it is worth failing loudly. */
    if (hooks.size != openuikit_abi_hooks_size()) {
        fprintf(stderr, "openuikit: hook vtable size mismatch (objc %u, swift %u)\n",
                (unsigned)hooks.size, (unsigned)openuikit_abi_hooks_size());
        abort();
    }

    if (getenv("OPENUIKIT_ABI_STRICT")) openuikit_set_strict(1);
}

void OpenUIKitSetResourceRoot(NSString *path) {
    openuikit_set_resource_root([path UTF8String]);
}

void OpenUIKitSetFontDirectory(NSString *dir) {
    /* Mirrors openrender's OPENUIKIT_FONT_DIR handling exactly, so an ObjC
     * render and a Swift render resolve the same font files. */
    NSArray *keys  = @[@"system", @"mono", @"italic"];
    NSArray *files = @[@"SFNS.ttf", @"SFNSMono.ttf", @"SFNSItalic.ttf"];
    for (NSUInteger i = 0; i < keys.count; i++) {
        NSString *p = [dir stringByAppendingPathComponent:files[i]];
        if ([[NSFileManager defaultManager] isReadableFileAtPath:p]) {
            openuikit_set_font_path([keys[i] UTF8String], [p UTF8String]);
        }
    }
}

void OpenUIKitUseQuartzBackend(BOOL quartz) { openuikit_set_backend(quartz ? 1 : 0); }
