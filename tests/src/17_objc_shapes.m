/* 17_objc_shapes -- rung (p): Objective-C draws, in anger.
 *
 * 15_quartz proved the rasteriser under machorun with no Objective-C in it.
 * 09_objc proved Objective-C under machorun with no drawing in it. 16_objc_quartz
 * proved the two libraries can be in one process. THIS fixture is the one that
 * is actually the milestone: a precompiled Apple-toolchain Mach-O whose PICTURE
 * is produced by polymorphic message dispatch, and which is compared to the same
 * bytes running natively on macOS pixel for pixel.
 *
 * It is deliberately not "C with brackets". Every Objective-C mechanism below
 * is on the critical path to a pixel -- take any one of them away and the image
 * changes:
 *
 *   protocol            <Drawable>, with a required method, an @optional one
 *                       and a readonly property. Held as id<Drawable> in the
 *                       collection, so the scene loop is typed by the protocol
 *                       and not by any class.
 *   root class          Shape owns its own `Class isa`; no NSObject, no
 *                       Foundation, no CoreFoundation anywhere. Instances come
 *                       from class_createInstance(), exactly as in 09_objc.
 *   ivars               declared in the @interface braces AND, for `inset`,
 *                       auto-synthesised by @property. Both reach the pixel
 *                       through libobjc's image-load ivar-offset fixups.
 *   properties          `tag` (backed by an explicitly declared _tag) and
 *                       `inset` (compiler-created _inset). The category uses
 *                       dot syntax, i.e. a real accessor message send.
 *   inheritance         Shape -> Circle -> Ring, three levels, with Ring's
 *                       -drawInContext: calling [super drawInContext:] --
 *                       objc_msgSendSuper2, a different dispatch path from
 *                       objc_msgSend and one no earlier fixture exercises.
 *   subclass ivars      Vane adds _angle on top of Shape's layout, so the
 *                       non-fragile-ivar instanceStart arithmetic is load
 *                       bearing rather than decorative.
 *   overriding          four -drawInContext: implementations, chosen at run
 *                       time by the isa pointer and nothing else.
 *   category            Shape (Badge) adds -badgeInContext: to a class that is
 *                       already compiled, and every shape in the scene gets a
 *                       badge from it. Separate __objc_catlist entry.
 *   +load               six of them (five classes and the category), printed
 *                       in the order libobjc calls them, before main runs.
 *   +initialize         inherited from Shape and fired lazily on first message
 *                       to each class, so the print order is a statement about
 *                       WHEN each class was first touched.
 *   objc_msgSend        called through an explicit cast as well as through
 *                       bracket syntax, including a QZRect return -- four
 *                       doubles, i.e. a homogeneous float aggregate returned
 *                       in d0-d3, through the trampoline.
 *
 * DETERMINISM, which is not negotiable in a differential fixture. No time, no
 * random, no locale-dependent formatting, no environment, no address is ever
 * printed, and nothing iterates a hash table: the collection is a fixed-size C
 * array walked in insertion order. Every coordinate and colour below is a
 * literal. The output is a function of the bytes of this binary and of the
 * three dylibs it loads (libquartz, libobjc, libSystem) and of nothing else.
 *
 * WHERE A DIVERGENCE WOULD SHOW FIRST. Stage 5 is the only stage that reaches
 * a transcendental: -[Vane drawInContext:] calls QZContextRotateCTM, which is
 * cos/sin, which is Apple's Libm on the oracle and glibc's under machorun (via
 * darwin/src/math.c, and on an Apple target very likely via the __sincos_stret
 * aggregate ABI). IEEE 754 pins nothing about sin or cos. Keeping it in its own
 * stage, last, with its own checksum, is what turns "the PNG differs" into a
 * bug report -- see docs/QUARTZ_MACHO.md §3.
 *
 * Output path is argv[1], defaulting to objc_shapes.png in the cwd.
 */
#include <objc/runtime.h>
#include <objc/message.h>
#include <quartz/quartz.h>
#include <stdio.h>

#define W 256
#define H 256

/* ------------------------------------------------------------- checksums */

static unsigned long long fnv1a(const unsigned char *p, size_t n)
{
    unsigned long long h = 1469598103934665603ULL;
    for (size_t i = 0; i < n; i++) { h ^= p[i]; h *= 1099511628211ULL; }
    return h;
}

static int stage_no = 0;

/* Checksum of the whole backing store plus six fixed probe pixels, so two logs
 * read side by side show colour values and not only "different".
 *
 * The probes are not arbitrary. They are in BITMAP coordinates (row 0 is the
 * top; quartz's user space is y-up), and each one is aimed at the output of a
 * different object so that a single wrong dispatch is visible as a colour and
 * not only as a moved hash:
 *
 *   40,60    inside the plain Shape's rect        -> Shape's own -drawInContext:
 *   94,51    the centre of the plain Shape's badge -> the CATEGORY's method
 *   140,80   inside the Circle                    -> the first override
 *   210,74   inside the RoundedBox                -> the second override
 *   30,150   the purple annulus of the Ring, not its hole -> the [super] path
 *   146,160  the centre of the first Vane          -> the rotated (cos/sin) stage
 */
static void stage(QZContextRef ctx, const char *what)
{
    const unsigned char *px = (const unsigned char *)QZBitmapContextGetData(ctx);
    size_t bpr = QZBitmapContextGetBytesPerRow(ctx);
    static const int probe[][2] = { {40,60}, {94,51}, {140,80},
                                    {210,74}, {30,150}, {146,160} };
    printf("stage %d %-16s fnv1a=%016llx", ++stage_no, what, fnv1a(px, bpr * H));
    for (unsigned i = 0; i < sizeof(probe)/sizeof(probe[0]); i++) {
        const unsigned char *q = px + (size_t)probe[i][1] * bpr + (size_t)probe[i][0] * 4;
        printf("  %02x%02x%02x%02x", q[0], q[1], q[2], q[3]);
    }
    printf("\n");
}

/* -------------------------------------------------------------- protocol */

@protocol Drawable
@required
- (void)drawInContext:(QZContextRef)ctx;
- (const char *)shapeName;
@property (readonly) int tag;
@optional
- (void)badgeInContext:(QZContextRef)ctx;   /* supplied by a CATEGORY, not by
                                             * any @interface -- so the scene's
                                             * badges exist only if categories
                                             * were attached at image load. */
@end

/* ------------------------------------------------------------ root class */

@interface Shape <Drawable> {
    Class   isa;            /* root class: we own the isa slot */
    QZRect  _frame;
    QZFloat _r, _g, _b, _a;
    int     _tag;
}
@property int tag;          /* uses the _tag declared above */
@property QZFloat inset;    /* no ivar declared: the compiler makes _inset */

+ (id)shapeWithFrame:(QZRect)f tag:(int)t;
- (void)setFillRed:(QZFloat)r green:(QZFloat)g blue:(QZFloat)b alpha:(QZFloat)a;
- (QZRect)frame;
- (QZRect)insetFrame;
- (void)applyFill:(QZContextRef)ctx;
- (void)drawInContext:(QZContextRef)ctx;
- (const char *)shapeName;
@end

@implementation Shape

/* +load runs at image-load time, before any initialiser and before main. The
 * order of these six lines across the classes and the category is libobjc's
 * traversal order and is exactly the thing tests/objc44/006-load-order pins. */
+ (void)load       { printf("+load %s\n", class_getName((Class)self)); }

/* +initialize is lazy: libobjc sends it to a class immediately before that
 * class's first message. Only Shape implements it, so every subclass inherits
 * this body and prints its OWN name -- which makes the print order a record of
 * when each class was first touched, not of link order. */
+ (void)initialize { printf("+initialize %s\n", class_getName((Class)self)); }

/* Takes a QZRect BY VALUE through objc_msgSend: four doubles, a homogeneous
 * float aggregate, passed in d0-d3 under AAPCS64. */
+ (id)shapeWithFrame:(QZRect)f tag:(int)t
{
    Shape *s = (Shape *)class_createInstance(self, 0);
    s->_frame = f;
    s->_tag   = t;
    s->_inset = 0.0;
    s->_r = 0.80; s->_g = 0.80; s->_b = 0.80; s->_a = 1.0;
    return s;
}

- (void)setFillRed:(QZFloat)r green:(QZFloat)g blue:(QZFloat)b alpha:(QZFloat)a
{
    _r = r; _g = g; _b = b; _a = a;
}

- (QZRect)frame { return _frame; }

- (QZRect)insetFrame
{
    return QZRectMake(_frame.origin.x + _inset,
                      _frame.origin.y + _inset,
                      _frame.size.width  - 2.0 * _inset,
                      _frame.size.height - 2.0 * _inset);
}

- (void)applyFill:(QZContextRef)ctx
{
    QZContextSetRGBFillColor(ctx, _r, _g, _b, _a);
}

/* The base implementation. Not dead code: one plain Shape is in the scene, so
 * a subclass that failed to override would be visible as a rectangle. */
- (void)drawInContext:(QZContextRef)ctx
{
    [self applyFill:ctx];
    QZContextFillRect(ctx, [self insetFrame]);
}

- (const char *)shapeName { return "shape"; }

@end

/* ------------------------------------------------- category on that class */

@interface Shape (Badge)
- (void)badgeInContext:(QZContextRef)ctx;
@end

@implementation Shape (Badge)

+ (void)load { printf("+load Shape(Badge)\n"); }

/* Uses dot syntax on purpose: `self.tag` is a message send to the synthesised
 * -tag accessor, so this method depends on the property metadata as well as on
 * the category having been attached. */
- (void)badgeInContext:(QZContextRef)ctx
{
    QZRect  f = [self frame];
    QZFloat s = 5.0 + 2.0 * (QZFloat)(self.tag % 3);
    QZContextSetRGBFillColor(ctx, 0.97, 0.97, 0.90, 0.92);
    QZContextFillRect(ctx, QZRectMake(f.origin.x + f.size.width - s - 2.0,
                                      f.origin.y + f.size.height - s - 2.0, s, s));
}

@end

/* ---------------------------------------------------------- the subclasses */

@interface Circle : Shape @end
@implementation Circle
+ (void)load { printf("+load %s\n", class_getName((Class)self)); }
- (void)drawInContext:(QZContextRef)ctx
{
    [self applyFill:ctx];
    QZContextFillEllipseInRect(ctx, [self insetFrame]);
}
- (const char *)shapeName { return "circle"; }
@end

@interface RoundedBox : Shape @end
@implementation RoundedBox
+ (void)load { printf("+load %s\n", class_getName((Class)self)); }
- (void)drawInContext:(QZContextRef)ctx
{
    [self applyFill:ctx];
    QZContextBeginPath(ctx);
    QZContextAddRoundedRect(ctx, [self insetFrame], 9.0);
    QZContextFillPath(ctx);
}
- (const char *)shapeName { return "rounded-box"; }
@end

/* Three levels deep, and the only place [super ...] appears -- which the
 * compiler lowers to objc_msgSendSuper2 against __objc_superrefs, a dispatch
 * path objc_msgSend alone does not cover. Ring's disc is Circle's disc; only
 * the hole is Ring's own. */
@interface Ring : Circle @end
@implementation Ring
+ (void)load { printf("+load %s\n", class_getName((Class)self)); }
- (void)drawInContext:(QZContextRef)ctx
{
    [super drawInContext:ctx];
    QZRect  f  = [self insetFrame];
    QZFloat dx = f.size.width  * 0.30;
    QZFloat dy = f.size.height * 0.30;
    QZContextSetRGBFillColor(ctx, 0.08, 0.09, 0.13, 1.0);
    QZContextFillEllipseInRect(ctx, QZRectMake(f.origin.x + dx, f.origin.y + dy,
                                               f.size.width - 2.0 * dx,
                                               f.size.height - 2.0 * dy));
}
- (const char *)shapeName { return "ring"; }
@end

/* Adds an ivar of its own on top of Shape's, so the non-fragile-ivar
 * instanceStart offset has to be right for _angle to be readable at all.
 * Its -drawInContext: is the transcendental stage: see the header. */
@interface Vane : Shape { QZFloat _angle; }
- (void)setAngle:(QZFloat)a;
@end
@implementation Vane
+ (void)load { printf("+load %s\n", class_getName((Class)self)); }
- (void)setAngle:(QZFloat)a { _angle = a; }
- (void)drawInContext:(QZContextRef)ctx
{
    QZRect f = [self frame];
    QZContextSaveGState(ctx);
    QZContextTranslateCTM(ctx, f.origin.x + f.size.width / 2.0,
                               f.origin.y + f.size.height / 2.0);
    QZContextRotateCTM(ctx, _angle);            /* <-- cos/sin live here */
    [self applyFill:ctx];
    QZContextFillRect(ctx, QZRectMake(-f.size.width / 2.0, -f.size.height / 6.0,
                                      f.size.width, f.size.height / 3.0));
    QZContextSetRGBStrokeColor(ctx, 0.10, 0.10, 0.14, 1.0);
    QZContextSetLineWidth(ctx, 2.0);
    QZContextStrokeRect(ctx, QZRectMake(-f.size.width / 2.0, -f.size.height / 6.0,
                                        f.size.width, f.size.height / 3.0));
    QZContextRestoreGState(ctx);
}
- (const char *)shapeName { return "vane"; }
@end

/* ------------------------------------------------------------ the holder */

/* A fixed-size C array behind an Objective-C interface. Deliberately NOT a
 * dictionary or a set: the drawing order has to be insertion order on both
 * hosts, and anything hash-ordered would make the picture a function of the
 * allocator. */
@interface ShapeList {
    Class    isa;
    id       _items[8];
    unsigned _count;
}
+ (id)list;
- (void)add:(id)obj;
- (unsigned)count;
- (id)at:(unsigned)i;
- (void)drawAllInContext:(QZContextRef)ctx;
@end

@implementation ShapeList
+ (void)load { printf("+load %s\n", class_getName((Class)self)); }
+ (id)list
{
    ShapeList *l = (ShapeList *)class_createInstance(self, 0);
    l->_count = 0;
    return l;
}
- (void)add:(id)obj { if (_count < 8) _items[_count++] = obj; }
- (unsigned)count   { return _count; }
- (id)at:(unsigned)i { return i < _count ? _items[i] : nil; }

/* THE POLYMORPHIC LOOP. Typed by the protocol, not by any class; which
 * -drawInContext: runs is decided by each object's isa and by nothing the
 * compiler could have known. */
- (void)drawAllInContext:(QZContextRef)ctx
{
    for (unsigned i = 0; i < _count; i++)
        [(id<Drawable>)_items[i] drawInContext:ctx];
}
@end

/* ------------------------------------------------------------------ scene */

static Shape *mk(Class cls, QZRect f, int tag, QZFloat inset,
                 QZFloat r, QZFloat g, QZFloat b, QZFloat a)
{
    /* +shapeWithFrame:tag: reached on a Class held in a variable: the receiver
     * is not a compile-time constant, so this really is a dispatch. */
    Shape *s = ((id (*)(id, SEL, QZRect, int))objc_msgSend)(
        (id)cls, @selector(shapeWithFrame:tag:), f, tag);
    s.inset = inset;
    [s setFillRed:r green:g blue:b alpha:a];
    return s;
}

int main(int argc, char **argv)
{
    const char *out = argc > 1 ? argv[1] : "objc_shapes.png";

    QZContextRef ctx = QZBitmapContextCreate(NULL, W, H, 8, W * 4,
                                             kQZImageAlphaPremultipliedLast);
    if (!ctx) { fprintf(stderr, "QZBitmapContextCreate failed\n"); return 2; }

    printf("objc shapes %dx%d bpr=%zu\n", W, H, QZBitmapContextGetBytesPerRow(ctx));

    /* ---- runtime facts. Deliberately before any message send, so nothing
     * here perturbs the +initialize order printed below. objc_getClass does
     * not initialise. ---- */
    Class cShape = objc_getClass("Shape");
    Class cCircle = objc_getClass("Circle");
    Class cRing = objc_getClass("Ring");
    Class cVane = objc_getClass("Vane");
    Class cBox  = objc_getClass("RoundedBox");
    Class cList = objc_getClass("ShapeList");
    printf("registered=%d\n", cShape && cCircle && cRing && cVane && cBox && cList ? 1 : 0);
    printf("chain=%s<-%s<-%s\n", class_getName(cShape),
           class_getName(class_getSuperclass(cRing)), class_getName(cRing));
    /* A root class has no superclass. Printed as a flag rather than as %p: the
     * value is nil on both hosts, but a pointer format is a printf test and
     * this fixture is not one. */
    printf("root-has-superclass=%d\n", class_getSuperclass(cShape) != NULL);
    printf("conforms Shape=%d Circle=%d\n",
           class_conformsToProtocol(cShape, @protocol(Drawable)),
           class_conformsToProtocol(cCircle, @protocol(Drawable)));
    printf("responds Circle.drawInContext:=%d Circle.badgeInContext:=%d Circle.nope=%d\n",
           class_respondsToSelector(cCircle, @selector(drawInContext:)),
           class_respondsToSelector(cCircle, @selector(badgeInContext:)),
           class_respondsToSelector(cCircle, sel_registerName("nope")));
    printf("sel-uniqued=%d name=%s\n",
           @selector(drawInContext:) == sel_registerName("drawInContext:"),
           sel_getName(@selector(drawInContext:)));

    /* ---- stage 1: the background, in plain C. Nothing dispatched yet. ---- */
    QZContextSetRGBFillColor(ctx, 0.08, 0.09, 0.13, 1.0);
    QZContextFillRect(ctx, QZRectMake(0, 0, W, H));
    stage(ctx, "background");

    /* ---- build the scene. Fixed order, fixed literals. The +initialize
     * lines appear interleaved here, in first-touch order. ---- */
    ShapeList *list = [ShapeList list];
    [list add:mk(cShape,  QZRectMake( 16, 152,  84,  58), 1, 6.0, 0.86, 0.26, 0.22, 1.00)];
    [list add:mk(cCircle, QZRectMake(112, 148,  64,  64), 2, 4.0, 0.22, 0.72, 0.38, 1.00)];
    [list add:mk(cBox,    QZRectMake(184, 146,  60,  68), 3, 3.0, 0.24, 0.44, 0.92, 1.00)];
    [list add:mk(cRing,   QZRectMake( 20,  74,  76,  66), 4, 5.0, 0.62, 0.38, 0.88, 1.00)];
    [list add:mk(cCircle, QZRectMake(196,  68,  52,  52), 5, 8.0, 0.96, 0.78, 0.18, 0.85)];
    printf("count=%u\n", [list count]);

    /* ---- stage 2: draw them all through the protocol. ---- */
    [list drawAllInContext:ctx];
    stage(ctx, "polymorphic");

    /* Names, resolved by the same dispatch that chose the drawing code. This
     * is the assertion that stage 2's picture came from four different
     * implementations and not from one. */
    for (unsigned i = 0; i < [list count]; i++) {
        id<Drawable> s = (id<Drawable>)[list at:i];
        printf("item %u %-12s tag=%d\n", i, [s shapeName], [s tag]);
    }

    /* ---- stage 3: the category's method, on every shape. -badgeInContext:
     * is declared @optional in the protocol and defined only in a category, so
     * these squares exist if and only if __objc_catlist was processed. ---- */
    for (unsigned i = 0; i < [list count]; i++)
        [(Shape *)[list at:i] badgeInContext:ctx];
    stage(ctx, "category-badges");

    /* ---- stage 4: hand-cast objc_msgSend, including a QZRect return. Four
     * doubles is a homogeneous float aggregate: AAPCS64 returns it in d0-d3,
     * NOT through the x8 indirect-result register, so this goes through plain
     * objc_msgSend and there is no _stret variant on arm64 to fall back to.
     * Getting it wrong misplaces every outline by whatever garbage was in
     * d0-d3, which the pixel diff catches and a status code does not. ---- */
    QZRect (*msgSendRect)(id, SEL) = (QZRect (*)(id, SEL))objc_msgSend;
    QZContextSetRGBStrokeColor(ctx, 0.98, 0.98, 0.98, 0.55);
    QZContextSetLineWidth(ctx, 1.0);
    for (unsigned i = 0; i < [list count]; i++) {
        id s = [list at:i];
        QZRect f = msgSendRect(s, sel_registerName("insetFrame"));
        printf("inset-frame %u %.1f,%.1f %.1fx%.1f\n", i,
               f.origin.x, f.origin.y, f.size.width, f.size.height);
        QZContextStrokeRect(ctx, f);
    }
    stage(ctx, "msgsend-outline");

    /* ---- stage 5: THE TRANSCENDENTAL STAGE. -[Vane drawInContext:] is the
     * only code in this fixture that reaches cos/sin. Two vanes at two angles
     * so a single unlucky argument cannot make it agree by accident. Vane is
     * not in the list, so this stage is separable from stage 2's checksum. ---- */
    Vane *v1 = (Vane *)mk(cVane, QZRectMake(104, 60, 84, 72), 6, 0.0,
                          0.95, 0.95, 0.98, 0.90);
    [v1 setAngle:0.5235987755982988];               /* pi/6 */
    Vane *v2 = (Vane *)mk(cVane, QZRectMake( 24, 12, 84, 48), 7, 0.0,
                          0.60, 0.86, 0.92, 0.90);
    [v2 setAngle:-1.1780972450961724];              /* -3pi/8 */
    [v1 drawInContext:ctx];
    [v2 drawInContext:ctx];
    stage(ctx, "rotated-vanes");

    if (!QZContextWritePNG(ctx, out)) {
        fprintf(stderr, "QZContextWritePNG(%s) failed\n", out);
        QZContextRelease(ctx);
        return 3;
    }
    printf("wrote %s\n", out);

    for (unsigned i = 0; i < [list count]; i++)
        object_dispose([list at:i]);
    object_dispose((id)v2);
    object_dispose((id)v1);
    object_dispose((id)list);
    QZContextRelease(ctx);
    return 0;
}
