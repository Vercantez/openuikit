/* __NSCFType — the shared base for every bridged CF class.
 *
 * IN A HEADER, not repeated per-file. The first attempt declared
 * `@interface __NSCFType : NSObject @end` inline in each of the seven .m files
 * and every one failed with "trying to recursively use '__NSCFType'": an
 * @interface with a body is a definition, not a forward declaration, and a
 * class cannot be defined once per translation unit the way a @class can be
 * forward-declared. Inheritance needs the definition, so the definition has to
 * be shared -- which is what a header is for.
 *
 * Implementation and the reasoning are in src/nscf/NSCFType.m.
 */
#ifndef NSCF_TYPE_H
#define NSCF_TYPE_H
#import <objc/NSObject.h>

@interface __NSCFType : NSObject
- (instancetype)retain;
- (oneway void)release;
- (NSUInteger)retainCount;
@end

#endif
