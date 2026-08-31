/* OWNED BY package pdf. Do not edit from other packages. */
#ifndef QUARTZ_PDF_H
#define QUARTZ_PDF_H
#ifdef __cplusplus
extern "C" {
#endif

typedef struct QZPDFDocument *QZPDFDocumentRef;
typedef struct QZPDFPage *QZPDFPageRef;

/* Bitmap-backed PDF writer. Drawing must go through the QZPDFContext*
 * helpers below so operators are recorded. QZPDFContextClose writes the
 * file; the context (and its pixels) stay valid until QZContextRelease. */
QZContextRef QZPDFContextCreate(const char *path, QZRect mediaBox);
void QZPDFContextBeginPage(QZContextRef ctx, const QZRect *mediaBox);
void QZPDFContextEndPage(QZContextRef ctx);
void QZPDFContextClose(QZContextRef ctx);

void QZPDFContextSetRGBFillColor(QZContextRef ctx, QZFloat r, QZFloat g, QZFloat b, QZFloat a);
void QZPDFContextSetRGBStrokeColor(QZContextRef ctx, QZFloat r, QZFloat g, QZFloat b, QZFloat a);
void QZPDFContextSetLineWidth(QZContextRef ctx, QZFloat width);
void QZPDFContextFillRect(QZContextRef ctx, QZRect rect);
void QZPDFContextStrokeRect(QZContextRef ctx, QZRect rect);
void QZPDFContextBeginPath(QZContextRef ctx);
void QZPDFContextMoveToPoint(QZContextRef ctx, QZFloat x, QZFloat y);
void QZPDFContextAddLineToPoint(QZContextRef ctx, QZFloat x, QZFloat y);
void QZPDFContextAddCurveToPoint(QZContextRef ctx, QZFloat cp1x, QZFloat cp1y,
                                 QZFloat cp2x, QZFloat cp2y, QZFloat x, QZFloat y);
void QZPDFContextClosePath(QZContextRef ctx);
void QZPDFContextFillPath(QZContextRef ctx);
void QZPDFContextStrokePath(QZContextRef ctx);

QZPDFDocumentRef QZPDFDocumentCreateWithFile(const char *path);
QZPDFDocumentRef QZPDFDocumentCreateWithBytes(const uint8_t *bytes, size_t length);
void QZPDFDocumentRelease(QZPDFDocumentRef doc);
size_t QZPDFDocumentGetNumberOfPages(QZPDFDocumentRef doc);
QZPDFPageRef QZPDFDocumentGetPage(QZPDFDocumentRef doc, size_t index); /* 1-based */
QZRect QZPDFPageGetBoxRect(QZPDFPageRef page);
void QZContextDrawPDFPage(QZContextRef ctx, QZPDFPageRef page);

/* Rasterise one PDF page into straight-alpha RGBA8.  This is the bounded,
 * dependency-free entry point used by OpenUIKit's asset-catalog loader.
 * `scale` is pixels per PDF point.  The returned buffer is
 * width*height*4 bytes and is released with QZImageFreeRGBA.  Unsupported or
 * malformed PDF constructs fail closed and return NULL. */
uint8_t *QZPDFPageRasterizeRGBA(QZPDFPageRef page, QZFloat scale,
                                int *out_width, int *out_height);

#ifdef __cplusplus
}
#endif
#endif
