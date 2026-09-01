#include "IOKit.h"

#include <stdio.h>

static int require(int condition, const char *message) {
    if (!condition) {
        fprintf(stderr, "IOKitHostTests: %s\n", message);
        return 0;
    }
    return 1;
}

int main(void) {
    io_iterator_t iterator = 99;
    int ok = 1;
    ok &= require(IOBSDNameMatching(0, 0, "en0") == NULL,
                  "matching must fail closed");
    ok &= require(IOServiceGetMatchingServices(0, NULL, &iterator) ==
                      kIOReturnUnsupported,
                  "matching services must report unsupported");
    ok &= require(iterator == IO_OBJECT_NULL,
                  "matching services must clear its iterator");
    ok &= require(IOIteratorNext(99) == IO_OBJECT_NULL,
                  "iterator must never fabricate a service");
    ok &= require(IORegistryEntryCreateCFProperty(99, NULL, NULL, 0) == NULL,
                  "property lookup must fail closed");
    ok &= require(IORegistryEntrySearchCFProperty(
                      99,
                      kIOServicePlane,
                      NULL,
                      NULL,
                      kIORegistryIterateRecursively |
                          kIORegistryIterateParents) == NULL,
                  "recursive property search must fail closed");
    ok &= require(IOObjectRelease(99) == kIOReturnUnsupported,
                  "unknown object release must report unsupported");
    if (!ok) {
        return 1;
    }
    puts("IOKIT_HOST_OK matching=nil services=unsupported iterator=nil properties=nil");
    return 0;
}
