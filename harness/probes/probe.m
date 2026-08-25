#include <stdint.h>
@protocol Pingable
- (void)ping;
@end

@interface Base { id _ivar; }
+ (id)alloc;
+ (id)self;
- (void)hello;
@end
@implementation Base
+ (void)load {}
+ (id)alloc { return 0; }
+ (id)self { return self; }
- (void)hello {}
@end

@interface Base (Extra) <Pingable>
- (void)ping;
@end
@implementation Base (Extra)
+ (void)load {}
- (void)ping {}
@end

@interface Derived : Base
@property (nonatomic) int value;
@end
@implementation Derived
@synthesize value = _value;
@end

void use(void) {
    Class c = (Class)[Base self];
    [c alloc];
    [(id)c hello];
    Protocol *p = @protocol(Pingable);
    (void)p; (void)c;
}
