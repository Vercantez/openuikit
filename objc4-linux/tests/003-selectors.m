// 003-selectors -- uniquing and round-tripping.
// A SEL is a pointer into the runtime's own string table; two registrations of
// the same name must yield the identical pointer, and @selector must land in
// the same table as sel_registerName.
#include "testsupport.h"

@interface Dummy : TestRoot
- (void)foo:(int)a bar:(int)b;
@end
@implementation Dummy
- (void)foo:(int)a bar:(int)b { (void)a; (void)b; }
@end

static const char *const kNames[] = {
    "a",
    "init",
    "setValue:forKey:",
    "::",
    ".leadingDot",
    "with spaces",
    "-",
    "1digitLeading",
    "UPPER",
    "veryLongSelectorNameThatIsDefinitelyNotInAnyPreexistingSelectorTable:",
};

int main(void) {
    SEL s1 = sel_registerName("foo:bar:");
    SEL s2 = sel_registerName("foo:bar:");
    SEL s3 = @selector(foo:bar:);

    say("register.stable=%s", YN(s1 == s2));
    say("atselector.matches.register=%s", YN(s1 == s3));
    say("sel_isEqual=%s", YN(sel_isEqual(s1, s2)));
    say("name=%s", sel_getName(s1));
    say("getUid.matches=%s", YN(sel_getUid("foo:bar:") == s1));

    SEL other = sel_registerName("foo:baz:");
    say("distinct.names.distinct.sels=%s", YN(other != s1));
    say("sel_isEqual.distinct=%s", YN(sel_isEqual(other, s1)));

    // Round-trip a spread of shapes, including ones no compiler would emit.
    for (unsigned i = 0; i < sizeof(kNames)/sizeof(kNames[0]); i++) {
        SEL s = sel_registerName(kNames[i]);
        const char *back = sel_getName(s);
        say("roundtrip[%u].ok=%s", i, YN(strcmp(back, kNames[i]) == 0));
        say("roundtrip[%u].stable=%s", i, YN(sel_registerName(kNames[i]) == s));
    }

    // The empty selector is legal and distinct from everything else.
    SEL empty = sel_registerName("");
    say("empty.name=[%s]", sel_getName(empty));
    say("empty.distinct=%s", YN(empty != s1));
    say("empty.stable=%s", YN(sel_registerName("") == empty));

    // Nil handling.
    say("nil.getName=%s", sel_getName((SEL)0));
    say("nil.registerName=%s", NULLNESS(sel_registerName(NULL)));

    // A selector registered by hand is usable for dispatch on a class that
    // declares the matching method.
    Class dummy = objc_getClass("Dummy");
    say("class_respondsToSelector=%s", YN(class_respondsToSelector(dummy, s1)));
    say("class_respondsToSelector.other=%s", YN(class_respondsToSelector(dummy, other)));
    return 0;
}
