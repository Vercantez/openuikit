// Shared declarations for the two images of 041-multi-image.
//
// LibRoot is defined by 041-multi-image.lib.m, which is built as a separate
// shared library; the test executable only ever sees this declaration. That is
// the point of the test: everything the runtime has to do across an image
// boundary -- superclass fixup, category attach, +load ordering -- happens
// here and nowhere else in the corpus.
#ifndef OBJC4_041_MULTI_IMAGE_H
#define OBJC4_041_MULTI_IMAGE_H

#include <objc/objc.h>
#include <objc/runtime.h>
#include <objc/message.h>

@interface LibRoot {
@public
    Class isa;
    int   fromLib;
}
+ (id)alloc;
+ (Class)class;
- (id)self;
- (int)base;
- (int)overridable;
@end

#endif
