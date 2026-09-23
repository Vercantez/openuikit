// The Objective-C side of the guest ObjC-Foundation probe. The same sources
// run on the iOS 26.1 simulator against Apple's Foundation (run.sh) and under
// machorun against the guest's (uikit/Tools/guestprobes/GuestObjCFoundationProbe).
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Prints the Foundation transcript: strings, numbers, collections, errors,
/// data, dates, locks and the runtime helpers FMDB relies on.
void OFFoundationScenario(void);

/// Prints the FMDB transcript: NetNewsWire's unmodified RSDatabaseObjC on an
/// in-memory SQLite database.
void OFFMDBScenario(void);

/// Objective-C objects handed to Swift and back (main.swift).
@interface OFBridgeProbe : NSObject
@property (nonatomic, copy) NSString *name;
- (instancetype)initWithName:(NSString *)name;
- (NSString *)greeting;
- (NSUInteger)utf16LengthOf:(NSString *)string;
- (NSDictionary<NSString *, id> *)record;
- (NSString *)describeDictionary:(NSDictionary<NSString *, id> *)dictionary;
- (NSInteger)sumOf:(NSArray<NSNumber *> *)numbers;
- (NSArray<NSString *> *)words:(NSString *)sentence;
- (nullable NSData *)dataFor:(NSString *)string;
- (NSSet<NSString *> *)uniqueWords:(NSArray<NSString *> *)words;
- (NSDate *)dateAtInterval:(NSTimeInterval)interval;
- (BOOL)failWithCode:(NSInteger)code error:(NSError **)error;
- (NSString *)transform:(NSString *)string with:(NSString *(^)(NSString *))block;
@end

NS_ASSUME_NONNULL_END
