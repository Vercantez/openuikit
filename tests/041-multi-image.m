// 041-multi-image -- everything that has to work ACROSS an image boundary.
//
// Every other test in the corpus is a single translation unit in a single
// image, so the whole of image discovery is exercised by exactly one image:
// the executable. This test puts the root class in a separate shared library
// (041-multi-image.lib.m) and the subclass and category in the executable, so
// it measures:
//
//   * +load ordering across images -- the library's must run first, because
//     the executable depends on it
//   * a superclass reference that is resolved in a different image
//   * a category in image A attaching to a class in image B
//   * class_getImageName distinguishing the two
//
// Output is deliberately path-free: the library is a .dylib on Darwin and a
// .so on Linux, and it lives in a different directory in each harness.
#include "testsupport.h"
#include "041-multi-image.h"

// A category, in the EXECUTABLE, on a class that lives in the LIBRARY.
@interface LibRoot (FromExecutable)
- (int)addedByExecutable;
- (int)overridable;
@end
@implementation LibRoot (FromExecutable)
- (int)addedByExecutable { return 41; }
- (int)overridable { return 20; }
@end

// A subclass, in the EXECUTABLE, of a class that lives in the LIBRARY.
@interface Derived : LibRoot
- (int)base;
@end
@implementation Derived
+ (void)load {
    say("ev[exe]=Derived.load");
}
- (int)base { return 100 + [super base]; }
@end

int main(void) {
    Class lib = objc_getClass("LibRoot");
    Class der = objc_getClass("Derived");
    say("libroot=%s", NULLNESS(lib));
    say("derived=%s", NULLNESS(der));
    say("derived.superclass==libroot=%s", YN(class_getSuperclass(der) == lib));
    say("derivedMeta.superclass==libMeta=%s",
        YN(class_getSuperclass(object_getClass(der)) == object_getClass(lib)));

    id d = [Derived alloc];
    say("derived.base=%d", [d base]);                 // 100 + library's 1
    say("derived.addedByExecutable=%d", [d addedByExecutable]);
    say("derived.overridable=%d", [d overridable]);   // category wins over lib

    id l = [LibRoot alloc];
    say("libroot.base=%d", [l base]);
    say("libroot.addedByExecutable=%d", [l addedByExecutable]);
    say("libroot.overridable=%d", [l overridable]);

    // The two classes must be attributed to two different images, and both
    // must be attributed to something.
    const char *libImage = class_getImageName(lib);
    const char *derImage = class_getImageName(der);
    say("libroot.image=%s", NULLNESS(libImage));
    say("derived.image=%s", NULLNESS(derImage));
    say("images.differ=%s",
        YN(libImage && derImage && strcmp(libImage, derImage) != 0));

    // TestRoot is compiled into the executable, so it must be attributed to
    // the same image as Derived and a different one from LibRoot. That is a
    // path-free way to say "the executable is one image and the library is
    // another".
    const char *rootImage = class_getImageName(objc_getClass("TestRoot"));
    say("testroot.image=%s", NULLNESS(rootImage));
    say("derived.image==testroot.image=%s",
        YN(rootImage && derImage && strcmp(rootImage, derImage) == 0));
    say("libroot.image!=testroot.image=%s",
        YN(rootImage && libImage && strcmp(rootImage, libImage) != 0));

    say("respondsTo.addedByExecutable=%s",
        YN(class_respondsToSelector(lib, @selector(addedByExecutable))));
    say("libroot.instanceSize=%zu", (size_t)class_getInstanceSize(lib));
    say("derived.instanceSize=%zu", (size_t)class_getInstanceSize(der));
    return 0;
}
