#ifndef OPENUIKIT_SIMPERIUM_H
#define OPENUIKIT_SIMPERIUM_H

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@class Simperium, SPBucket, SPAuthenticator, SPUser;
@class UIViewController;

typedef NS_ENUM(NSInteger, SPSimperiumErrors) {
    SPSimperiumErrorsMissingAppID,
    SPSimperiumErrorsMissingAPIKey,
    SPSimperiumErrorsMissingToken,
    SPSimperiumErrorsMissingWindow,
    SPSimperiumErrorsInvalidToken,
};

@protocol SimperiumDelegate <NSObject>
@optional
- (void)simperium:(Simperium *)simperium didFailWithError:(NSError *)error;
- (void)simperiumDidLogin:(Simperium *)simperium;
- (void)simperiumDidLogout:(Simperium *)simperium;
- (void)simperiumDidCancelLogin:(Simperium *)simperium;
- (void)simperiumDidCreateAccount:(Simperium *)simperium;
@end

typedef NS_ENUM(NSUInteger, SPBucketChangeType) {
    SPBucketChangeTypeInsert = 1, SPBucketChangeTypeDelete, SPBucketChangeTypeMove,
    SPBucketChangeTypeUpdate, SPBucketChangeTypeAcknowledge,
};
@protocol SPBucketDelegate <NSObject>
@optional
- (void)bucket:(SPBucket *)bucket didChangeObjectForKey:(NSString *)key forChangeType:(SPBucketChangeType)changeType memberNames:(NSArray *)memberNames;
- (void)bucket:(SPBucket *)bucket willChangeObjectsForKeys:(NSSet *)keys;
- (void)bucketWillStartIndexing:(SPBucket *)bucket;
- (void)bucketDidFinishIndexing:(SPBucket *)bucket;
- (void)bucket:(SPBucket *)bucket didReceiveObjectForKey:(NSString *)key version:(NSString *)version data:(NSDictionary *)data;
- (void)bucketDidAcknowledgeDelete:(SPBucket *)bucket;
- (void)bucket:(SPBucket *)bucket didFailWithError:(NSError *)error;
@end

@interface SPUser : NSObject
@property (copy, nonatomic) NSString *email;
@property (copy, nonatomic) NSString *authToken;
- (instancetype)initWithEmail:(NSString *)username token:(NSString *)token;
- (NSString *)hashedEmail;
- (BOOL)authenticated;
- (void)setCustomObject:(id)object forKey:(NSString *)key;
- (nullable id)getCustomObjectForKey:(NSString *)key;
+ (SPUser *)parseUserFromResponseString:(NSString *)string;
@end

typedef void (^SuccessBlockType)(void);
typedef void (^FailureBlockType)(NSInteger responseCode, NSString * _Nullable responseString, NSError * _Nullable error);
@protocol SPAuthenticatorDelegate <NSObject>
@optional
- (void)authenticationDidSucceedForUsername:(NSString *)username token:(NSString *)token;
- (void)authenticationDidCreateAccount;
- (void)authenticationDidFail;
- (void)authenticationDidCancel;
@end
@interface SPAuthenticator : NSObject
@property (nonatomic, copy) NSString *authURL;
@property (nonatomic, copy) NSDictionary *customHTTPHeaders;
@property (nonatomic, copy) NSString *providerString;
@property (nonatomic, readonly) BOOL connected;
- (instancetype)initWithDelegate:(nullable id<SPAuthenticatorDelegate>)authDelegate simperium:(Simperium *)simperium;
- (BOOL)authenticateIfNecessary;
- (void)authenticateWithUsername:(NSString *)username token:(NSString *)token;
- (void)authenticateWithUsername:(NSString *)username password:(NSString *)password success:(SuccessBlockType)success failure:(FailureBlockType)failure;
- (void)validateWithUsername:(NSString *)username password:(NSString *)password success:(SuccessBlockType)success failure:(FailureBlockType)failure;
- (void)signupWithUsername:(NSString *)username password:(NSString *)password success:(SuccessBlockType)success failure:(FailureBlockType)failure;
- (void)reset;
- (void)cancel;
@end

typedef void (^SPBucketStatsCallback)(SPBucket *bucket, NSUInteger localPendingChanges, NSUInteger localEnqueuedChanges, NSUInteger localEnqueuedDeletions);
@interface SPBucket : NSObject
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *remoteName;
@property (nonatomic, weak) id<SPBucketDelegate> delegate;
@property (nonatomic) BOOL notifyWhileIndexing;
@property (nonatomic) BOOL propertyMismatchFailsafeEnabled;
- (nullable id)objectForKey:(NSString *)simperiumKey;
- (NSArray *)allObjects;
- (nullable id)insertNewObject;
- (nullable id)insertNewObjectForKey:(NSString *)simperiumKey;
- (NSArray *)objectsForKeys:(NSSet *)keys;
- (NSArray *)objectsForPredicate:(NSPredicate *)predicate;
- (void)requestVersions:(int)numVersions key:(NSString *)simperiumKey;
- (void)deleteObject:(id)object;
- (void)deleteAllObjects;
- (NSInteger)numObjects;
- (NSInteger)numObjectsForPredicate:(NSPredicate *)predicate;
- (void)statsWithCallback:(SPBucketStatsCallback)callback;
- (BOOL)hasLocalChangesForKey:(NSString *)simperiumKey;
@end

@interface SPManagedObject : NSManagedObject
@property (strong, nonatomic) id ghost;
@property (weak, nonatomic) SPBucket *bucket;
@property (copy, nonatomic) NSString *ghostData;
@property (copy, nonatomic) NSString *simperiumKey;
@property (nonatomic) BOOL updateWaiting;
- (void)loadMemberData:(NSDictionary *)dictionary;
- (NSDictionary *)dictionary;
- (NSString *)version;
- (void)awakeFromLocalInsert;
- (void)awakeFromRemoteInsert;
@end

@interface Simperium : NSObject
- (instancetype)initWithModel:(NSManagedObjectModel *)model context:(NSManagedObjectContext *)context coordinator:(NSPersistentStoreCoordinator *)coordinator;
- (instancetype)initWithModel:(NSManagedObjectModel *)model context:(NSManagedObjectContext *)context coordinator:(NSPersistentStoreCoordinator *)coordinator label:(NSString *)label bucketOverrides:(nullable NSDictionary *)bucketOverrides;
- (void)authenticateWithAppID:(NSString *)identifier APIKey:(NSString *)key rootViewController:(UIViewController *)controller;
- (void)authenticateWithAppID:(NSString *)identifier token:(NSString *)token;
- (BOOL)save;
- (nullable SPBucket *)bucketForName:(NSString *)name;
- (NSManagedObjectContext *)managedObjectContext;
- (NSManagedObjectContext *)writerManagedObjectContext;
- (NSManagedObjectModel *)managedObjectModel;
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
- (BOOL)saveWithoutSyncing;
- (void)signOutAndRemoveLocalData:(BOOL)remove completion:(nullable void (^)(void))completion;
- (void)resetMetadata;
- (void)setAllBucketDelegates:(nullable id<SPBucketDelegate>)delegate;
- (void)setAllBucketPropertyMismatchFailsafeEnabled:(BOOL)enabled;
- (BOOL)authenticateIfNecessary;
@property (nonatomic, weak) id<SimperiumDelegate> delegate;
@property (nonatomic) BOOL authenticationOptional;
@property (nonatomic) BOOL authenticationShouldBeEmbeddedInNavigationController;
@property (nonatomic) BOOL certificatePinningEnabled;
@property (nonatomic) BOOL verboseLoggingEnabled;
@property (nonatomic) BOOL remoteLoggingEnabled;
@property (nonatomic) BOOL networkEnabled;
@property (nonatomic) BOOL presentsLoginByDefault;
@property (nonatomic) BOOL delaysNewObjectsInitialization;
@property (nonatomic) BOOL validatesObjects;
@property (nonatomic, strong, nullable) SPUser *user;
@property (nonatomic, readonly, copy) NSString *appURL;
@property (nonatomic, copy) NSString *rootURL;
@property (nonatomic, readonly, copy) NSString *appID;
@property (nonatomic, readonly, copy) NSString *APIKey;
@property (nonatomic, readonly, copy) NSString *clientID;
@property (nonatomic, readonly, nullable, copy) NSDictionary *bucketOverrides;
@property (nonatomic, strong) SPAuthenticator *authenticator;
@property (nonatomic, readonly) BOOL requiresConnection;
@property (nonatomic, readonly, copy) NSString *networkStatus;
@property (nonatomic, readonly, strong) NSDate *networkLastSeenTime;
@property (nonatomic, readonly) NSUInteger bytesSent;
@property (nonatomic, readonly) NSUInteger bytesReceived;
@property (nonatomic, weak) UIViewController *rootViewController;
@property (nonatomic, weak) Class authenticationViewControllerClass;
@end

NS_ASSUME_NONNULL_END
#endif
