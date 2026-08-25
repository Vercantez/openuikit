/* UIKitFacade.m — the Objective-C half of the bridge. Compiled by clang with
 * -fobjc-arc -fobjc-runtime=gnustep-2.2, linked against libobjc2 +
 * gnustep-base + libOpenUIKitC.so.
 *
 * Every method here is the same three lines: unwrap the arguments, call one C
 * function, wrap the result. That uniformity is the whole finding — see
 * docs/OBJC_FACADE.md on why the full facade should be GENERATED.
 */

#import "UIKit.h"
#import <objc/runtime.h>

/* Private construction seam.
 *
 * `_initWithHandle:frame:` is the real designated initializer: it takes a Swift
 * object at +1 and adopts it. `createOpenUIKitHandle` is the one method a
 * facade subclass must override — it names the C constructor that makes the
 * Swift half — and everything else is inherited unchanged. Classes whose Swift
 * constructor takes arguments (UIButton's type) bypass the hook and call
 * `_initWithHandle:` directly, because ObjC cannot pass state into a method
 * that runs before `self` exists. */
@interface UIView ()
- (OUKHandle)createOpenUIKitHandle;
- (instancetype)_initWithHandle:(OUKHandle)handle frame:(CGRect)frame
    NS_DESIGNATED_INITIALIZER;
@end

/* ------------------------------------------------------------------ */
#pragma mark - Handle <-> object identity

/* Resolving a +0 handle back to its Objective-C object needs no side table:
 * the Swift object stores its peer, so identity round-trips for anything the
 * ObjC side created. Objects the ENGINE created (UIButton's private title
 * label, say) have no peer, and this returns nil for them — a real limitation,
 * recorded in docs/OBJC_FACADE.md rather than papered over. */
static id OUKPeerObject(OUKHandle h) {
    if (!h) return nil;
    OUKPeer p = openuikit_get_peer(h);
    return p ? (__bridge id)p : nil;
}

/* ------------------------------------------------------------------ */
#pragma mark - UIColor

@implementation UIColor
+ (instancetype)colorWithRed:(CGFloat)r green:(CGFloat)g blue:(CGFloat)b alpha:(CGFloat)a {
    UIColor *c = [[UIColor alloc] init];
    if (c) { c->_red = r; c->_green = g; c->_blue = b; c->_alpha = a; }
    return c;
}
+ (instancetype)colorWithWhite:(CGFloat)w alpha:(CGFloat)a {
    return [self colorWithRed:w green:w blue:w alpha:a];
}
+ (instancetype)whiteColor { return [self colorWithWhite:1 alpha:1]; }
+ (instancetype)blackColor { return [self colorWithWhite:0 alpha:1]; }
+ (instancetype)clearColor { return [self colorWithWhite:0 alpha:0]; }
- (void)setFill { openuikit_gc_set_fill_color(_red, _green, _blue, _alpha); }
- (NSString *)description {
    return [NSString stringWithFormat:@"UIColor(%g %g %g / %g)", _red, _green, _blue, _alpha];
}
@end

void UIRectFill(CGRect r) {
    openuikit_gc_fill_rect_current(r.origin.x, r.origin.y, r.size.width, r.size.height);
}

/* ------------------------------------------------------------------ */
#pragma mark - UIResponder

@implementation UIResponder
@end

/* ------------------------------------------------------------------ */
#pragma mark - UIView

@implementation UIView

+ (void)load { OpenUIKitObjCBootstrap(); }

/* Subclass hook: each facade class says which C constructor makes its Swift
 * half, so -initWithFrame: is inherited unchanged all the way down. */
- (OUKHandle)createOpenUIKitHandle { return openuikit_view_create(); }

- (instancetype)_initWithHandle:(OUKHandle)handle frame:(CGRect)frame {
    self = [super init];
    if (!self) { openuikit_release(handle); return nil; }
    _handle = handle;                              /* +1 — the Create Rule */
    _ownsHandle = YES;
    _subviewsOwned = [NSMutableArray array];
    /* Register the peer: this is the ONLY thing that makes an ObjC override
     * reachable from the Swift engine. */
    openuikit_set_peer(_handle, (__bridge OUKPeer)self);
    self.frame = frame;
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    return [self _initWithHandle:[self createOpenUIKitHandle] frame:frame];
}

- (instancetype)init { return [self initWithFrame:CGRectZero]; }

- (void)dealloc {
    /* Detach first: openuikit_clear_peer also CHECKS the domination rule and
     * complains if this object is dying while its Swift view is still
     * parented. Then balance the +1 from -initWithFrame:. */
    if (_handle) {
        openuikit_clear_peer(_handle);
        if (_ownsHandle) openuikit_release(_handle);
        _handle = NULL;
    }
}

- (OUKHandle)openuikitHandle { return _handle; }

#pragma mark geometry

- (CGRect)frame {
    double o[4]; openuikit_view_get_frame(_handle, o);
    return CGRectMake(o[0], o[1], o[2], o[3]);
}
- (void)setFrame:(CGRect)f {
    openuikit_view_set_frame(_handle, f.origin.x, f.origin.y, f.size.width, f.size.height);
}
- (CGRect)bounds {
    double o[4]; openuikit_view_get_bounds(_handle, o);
    return CGRectMake(o[0], o[1], o[2], o[3]);
}
- (void)setBounds:(CGRect)b {
    openuikit_view_set_bounds(_handle, b.origin.x, b.origin.y, b.size.width, b.size.height);
}
- (CGPoint)center {
    CGRect f = self.frame;
    return CGPointMake(f.origin.x + f.size.width / 2, f.origin.y + f.size.height / 2);
}
- (void)setCenter:(CGPoint)c { openuikit_view_set_center(_handle, c.x, c.y); }

#pragma mark appearance

- (void)setBackgroundColor:(UIColor *)c {
    _backgroundColor = c;
    if (c) openuikit_view_set_background_color(_handle, c.red, c.green, c.blue, c.alpha);
    else   openuikit_view_clear_background_color(_handle);
}
- (void)setAlpha:(CGFloat)a { _alpha = a; openuikit_view_set_alpha(_handle, a); }
- (void)setHidden:(BOOL)h { _hidden = h; openuikit_view_set_hidden(_handle, h); }
- (void)setOpaque:(BOOL)o { _opaque = o; openuikit_view_set_opaque(_handle, o); }
- (void)setClipsToBounds:(BOOL)c { _clipsToBounds = c; openuikit_view_set_clips_to_bounds(_handle, c); }
- (void)setCornerRadius:(CGFloat)r { _cornerRadius = r; openuikit_view_set_corner_radius(_handle, r); }
- (void)setTag:(NSInteger)t { openuikit_view_set_tag(_handle, (int64_t)t); }
- (NSInteger)tag { return (NSInteger)openuikit_view_get_tag(_handle); }

#pragma mark hierarchy

/* THE DOMINATION RULE IN CODE. `_subviews` retains, mirroring Swift's own
 * `subviews` array, so no ObjC peer can die while its Swift view is still
 * parented. Drop this one line and the bridge starts crashing in layout. */
- (void)addSubview:(UIView *)view {
    if (!view) return;
    [view removeFromSuperview];
    [_subviewsOwned addObject:view];
    view->_superviewUnowned = self;
    openuikit_view_add_subview(_handle, view->_handle);
}

- (void)insertSubview:(UIView *)view atIndex:(NSInteger)index {
    if (!view) return;
    [view removeFromSuperview];
    NSUInteger i = (NSUInteger)MAX((NSInteger)0, MIN(index, (NSInteger)_subviewsOwned.count));
    [_subviewsOwned insertObject:view atIndex:i];
    view->_superviewUnowned = self;
    openuikit_view_insert_subview_at(_handle, view->_handle, (int32_t)i);
}

- (void)removeFromSuperview {
    UIView *keepAlive = self;             /* the array may hold the last ref */
    UIView *parent = keepAlive->_superviewUnowned;
    if (!parent) return;
    openuikit_view_remove_from_superview(keepAlive->_handle);
    keepAlive->_superviewUnowned = nil;
    [parent->_subviewsOwned removeObjectIdenticalTo:keepAlive];
}

- (UIView *)superview {
    /* Identity via the peer, not via _superview, so this also works for views
     * the Swift side re-parented behind our back. */
    UIView *v = OUKPeerObject(openuikit_view_superview(_handle));
    return v ?: _superviewUnowned;
}

- (NSArray<UIView *> *)subviews { return [_subviewsOwned copy]; }

#pragma mark layout & display

- (void)setNeedsLayout { openuikit_view_set_needs_layout(_handle); }
- (void)layoutIfNeeded { openuikit_view_layout_if_needed(_handle); }
- (void)setNeedsDisplay { openuikit_view_set_needs_display(_handle); }
- (void)sizeToFit { openuikit_view_size_to_fit(_handle); }
- (CGSize)sizeThatFits:(CGSize)size {
    double o[2] = {0, 0};
    openuikit_view_size_that_fits(_handle, size.width, size.height, o);
    return CGSizeMake(o[0], o[1]);
}

/* The base implementations forward to the Swift SUPERCLASS. An ObjC subclass
 * that overrides and calls [super layoutSubviews] therefore lands in
 * OpenUIKit's own implementation; one that does not override still gets
 * correct engine behaviour. Neither recurses: the Swift side reaches
 * `super.layoutSubviews()`, never the override. */
- (void)layoutSubviews { openuikit_view_super_layout_subviews(_handle); }
- (void)drawRect:(CGRect)rect {
    openuikit_view_super_draw_rect(_handle, rect.origin.x, rect.origin.y,
                                   rect.size.width, rect.size.height);
}

- (BOOL)renderToPNGAtPath:(NSString *)path scale:(CGFloat)scale {
    return openuikit_render_png(_handle, scale, [path UTF8String]) != 0;
}

- (NSString *)description {
    char buf[128];
    openuikit_class_name(_handle, buf, (int32_t)sizeof(buf));
    CGRect f = self.frame;
    return [NSString stringWithFormat:@"<%s: %p; swift=%s; frame=(%g %g; %g %g)>",
            class_getName([self class]), self, buf,
            f.origin.x, f.origin.y, f.size.width, f.size.height];
}
@end

/* ------------------------------------------------------------------ */
#pragma mark - UILabel

@implementation UILabel
- (OUKHandle)createOpenUIKitHandle { return openuikit_label_create(); }

- (void)setText:(NSString *)text {
    _text = [text copy];
    openuikit_label_set_text(_handle, text ? [text UTF8String] : NULL);
}
- (void)setTextColor:(UIColor *)c {
    _textColor = c;
    if (c) openuikit_label_set_text_color(_handle, c.red, c.green, c.blue, c.alpha);
}
- (void)setNumberOfLines:(NSInteger)n {
    _numberOfLines = n;
    openuikit_label_set_number_of_lines(_handle, (int32_t)n);
}
- (void)setFontOfSize:(CGFloat)size weight:(int32_t)weight {
    openuikit_label_set_font(_handle, size, weight);
}
- (void)setTextAlignment:(int32_t)alignment {
    openuikit_label_set_text_alignment(_handle, alignment);
}
@end

/* ------------------------------------------------------------------ */
#pragma mark - UIControl / UIButton

@implementation UIControl
- (void)addTarget:(id)target action:(SEL)action forControlEvents:(uint32_t)events {
    if (!target || !action) return;
    openuikit_control_add_target_action(_handle, (__bridge OUKPeer)target,
                                        sel_getName(action), events);
}
- (void)sendActionsForControlEvents:(uint32_t)events {
    openuikit_control_send_actions(_handle, events);
}
- (void)setEnabled:(BOOL)e { _enabled = e; openuikit_control_set_enabled(_handle, e); }
@end

@implementation UIButton
/* UIButton takes its type at CREATION time, which an ObjC initializer cannot
 * pass down to a `createOpenUIKitHandle` override (ivars are not writable
 * before [super init...] returns). Hence the private `_initWithHandle:`
 * seam: the class method makes the Swift object first and hands it over +1.
 * Any facade class whose Swift constructor takes arguments needs this shape;
 * a generator would emit it mechanically. */
- (OUKHandle)createOpenUIKitHandle { return openuikit_button_create(OUKButtonTypeSystem); }

+ (instancetype)buttonWithType:(UIButtonType)type {
    return [[self alloc] _initWithHandle:openuikit_button_create((int32_t)type)
                                   frame:CGRectZero];
}
- (void)setTitle:(NSString *)title forState:(uint32_t)state {
    openuikit_button_set_title(_handle, title ? [title UTF8String] : NULL, state);
}
- (NSString *)titleForState:(uint32_t)state {
    char buf[512];
    int32_t n = openuikit_button_get_title(_handle, state, buf, (int32_t)sizeof(buf));
    if (n < 0) return nil;
    return [NSString stringWithUTF8String:buf];
}
- (void)setTitleColor:(UIColor *)color forState:(uint32_t)state {
    if (color) openuikit_button_set_title_color(_handle, color.red, color.green,
                                                color.blue, color.alpha, state);
}
@end

/* ------------------------------------------------------------------ */
#pragma mark - UIViewController

@implementation UIViewController

- (instancetype)init {
    self = [super init];
    if (!self) return nil;
    _handle = openuikit_viewcontroller_create();      /* +1 */
    openuikit_set_peer(_handle, (__bridge OUKPeer)self);
    return self;
}

- (void)dealloc {
    if (_handle) {
        openuikit_clear_peer(_handle);
        openuikit_release(_handle);
        _handle = NULL;
    }
}

- (OUKHandle)openuikitHandle { return _handle; }

- (UIView *)view {
    [self loadViewIfNeeded];
    return _view;
}

/* Strong, and that is the domination rule again: the Swift controller retains
 * its view, so the ObjC controller must retain the view's peer. */
- (void)setView:(UIView *)view {
    _view = view;
    openuikit_viewcontroller_set_view(_handle, view ? view.openuikitHandle : NULL);
}

- (void)setTitle:(NSString *)t {
    _title = [t copy];
    openuikit_viewcontroller_set_title(_handle, t ? [t UTF8String] : NULL);
}

- (void)loadViewIfNeeded {
    if (_view) return;
    openuikit_viewcontroller_load_view_if_needed(_handle);
}

/* Base implementations: `loadView` must install a view the ObjC side owns,
 * because the default Swift loadView would create an UNPEERED UIView that the
 * facade could never wrap. This is the one place the bridge cannot simply
 * forward to super — noted in docs/OBJC_FACADE.md. */
- (void)loadView {
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 390, 844)];
    self.view = v;
}
- (void)viewDidLoad { openuikit_viewcontroller_super_view_did_load(_handle); }
@end
