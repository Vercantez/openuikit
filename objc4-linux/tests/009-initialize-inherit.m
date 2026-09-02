// 009-initialize-inherit -- +initialize is inherited, and that is a trap.
//
// A class with no +initialize of its own inherits the superclass's, which is
// therefore invoked once PER CLASS with a different `self` each time. Also:
// touching a subclass initializes every uninitialized superclass first.
#include "testsupport.h"

static int parentBody_runs;

@interface IParent : TestRoot
+ (int)tag;
@end
@implementation IParent
+ (void)initialize {
    parentBody_runs++;
    eventf("initialize.body self=%s", class_getName(self));
}
+ (int)tag { return 1; }
@end

// No +initialize of its own -- inherits IParent's.
@interface IChild : IParent @end
@implementation IChild
+ (int)tag { return 2; }
@end

// Has its own; the superclass's must still run first.
@interface IChild2 : IParent @end
@implementation IChild2
+ (void)initialize { eventf("IChild2.own.initialize self=%s", class_getName(self)); }
@end

@interface IGrandchild : IChild @end
@implementation IGrandchild @end

// A separate chain, touched only through the deepest class, to show the
// top-down cascade.
static int cascade_runs;
@interface CTop : TestRoot @end
@implementation CTop
+ (void)initialize { cascade_runs++; eventf("cascade self=%s", class_getName(self)); }
@end
@interface CMid : CTop @end
@implementation CMid @end
@interface CBot : CMid @end
@implementation CBot @end

int main(void) {
    event("main");

    say("parentBody.before=%d", parentBody_runs);

    // Touch the CHILD first. The parent must initialize before it.
    say("child.tag=%d", [IChild tag]);
    say("parentBody.after.child=%d", parentBody_runs);

    // Touching the parent now must not re-run anything.
    say("parent.tag=%d", [IParent tag]);
    say("parentBody.after.parent=%d", parentBody_runs);

    // Grandchild: parent's body runs a third time, with self=IGrandchild.
    say("grandchild.tag=%d", [IGrandchild tag]);
    say("parentBody.after.grandchild=%d", parentBody_runs);

    // A child with its OWN +initialize does not run the parent's body again
    // for itself, but the parent's own initialization has already happened.
    say("child2.tag=%d", [IChild2 tag]);
    say("parentBody.after.child2=%d", parentBody_runs);

    // Deep cascade touched only at the bottom.
    say("cascade.before=%d", cascade_runs);
    [CBot class];
    say("cascade.after=%d", cascade_runs);

    print_events("ev");
    return 0;
}
