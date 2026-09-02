/* OWNED BY package data-provider. */
#ifndef QUARTZ_DATA_PROVIDER_H
#define QUARTZ_DATA_PROVIDER_H
#ifdef __cplusplus
extern "C" {
#endif

typedef struct QZDataProvider *QZDataProviderRef;

QZDataProviderRef QZDataProviderCreateWithFilename(const char *path);
QZDataProviderRef QZDataProviderCreateWithData(const void *data, size_t size);
void QZDataProviderRelease(QZDataProviderRef dp);
size_t QZDataProviderGetSize(QZDataProviderRef dp);
const void *QZDataProviderGetBytePtr(QZDataProviderRef dp);
QZImageRef QZImageCreateWithDataProvider(QZDataProviderRef dp, size_t width, size_t height,
                                         size_t bitsPerComponent, size_t bytesPerRow);

#ifdef __cplusplus
}
#endif
#endif
