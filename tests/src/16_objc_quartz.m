/* 16_objc_quartz -- rung (o): the smallest program in which Objective-C draws.
 *
 * This fixture exists to be a BISECTION POINT, not a demonstration. Its sibling
 * 17_objc_shapes is the real exercise -- inheritance, a category, a protocol,
 * +load/+initialize, polymorphic dispatch over a collection. When that one
 * fails, the first question is "is it the composition, or is it the fact that
 * libobjc and libquartz are in the same process at all?". This one answers it:
 *
 *   ONE root class. ONE ivar. ONE message. ONE filled ellipse. ONE PNG.
 *
 * If 16 passes and 17 fails, the bug is in what 17 adds. If 16 fails, nothing
 * about 17 is worth reading yet.
 *
 * Three images are loaded, which is one more than any fixture before rung (n)
 * needed: /usr/lib/libquartz.dylib, /usr/lib/libobjc.A.dylib and
 * /usr/lib/libSystem.B.dylib. That alone is new -- 15_quartz proved quartz
 * under machorun with no ObjC anywhere, and 09_objc proved ObjC under machorun
 * with no drawing anywhere. Neither proved they compose.
 *
 * Deliberately Foundation-free, exactly like 09_objc: a root class with its
 * own `Class isa` and instances from class_createInstance(), so nothing here
 * needs NSObject or CoreFoundation.
 *
 * DETERMINISM. No time, no random, no locale-dependent formatting, no
 * hash-ordered iteration, no address is ever printed. The output is a function
 * of the bytes of this binary and of the two dylibs it loads.
 *
 * Output path is argv[1], defaulting to objc_smoke.png in the cwd.
 */
#include <objc/runtime.h>
#include <objc/message.h>
#include <quartz/quartz.h>
#include <stdio.h>

#define W 128
#define H 128

/* FNV-1a over the whole backing store. Same function as 15_quartz's, and for
 * the same reason: a hash that moves for a transposition, five lines, no
 * dependency. Printed so a divergence is visible on stdout before the PNG is
 * ever compared. */
static unsigned long long fnv1a(const unsigned char *p, size_t n)
{
    unsigned long long h = 1469598103934665603ULL;
    for (size_t i = 0; i < n; i++) { h ^= p[i]; h *= 1099511628211ULL; }
    return h;
}

/* Two probes in BITMAP coordinates (row 0 is the top; quartz's user space is
 * y-up): 64,32 lands in the big blob only and 64,64 in the small one on top of
 * it, so the two message sends are distinguishable by colour and not only by a
 * hash that moved. */
static void stage(QZContextRef ctx, int no, const char *what)
{
    const unsigned char *px = (const unsigned char *)QZBitmapContextGetData(ctx);
    size_t bpr = QZBitmapContextGetBytesPerRow(ctx);
    static const int probe[][2] = { {64,32}, {64,64} };
    printf("stage %d %-12s fnv1a=%016llx", no, what, fnv1a(px, bpr * H));
    for (unsigned i = 0; i < sizeof(probe)/sizeof(probe[0]); i++) {
        const unsigned char *q = px + (size_t)probe[i][1] * bpr + (size_t)probe[i][0] * 4;
        printf("  %02x%02x%02x%02x", q[0], q[1], q[2], q[3]);
    }
    printf("\n");
}

/* --------------------------------------------------------------- the class */

@interface Blob {
    Class   isa;        /* root class: we own the isa slot */
    QZFloat radius;
    QZFloat tint;
}
+ (id)blobWithRadius:(QZFloat)r tint:(QZFloat)t;
- (void)drawInContext:(QZContextRef)ctx;
@end

@implementation Blob

+ (id)blobWithRadius:(QZFloat)r tint:(QZFloat)t
{
    Blob *b = (Blob *)class_createInstance(self, 0);
    b->radius = r;
    b->tint   = t;
    return b;
}

/* The one drawing method. Both ivars are reached through the implicit `self`,
 * i.e. through the ivar offset variables libobjc fixed up at image-load time
 * from __DATA,__objc_ivar. A wrong offset does not crash here -- it draws the
 * wrong ellipse in the wrong colour, which is exactly the failure a pixel
 * comparison is for and a return-code check is not. */
- (void)drawInContext:(QZContextRef)ctx
{
    QZContextSetRGBFillColor(ctx, 0.93, 0.16 + tint, 0.16, 1.0);
    QZContextFillEllipseInRect(ctx,
        QZRectMake(W / 2.0 - radius, H / 2.0 - radius, radius * 2, radius * 2));
}

@end

/* ---------------------------------------------------------------- the run */

int main(int argc, char **argv)
{
    const char *out = argc > 1 ? argv[1] : "objc_smoke.png";

    QZContextRef ctx = QZBitmapContextCreate(NULL, W, H, 8, W * 4,
                                             kQZImageAlphaPremultipliedLast);
    if (!ctx) { fprintf(stderr, "QZBitmapContextCreate failed\n"); return 2; }

    printf("objc smoke %dx%d\n", W, H);

    /* Plain C, no ObjC: establishes the baseline framebuffer. */
    QZContextSetRGBFillColor(ctx, 0.10, 0.12, 0.17, 1.0);
    QZContextFillRect(ctx, QZRectMake(0, 0, W, H));
    stage(ctx, 1, "background");

    /* One message send. Written with bracket syntax, which is objc_msgSend. */
    Blob *b = [Blob blobWithRadius:40.0 tint:0.26];
    printf("class=%s\n", class_getName(object_getClass(b)));
    [b drawInContext:ctx];
    stage(ctx, 2, "blob");

    /* The same selector again, dispatched through an explicitly cast
     * objc_msgSend, on a second blob that is smaller and a different colour --
     * different so that it CHANGES the framebuffer. A second identical ellipse
     * would leave stage 3's checksum equal to stage 2's, and a stage that
     * cannot move is a stage that cannot fail. If the bracket-syntax path and
     * the hand-cast call disagree about the IMP, stage 3 says so before the
     * PNG is compared. */
    Blob *b2 = [Blob blobWithRadius:16.0 tint:0.74];
    ((void (*)(id, SEL, QZContextRef))objc_msgSend)(b2, @selector(drawInContext:), ctx);
    stage(ctx, 3, "blob-msgSend");

    if (!QZContextWritePNG(ctx, out)) {
        fprintf(stderr, "QZContextWritePNG(%s) failed\n", out);
        QZContextRelease(ctx);
        return 3;
    }
    printf("wrote %s\n", out);

    object_dispose((id)b2);
    object_dispose((id)b);
    QZContextRelease(ctx);
    return 0;
}
