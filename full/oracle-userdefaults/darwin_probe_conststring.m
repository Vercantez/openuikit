// What does REAL Darwin's __NSCFConstantString answer for the selectors CF
// dispatches to it?
//
// WHY THIS EXISTS. `__NSCFConstantString` is the one class in the bridged
// surface whose isa can NEVER match CFString's registered slot -- the isa is
// stamped into __DATA by the compiler before any registration exists. So CF
// takes the ObjC branch for EVERY constant string, always, and each selector it
// reaches has to be right rather than merely present.
//
// Implementing them from the header would be guessing. These are SPI with no
// documentation, and the interesting cases are the edges: does a constant
// string report NUL-terminated contents? what does the 8-bit class say when
// asked for WIDE contents? does `requiresNullTermination` change the answer?
//
// Build:  clang -fobjc-arc -framework Foundation -framework CoreFoundation \
//               darwin_probe_conststring.m -o /tmp/dpcs && /tmp/dpcs

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

static const char *sendFastC(id obj, BOOL nullTerm) {
    SEL s = sel_registerName("_fastCStringContents:");
    if (![obj respondsToSelector:s]) return (const char *)-1;
    const char *(*fn)(id, SEL, BOOL) = (void *)objc_msgSend;
    return fn(obj, s, nullTerm);
}
static const void *sendFastChars(id obj) {
    SEL s = sel_registerName("_fastCharacterContents");
    if (![obj respondsToSelector:s]) return (const void *)-1;
    const void *(*fn)(id, SEL) = (void *)objc_msgSend;
    return fn(obj, s);
}
static long sendLong(id obj, const char *name) {
    SEL s = sel_registerName(name);
    if (![obj respondsToSelector:s]) return -999;
    long (*fn)(id, SEL) = (void *)objc_msgSend;
    return fn(obj, s);
}

static void report(const char *label, id obj) {
    printf("\n--- %s   isa=%s\n", label, object_getClassName(obj));

    const char *c1 = sendFastC(obj, YES);
    const char *c0 = sendFastC(obj, NO);
    if (c1 == (const char *)-1) printf("  _fastCStringContents:      NOT IMPLEMENTED on this class\n");
    else {
        printf("  _fastCStringContents:YES   %s", c1 ? "non-NULL" : "NULL");
        if (c1) printf("  -> \"%s\"  (len %zu)", c1, strlen(c1));
        printf("\n");
        printf("  _fastCStringContents:NO    %s", c0 ? "non-NULL" : "NULL");
        if (c0) printf("  -> \"%s\"", c0);
        printf("\n");
        printf("  same pointer for YES/NO?   %s\n", (c1 == c0) ? "YES" : "no");
        if (c1) {
            // THE QUESTION THAT DECIDES THE IMPLEMENTATION: is the byte after
            // the contents a NUL? If Darwin hands back a pointer when
            // requiresNullTermination is YES, the bytes must be terminated.
            CFIndex n = CFStringGetLength((CFStringRef)obj);
            printf("  byte at [length] (%ld)      0x%02x %s\n", (long)n,
                   (unsigned char)c1[n],
                   c1[n] == 0 ? "(NUL -- terminated)" : "(NOT NUL)");
        }
    }

    const void *w = sendFastChars(obj);
    if (w == (const void *)-1) printf("  _fastCharacterContents     NOT IMPLEMENTED on this class\n");
    else printf("  _fastCharacterContents     %s  (8-bit strings must say NULL)\n",
                w ? "non-NULL" : "NULL");

    // The public entry point that dispatches to the above, for cross-checking.
    const char *pub = CFStringGetCStringPtr((CFStringRef)obj, kCFStringEncodingASCII);
    printf("  CFStringGetCStringPtr(ASCII) %s\n", pub ? pub : "NULL");
    const char *pub8 = CFStringGetCStringPtr((CFStringRef)obj, kCFStringEncodingUTF8);
    printf("  CFStringGetCStringPtr(UTF8)  %s\n", pub8 ? pub8 : "NULL");
    const UniChar *pubw = CFStringGetCharactersPtr((CFStringRef)obj);
    printf("  CFStringGetCharactersPtr     %s\n", pubw ? "non-NULL" : "NULL");

    printf("  length                       %ld\n", (long)CFStringGetLength((CFStringRef)obj));
    printf("  hash (CFHash)                0x%lx\n", (unsigned long)CFHash((CFTypeRef)obj));
    printf("  _cfTypeID via CFGetTypeID    %lu  (CFString is %lu)\n",
           (unsigned long)CFGetTypeID((CFTypeRef)obj), (unsigned long)CFStringGetTypeID());
    long enc = sendLong(obj, "_fastestEncodingInCFStringEncoding");
    if (enc != -999) printf("  _fastestEncodingInCFStringEncoding  %ld\n", enc);
    long senc = sendLong(obj, "_smallestEncodingInCFStringEncoding");
    if (senc != -999) printf("  _smallestEncodingInCFStringEncoding %ld\n", senc);
}

int main(void) {
    @autoreleasepool {
        printf("=== Darwin __NSCFConstantString: what CF actually gets back ===\n");
        printf("macOS %s\n", [[[NSProcessInfo processInfo] operatingSystemVersionString] UTF8String]);

        report("CFSTR(\"hello\")            constant, narrow", (id)CFSTR("hello"));
        report("CFSTR(\"\")                 constant, empty", (id)CFSTR(""));
        report("CFSTR(\"a/b/c.plist\")      constant, path-shaped", (id)CFSTR("a/b/c.plist"));

        // A DYNAMIC 8-bit string, to show which answers belong to CONSTANTS and
        // which to 8-bit-ness. Without this control an implementer cannot tell
        // whether a behaviour is the constant class's or CFString's.
        CFStringRef dyn = CFStringCreateWithCString(NULL, "hello", kCFStringEncodingUTF8);
        report("CFStringCreateWithCString  DYNAMIC 8-bit (control)", (id)dyn);

        // A WIDE string: the 8-bit fast paths must refuse it.
        CFStringRef wide = CFStringCreateWithCString(NULL, "caf\xc3\xa9", kCFStringEncodingUTF8);
        report("CFStringCreateWithCString  DYNAMIC non-ASCII (control)", (id)wide);

        // ---- _getCString:maxLength:encoding:
        //
        // Named by execution: T19's CFStringGetCString aborted on it. CF calls
        // it as `_getCString:buffer maxLength:bufferSize - 1 encoding:enc`
        // (CFString.c:2324), so maxLength EXCLUDES the NUL -- but whether
        // Darwin's implementation treats it that way is the question, and the
        // boundary is where a copy either overruns a caller's buffer or
        // needlessly refuses. Measured, not reasoned.
        printf("\n--- _getCString:maxLength:encoding: on CFSTR(\"hello\")  (len 5)\n");
        {
            SEL s = sel_registerName("_getCString:maxLength:encoding:");
            id k = (id)CFSTR("hello");
            if (![k respondsToSelector:s]) printf("  NOT IMPLEMENTED\n");
            else {
                BOOL (*fn)(id, SEL, char *, NSUInteger, unsigned int) = (void *)objc_msgSend;
                unsigned int encs[] = { kCFStringEncodingUTF8, kCFStringEncodingASCII,
                                        kCFStringEncodingMacRoman, kCFStringEncodingUnicode,
                                        kCFStringEncodingISOLatin1 };
                const char *encn[] = { "UTF8", "ASCII", "MacRoman", "Unicode(UTF16)", "ISOLatin1" };
                for (int e = 0; e < 5; e++) {
                    char b[64]; memset(b, 0xAA, sizeof b);
                    BOOL r = fn(k, s, b, 32, encs[e]);
                    printf("  maxLength=32 enc=%-14s -> %s", encn[e], r ? "true " : "false");
                    if (r) printf("  buf=\"%s\"  byte[5]=0x%02x %s", b, (unsigned char)b[5],
                                  b[5] == 0 ? "(NUL)" : "(NOT NUL)");
                    printf("\n");
                }
                printf("  --- the boundary, UTF8, string length 5:\n");
                for (int m = 3; m <= 7; m++) {
                    char b[64]; memset(b, 0xAA, sizeof b);
                    BOOL r = fn(k, s, b, (NSUInteger)m, kCFStringEncodingUTF8);
                    printf("    maxLength=%d -> %s", m, r ? "true " : "false");
                    if (r) {
                        printf("  buf=\"%s\"", b);
                        int term = -1;
                        for (int i = 0; i < 16; i++) if ((unsigned char)b[i] == 0) { term = i; break; }
                        printf("  NUL at index %d", term);
                    }
                    printf("\n");
                }
                // Does the PUBLIC entry point agree? CF passes bufferSize-1, so
                // CFStringGetCString(str, buf, 6, UTF8) becomes maxLength 5.
                char b2[64];
                printf("  --- CFStringGetCString (public; passes bufferSize-1):\n");
                for (int sz = 4; sz <= 7; sz++) {
                    memset(b2, 0xAA, sizeof b2);
                    Boolean r = CFStringGetCString(CFSTR("hello"), b2, sz, kCFStringEncodingUTF8);
                    printf("    bufferSize=%d -> %s%s%s\n", sz, r ? "true " : "false",
                           r ? "  buf=" : "", r ? b2 : "");
                }
            }
        }

        // Identity, because selector-reentry.md records that CFSTR twice yields
        // ONE pointer -- which is why t9's dictionary lookup never hashed.
        printf("\n--- identity\n");
        printf("  CFSTR(\"x\") == CFSTR(\"x\") ?   %s\n",
               (CFSTR("x") == CFSTR("x")) ? "SAME POINTER" : "distinct");
        CFStringRef d1 = CFStringCreateWithCString(NULL, "x", kCFStringEncodingUTF8);
        printf("  CFEqual(CFSTR(\"x\"), dynamic \"x\")  %s\n",
               CFEqual(CFSTR("x"), d1) ? "true" : "FALSE");
        printf("  CFHash equal across the two?      %s\n",
               CFHash(CFSTR("x")) == CFHash(d1) ? "yes" : "NO");
        CFRelease(d1); CFRelease(dyn); CFRelease(wide);
    }
    return 0;
}
