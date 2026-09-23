// NSSet / NSMutableSet / NSEnumerator: classes of FoundationObjCBridge (the
// facade has no NSObject set; its NSMutableSet is a plain Swift class).
#ifndef OF_FOUNDATION_NSSET_H
#define OF_FOUNDATION_NSSET_H

#import <Foundation/NSObject.h>

@class NSArray<ObjectType>, NSString;

NS_ASSUME_NONNULL_BEGIN

OF_SWIFT_CLASS("_TtC20FoundationObjCBridge12NSEnumerator", "FoundationObjCBridge")
@interface NSEnumerator<ObjectType> : NSObject
#if !defined(__swift__)
- (nullable ObjectType)nextObject;
@property (readonly, copy) NSArray<ObjectType> *allObjects;
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained _Nullable [_Nonnull])buffer
                                    count:(NSUInteger)len;
#endif
@end

OF_SWIFT_CLASS("_TtC20FoundationObjCBridge5NSSet", "FoundationObjCBridge")
__attribute__((swift_bridge("Swift.Set")))
@interface NSSet<__covariant ObjectType> : NSObject
#if !defined(__swift__)
@property (readonly) NSUInteger count;
- (nullable ObjectType)member:(ObjectType)object;
- (NSEnumerator<ObjectType> *)objectEnumerator;
- (instancetype)init NS_DESIGNATED_INITIALIZER;
@property (readonly, copy) NSArray<ObjectType> *allObjects;
- (nullable ObjectType)anyObject;
- (BOOL)containsObject:(ObjectType)anObject;
@property (readonly, copy) NSString *description;
- (BOOL)isEqualToSet:(NSSet<ObjectType> *)otherSet;
- (NSSet<ObjectType> *)setByAddingObject:(ObjectType)anObject;
- (NSSet<ObjectType> *)objectsPassingTest:(BOOL (NS_NOESCAPE ^)(ObjectType obj, BOOL *stop))predicate;
- (void)enumerateObjectsUsingBlock:(void (NS_NOESCAPE ^)(ObjectType obj, BOOL *stop))block;
- (void)makeObjectsPerformSelector:(SEL)aSelector;
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained _Nullable [_Nonnull])buffer
                                    count:(NSUInteger)len;
+ (instancetype)set;
+ (instancetype)setWithObject:(ObjectType)object;
+ (instancetype)setWithObjects:(ObjectType)firstObj, ... NS_REQUIRES_NIL_TERMINATION;
+ (instancetype)setWithArray:(NSArray<ObjectType> *)array;
+ (instancetype)setWithSet:(NSSet<ObjectType> *)set;
- (instancetype)initWithArray:(NSArray<ObjectType> *)array;
#endif
@end

OF_SWIFT_CLASS("_TtC20FoundationObjCBridge12NSMutableSet", "FoundationObjCBridge")
@interface NSMutableSet<ObjectType> : NSSet<ObjectType>
#if !defined(__swift__)
- (void)addObject:(ObjectType)object;
- (void)removeObject:(ObjectType)object;
- (void)addObjectsFromArray:(NSArray<ObjectType> *)array;
- (void)removeAllObjects;
- (void)unionSet:(NSSet<ObjectType> *)otherSet;
- (instancetype)initWithCapacity:(NSUInteger)numItems;
+ (instancetype)setWithCapacity:(NSUInteger)numItems;
#endif
@end

NS_ASSUME_NONNULL_END

#endif
