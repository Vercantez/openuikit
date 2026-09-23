// NSDictionary / NSMutableDictionary = the Swift facade's classes.
#ifndef OF_FOUNDATION_NSDICTIONARY_H
#define OF_FOUNDATION_NSDICTIONARY_H

#import <Foundation/NSObject.h>

@class NSArray<ObjectType>, NSString, NSEnumerator<ObjectType>;

NS_ASSUME_NONNULL_BEGIN

OF_SWIFT_CLASS("_TtC10Foundation12NSDictionary", "Foundation")
__attribute__((swift_bridge("Swift.Dictionary")))
@interface NSDictionary<__covariant KeyType, __covariant ObjectType> : NSObject
#if !defined(__swift__)
@property (readonly) NSUInteger count;
- (nullable ObjectType)objectForKey:(KeyType)aKey;
- (NSEnumerator<KeyType> *)keyEnumerator;
- (instancetype)init NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithObjects:(const ObjectType _Nonnull [_Nullable])objects forKeys:(const KeyType _Nonnull [_Nullable])keys count:(NSUInteger)cnt NS_DESIGNATED_INITIALIZER;
@end

@interface NSDictionary<KeyType, ObjectType> (NSExtendedDictionary)
@property (readonly, copy) NSArray<KeyType> *allKeys;
@property (readonly, copy) NSArray<ObjectType> *allValues;
@property (readonly, copy) NSString *description;
- (BOOL)isEqualToDictionary:(NSDictionary<KeyType, ObjectType> *)otherDictionary;
- (NSEnumerator<ObjectType> *)objectEnumerator;
- (NSArray<ObjectType> *)objectsForKeys:(NSArray<KeyType> *)keys notFoundMarker:(ObjectType)marker;
- (nullable ObjectType)objectForKeyedSubscript:(KeyType)key;
- (nullable id)valueForKey:(NSString *)key;
- (void)enumerateKeysAndObjectsUsingBlock:(void (NS_NOESCAPE ^)(KeyType key, ObjectType obj, BOOL *stop))block;
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained _Nullable [_Nonnull])buffer
                                    count:(NSUInteger)len;
@end

@interface NSDictionary<KeyType, ObjectType> (NSDictionaryCreation)
+ (instancetype)dictionary;
+ (instancetype)dictionaryWithObject:(ObjectType)object forKey:(KeyType)key;
+ (instancetype)dictionaryWithObjects:(const ObjectType _Nonnull [_Nullable])objects forKeys:(const KeyType _Nonnull [_Nullable])keys count:(NSUInteger)cnt;
+ (instancetype)dictionaryWithObjectsAndKeys:(id)firstObject, ... NS_REQUIRES_NIL_TERMINATION;
+ (instancetype)dictionaryWithDictionary:(NSDictionary<KeyType, ObjectType> *)dict;
+ (instancetype)dictionaryWithObjects:(NSArray<ObjectType> *)objects forKeys:(NSArray<KeyType> *)keys;
- (instancetype)initWithDictionary:(NSDictionary<KeyType, ObjectType> *)otherDictionary;
#endif
@end

OF_SWIFT_CLASS("_TtC10Foundation19NSMutableDictionary", "Foundation")
@interface NSMutableDictionary<KeyType, ObjectType> : NSDictionary<KeyType, ObjectType>
#if !defined(__swift__)
- (void)removeObjectForKey:(KeyType)aKey;
- (void)setObject:(ObjectType)anObject forKey:(KeyType)aKey;
- (instancetype)init NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCapacity:(NSUInteger)numItems NS_DESIGNATED_INITIALIZER;
@end

@interface NSMutableDictionary<KeyType, ObjectType> (NSExtendedMutableDictionary)
- (void)addEntriesFromDictionary:(NSDictionary<KeyType, ObjectType> *)otherDictionary;
- (void)removeAllObjects;
- (void)removeObjectsForKeys:(NSArray<KeyType> *)keyArray;
- (void)setObject:(nullable ObjectType)obj forKeyedSubscript:(KeyType)key;
- (void)setValue:(nullable ObjectType)value forKey:(NSString *)key;
@end

@interface NSMutableDictionary<KeyType, ObjectType> (NSMutableDictionaryCreation)
+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems;
#endif
@end

NS_ASSUME_NONNULL_END

#endif
