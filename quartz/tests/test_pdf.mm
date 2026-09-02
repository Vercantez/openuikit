#import <Foundation/Foundation.h>
#include "test_common.h"
#include <string.h>
#include <sys/stat.h>

enum { kW = 320, kH = 240 };
static const char *kPath = "/tmp/qz_pdf_test.pdf";
static const char *kPathOut = "output/qz_pdf_test.pdf";

static CGContextRef apple_ctx(void) {
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(
        NULL, kW, kH, 8, (size_t)kW * 4, cs,
        kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(cs);
    if (ctx) CGContextClearRect(ctx, CGRectMake(0, 0, kW, kH));
    return ctx;
}

static QZContextRef qz_ctx(void) {
    return QZBitmapContextCreate(NULL, kW, kH, 8, (size_t)kW * 4,
                                 kQZImageAlphaPremultipliedLast);
}

static void draw_scene(QZContextRef ctx) {
    QZPDFContextSetRGBFillColor(ctx, 1, 1, 1, 1);
    QZPDFContextFillRect(ctx, QZRectMake(0, 0, kW, kH));

    QZPDFContextSetRGBFillColor(ctx, 0.80, 0.12, 0.15, 1);
    QZPDFContextFillRect(ctx, QZRectMake(20, 30, 90, 50));

    QZPDFContextSetRGBFillColor(ctx, 0.15, 0.65, 0.25, 1);
    QZPDFContextFillRect(ctx, QZRectMake(130, 40, 70, 80));

    QZPDFContextSetRGBFillColor(ctx, 0.12, 0.30, 0.85, 1);
    QZPDFContextFillRect(ctx, QZRectMake(40, 140, 120, 55));

    QZPDFContextSetRGBFillColor(ctx, 0.95, 0.75, 0.10, 1);
    QZPDFContextBeginPath(ctx);
    QZPDFContextMoveToPoint(ctx, 220, 40);
    QZPDFContextAddLineToPoint(ctx, 300, 40);
    QZPDFContextAddLineToPoint(ctx, 260, 120);
    QZPDFContextClosePath(ctx);
    QZPDFContextFillPath(ctx);

    QZPDFContextSetRGBStrokeColor(ctx, 0.70, 0.10, 0.70, 1);
    QZPDFContextSetLineWidth(ctx, 4);
    QZPDFContextStrokeRect(ctx, QZRectMake(12, 12, 296, 216));

    QZPDFContextSetRGBStrokeColor(ctx, 0.05, 0.55, 0.70, 1);
    QZPDFContextSetLineWidth(ctx, 6);
    QZPDFContextBeginPath(ctx);
    QZPDFContextMoveToPoint(ctx, 30, 200);
    QZPDFContextAddLineToPoint(ctx, 180, 180);
    QZPDFContextAddLineToPoint(ctx, 280, 210);
    QZPDFContextStrokePath(ctx);
}

static double mae_bufs(const uint8_t *a, size_t abpr, const uint8_t *b, size_t bbpr) {
    double sae = 0;
    for (int y = 0; y < kH; y++) {
        const uint8_t *ar = a + (size_t)y * abpr;
        const uint8_t *br = b + (size_t)y * bbpr;
        for (int x = 0; x < kW; x++) {
            for (int c = 0; c < 4; c++) {
                int d = (int)ar[x * 4 + c] - (int)br[x * 4 + c];
                if (d < 0) d = -d;
                sae += d;
            }
        }
    }
    return sae / (kW * kH * 4.0);
}

static double close_pct(const uint8_t *a, size_t abpr, const uint8_t *b, size_t bbpr) {
    int close = 0;
    for (int y = 0; y < kH; y++) {
        const uint8_t *ar = a + (size_t)y * abpr;
        const uint8_t *br = b + (size_t)y * bbpr;
        for (int x = 0; x < kW; x++) {
            int md = 0;
            for (int c = 0; c < 4; c++) {
                int d = (int)ar[x * 4 + c] - (int)br[x * 4 + c];
                if (d < 0) d = -d;
                if (d > md) md = d;
            }
            if (md <= 8) close++;
        }
    }
    return 100.0 * close / (double)(kW * kH);
}

static void dump_rgba(const char *path, const uint8_t *p, size_t bpr) {
    QZContextRef tmp = qz_ctx();
    if (!tmp) return;
    uint8_t *d = (uint8_t *)QZBitmapContextGetData(tmp);
    size_t dbpr = QZBitmapContextGetBytesPerRow(tmp);
    for (int y = 0; y < kH; y++) memcpy(d + (size_t)y * dbpr, p + (size_t)y * bpr, (size_t)kW * 4);
    QZContextWritePNG(tmp, path);
    QZContextRelease(tmp);
}

static void dump_mismatch(const char *name, const uint8_t *a, size_t abpr,
                          const uint8_t *b, size_t bbpr) {
    int n = 0;
    for (int y = 0; y < kH && n < 12; y++) {
        const uint8_t *ar = a + (size_t)y * abpr;
        const uint8_t *br = b + (size_t)y * bbpr;
        for (int x = 0; x < kW && n < 12; x++) {
            int md = 0;
            for (int c = 0; c < 4; c++) {
                int d = (int)ar[x * 4 + c] - (int)br[x * 4 + c];
                if (d < 0) d = -d;
                if (d > md) md = d;
            }
            if (md <= 8) continue;
            fprintf(stderr, "  %s mismatch mem(%d,%d) a=%d %d %d %d b=%d %d %d %d\n",
                    name, x, y, ar[x * 4], ar[x * 4 + 1], ar[x * 4 + 2], ar[x * 4 + 3],
                    br[x * 4], br[x * 4 + 1], br[x * 4 + 2], br[x * 4 + 3]);
            n++;
        }
    }
}

static int check_pair(const char *name, const uint8_t *ref, size_t rbpr,
                      const uint8_t *got, size_t gbpr, double *mae_out, double *close_out) {
    double mae = mae_bufs(ref, rbpr, got, gbpr);
    double close = close_pct(ref, rbpr, got, gbpr);
    if (mae_out) *mae_out = mae;
    if (close_out) *close_out = close;
    printf("%s mae=%.4f close=%.2f%%\n", name, mae, close);
    if (close >= 99.0 && mae < 1.0) return 0;
    fprintf(stderr, "FAIL %s mae=%.4f close=%.2f%%\n", name, mae, close);
    dump_mismatch(name, ref, rbpr, got, gbpr);
    return 1;
}

static int rasterize_apple(const char *path, CGContextRef dest) {
    NSURL *url = [NSURL fileURLWithPath:@(path)];
    CGPDFDocumentRef doc = CGPDFDocumentCreateWithURL((__bridge CFURLRef)url);
    if (!doc) return qz_fail("CGPDFDocumentCreateWithURL");
    size_t np = CGPDFDocumentGetNumberOfPages(doc);
    if (np < 1) {
        CGPDFDocumentRelease(doc);
        return qz_fail("Apple PDF page count");
    }
    CGPDFPageRef page = CGPDFDocumentGetPage(doc, 1);
    if (!page) {
        CGPDFDocumentRelease(doc);
        return qz_fail("CGPDFDocumentGetPage");
    }
    CGContextDrawPDFPage(dest, page);
    CGPDFDocumentRelease(doc);
    return 0;
}

static void copy_pdf(const char *src, const char *dst) {
    FILE *in = fopen(src, "rb");
    FILE *out = fopen(dst, "wb");
    if (!in || !out) {
        if (in) fclose(in);
        if (out) fclose(out);
        return;
    }
    char buf[4096];
    size_t n;
    while ((n = fread(buf, 1, sizeof(buf), in)) > 0) fwrite(buf, 1, n, out);
    fclose(in);
    fclose(out);
}

int main(void) {
    mkdir("output", 0755);

    QZContextRef ref = QZPDFContextCreate(kPath, QZRectMake(0, 0, kW, kH));
    if (!ref) return qz_fail("QZPDFContextCreate");
    draw_scene(ref);
    QZPDFContextClose(ref);

    FILE *fp = fopen(kPath, "rb");
    if (!fp) {
        QZContextRelease(ref);
        return qz_fail("pdf file missing");
    }
    char hdr[8] = {0};
    size_t nr = fread(hdr, 1, 5, fp);
    fclose(fp);
    if (nr != 5 || memcmp(hdr, "%PDF-", 5) != 0) {
        QZContextRelease(ref);
        return qz_fail("pdf header");
    }
    copy_pdf(kPath, kPathOut);

    const uint8_t *rp = (const uint8_t *)QZBitmapContextGetData(ref);
    size_t rbpr = QZBitmapContextGetBytesPerRow(ref);

    CGContextRef ac = apple_ctx();
    if (!ac) {
        QZContextRelease(ref);
        return qz_fail("apple bitmap");
    }
    if (rasterize_apple(kPath, ac)) {
        CGContextRelease(ac);
        QZContextRelease(ref);
        return 1;
    }
    const uint8_t *ap = (const uint8_t *)CGBitmapContextGetData(ac);
    size_t abpr = CGBitmapContextGetBytesPerRow(ac);
    double apple_mae = 0, apple_close = 0;
    int apple_fail = check_pair("apple CGPDF", rp, rbpr, ap, abpr, &apple_mae, &apple_close);
    if (apple_fail) {
        dump_rgba("output/pdf_ref.png", rp, rbpr);
        dump_rgba("output/pdf_apple.png", ap, abpr);
    }

    QZPDFDocumentRef doc = QZPDFDocumentCreateWithFile(kPath);
    if (!doc) {
        CGContextRelease(ac);
        QZContextRelease(ref);
        return qz_fail("QZPDFDocumentCreateWithFile");
    }
    if (QZPDFDocumentGetNumberOfPages(doc) != 1) {
        QZPDFDocumentRelease(doc);
        CGContextRelease(ac);
        QZContextRelease(ref);
        return qz_fail("page count");
    }
    QZPDFPageRef page = QZPDFDocumentGetPage(doc, 1);
    QZRect box = QZPDFPageGetBoxRect(page);
    if (fabs(box.size.width - kW) > 0.5 || fabs(box.size.height - kH) > 0.5) {
        QZPDFDocumentRelease(doc);
        CGContextRelease(ac);
        QZContextRelease(ref);
        return qz_fail("MediaBox");
    }

    QZContextRef qc = qz_ctx();
    if (!qc) {
        QZPDFDocumentRelease(doc);
        CGContextRelease(ac);
        QZContextRelease(ref);
        return qz_fail("qz bitmap");
    }
    QZContextDrawPDFPage(qc, page);
    const uint8_t *qp = (const uint8_t *)QZBitmapContextGetData(qc);
    size_t qbpr = QZBitmapContextGetBytesPerRow(qc);
    double qz_mae = 0, qz_close = 0;
    int qz_fail_cmp = check_pair("QZ DrawPDFPage", rp, rbpr, qp, qbpr, &qz_mae, &qz_close);
    if (qz_fail_cmp) dump_rgba("output/pdf_qz.png", qp, qbpr);

    QZContextRelease(qc);
    QZPDFDocumentRelease(doc);
    CGContextRelease(ac);
    QZContextRelease(ref);

    if (apple_fail || qz_fail_cmp) return 1;
    printf("PASS pdf apple mae=%.4f close=%.2f%% qz mae=%.4f close=%.2f%%\n",
           apple_mae, apple_close, qz_mae, qz_close);
    return 0;
}
