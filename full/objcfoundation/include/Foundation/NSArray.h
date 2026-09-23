// NSArray / NSMutableArray = the Swift facade's Foundation.NSArray and
// Foundation.NSMutableArray. Members are Objective-C only.
#ifndef OF_FOUNDATION_NSARRAY_H
#define OF_FOUNDATION_NSARRAY_H

#import <Foundation/NSObject.h>
#import <Foundation/NSRange.h>

@class NSString, NSEnumerator<ObjectType>;

NS_ASSUME_NONNULL_BEGIN

OF_SWIFT_CLASS("_TtC10Foundation7NSArray", "Foundation")
__attribute__((swift_bridge("Swift.Array")))
@interface NSArray<__covariant ObjectType> : NSObject
#if !defined(__swift__)
@property (readonly) NSUInteger count;
- (ObjectType)objectAtIndex:(NSUInteger)index;
- (instancetype)init NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithObjects:(const ObjectType _Nonnull [_Nullable])objects count:(NSUInteger)cnt NS_DESIGNATED_INITIALIZER;
@end

@interface NSArray<ObjectType> (NSExtendedArray)
- (NSArray<ObjectType> *)arrayByAddingObject:(ObjectType)anObject;
- (NSArray<ObjectType> *)arrayByAddingObjectsFromArray:(NSArray<ObjectType> *)otherArray;
- (NSString *)componentsJoinedByString:(NSString *)separator;
- (BOOL)containsObject:(ObjectType)anObject;
@property (readonly, copy) NSString *description;
- (NSUInteger)indexOfObject:(ObjectType)anObject;
- (NSUInteger)indexOfObjectIdenticalTo:(ObjectType)anObject;
- (BOOL)isEqualToArray:(NSArray<ObjectType> *)otherArray;
@property (nullable, nonatomic, readonly) ObjectType firstObject;
@property (nullable, nonatomic, readonly) ObjectType lastObject;
- (NSEnumerator<ObjectType> *)objectEnumerator;
- (NSEnumerator<ObjectType> *)reverseObjectEnumerator;
- (NSArray<ObjectType> *)sortedArrayUsingSelector:(SEL)comparator;
- (NSArray<ObjectType> *)sortedArrayUsingComparator:(NSComparator NS_NOESCAPE)cmptr;
- (NSArray<ObjectType> *)subarrayWithRange:(NSRange)range;
- (void)makeObjectsPerformSelector:(SEL)aSelector;
- (void)makeObjectsPerformSelector:(SEL)aSelector withObject:(nullable id)argument;
- (ObjectType)objectAtIndexedSubscript:(NSUInteger)idx;
- (void)enumerateObjectsUsingBlock:(void (NS_NOESCAPE ^)(ObjectType obj, NSUInteger idx, BOOL *stop))block;
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained _Nullable [_Nonnull])buffer
                                    count:(NSUInteger)len;
@end

@interface NSArray<ObjectType> (NSArrayCreation)
+ (instancetype)array;
+ (instancetype)arrayWithObject:(ObjectType)anObject;
+ (instancetype)arrayWithObjects:(const ObjectType _Nonnull [_Nonnull])objects count:(NSUInteger)cnt;
+ (instancetype)arrayWithObjects:(ObjectType)firstObj, ... NS_REQUIRES_NIL_TERMINATION;
+ (instancetype)arrayWithArray:(NSArray<ObjectType> *)array;
- (instancetype)initWithObjects:(ObjectType)firstObj, ... NS_REQUIRES_NIL_TERMINATION;
- (instancetype)initWithArray:(NSArray<ObjectType> *)array;
#endif
@end

OF_SWIFT_CLASS("_TtC10Foundation14NSMutableArray", "Foundation")
@interface NSMutableArray<ObjectType> : NSArray<ObjectType>
#if !defined(__swift__)
- (void)addObject:(ObjectType)anObject;
- (void)insertObject:(ObjectType)anObject atIndex:(NSUInteger)index;
- (void)removeLastObject;
- (void)removeObjectAtIndex:(NSUInteger)index;
- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(ObjectType)anObject;
- (instancetype)init NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCapacity:(NSUInteger)numItems NS_DESIGNATED_INITIALIZER;
@end

@interface NSMutableArray<ObjectType> (NSExtendedMutableArray)
- (void)addObjectsFromArray:(NSArray<ObjectType> *)otherArray;
- (void)removeAllObjects;
- (void)removeObject:(ObjectType)anObject;
- (void)removeObjectIdenticalTo:(ObjectType)anObject;
- (void)setObject:(ObjectType)obj atIndexedSubscript:(NSUInteger)idx;
- (void)sortUsingSelector:(SEL)comparator;
- (void)sortUsingComparator:(NSComparator NS_NOESCAPE)cmptr;
@end

@interface NSMutableArray<ObjectType> (NSMutableArrayCreation)
+ (instancetype)arrayWithCapacity:(NSUInteger)numItems;
#endif
@end

NS_ASSUME_NONNULL_END

#endif
