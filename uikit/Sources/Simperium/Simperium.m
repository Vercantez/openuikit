#import "Simperium.h"

static NSError *SPUnavailableError(void) {
    return [NSError errorWithDomain:@"OpenUIKit.Simperium" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Simperium networking is unavailable in OpenUIKit"}];
}
static void SPLogOnce(void) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{ NSLog(@"[OpenUIKit] Simperium fail-closed shim active; no account or network success is fabricated"); });
}

@implementation SPUser
- (instancetype)initWithEmail:(NSString *)email token:(NSString *)token { if ((self = [super init])) { _email = [email copy]; _authToken = [token copy]; } return self; }
- (NSString *)hashedEmail { return nil; }
- (BOOL)authenticated { return NO; }
- (void)setCustomObject:(id)object forKey:(NSString *)key { (void)object; (void)key; SPLogOnce(); }
- (id)getCustomObjectForKey:(NSString *)key { (void)key; SPLogOnce(); return nil; }
+ (SPUser *)parseUserFromResponseString:(NSString *)string { (void)string; SPLogOnce(); return nil; }
@end

@implementation SPAuthenticator
- (instancetype)initWithDelegate:(id)delegate simperium:(Simperium *)simperium { (void)delegate; (void)simperium; return [super init]; }
- (BOOL)connected { return NO; }
- (BOOL)authenticateIfNecessary { SPLogOnce(); return NO; }
- (void)authenticateWithUsername:(NSString *)username token:(NSString *)token { (void)username; (void)token; SPLogOnce(); }
- (void)fail:(FailureBlockType)failure { SPLogOnce(); if (failure) failure(0, nil, SPUnavailableError()); }
- (void)authenticateWithUsername:(NSString *)u password:(NSString *)p success:(SuccessBlockType)s failure:(FailureBlockType)f { (void)u; (void)p; (void)s; [self fail:f]; }
- (void)validateWithUsername:(NSString *)u password:(NSString *)p success:(SuccessBlockType)s failure:(FailureBlockType)f { (void)u; (void)p; (void)s; [self fail:f]; }
- (void)signupWithUsername:(NSString *)u password:(NSString *)p success:(SuccessBlockType)s failure:(FailureBlockType)f { (void)u; (void)p; (void)s; [self fail:f]; }
- (void)reset { SPLogOnce(); }
- (void)cancel { SPLogOnce(); }
@end

@implementation SPBucket
- (instancetype)initWithName:(NSString *)name { if ((self = [super init])) { _name = [name copy]; _remoteName = [name copy]; } return self; }
- (id)objectForKey:(NSString *)key { (void)key; SPLogOnce(); return nil; }
- (NSArray *)allObjects { return @[]; }
- (id)insertNewObject { SPLogOnce(); return nil; }
- (id)insertNewObjectForKey:(NSString *)key { (void)key; SPLogOnce(); return nil; }
- (NSArray *)objectsForKeys:(NSSet *)keys { (void)keys; return @[]; }
- (NSArray *)objectsForPredicate:(NSPredicate *)predicate { (void)predicate; return @[]; }
- (void)requestVersions:(int)count key:(NSString *)key { (void)count; (void)key; SPLogOnce(); }
- (void)deleteObject:(id)object { (void)object; SPLogOnce(); }
- (void)deleteAllObjects { SPLogOnce(); }
- (NSInteger)numObjects { return 0; }
- (NSInteger)numObjectsForPredicate:(NSPredicate *)predicate { (void)predicate; return 0; }
- (void)statsWithCallback:(SPBucketStatsCallback)callback { if (callback) callback(self, 0, 0, 0); }
- (BOOL)hasLocalChangesForKey:(NSString *)key { (void)key; return NO; }
@end

@implementation SPManagedObject
- (void)loadMemberData:(NSDictionary *)dictionary { (void)dictionary; SPLogOnce(); }
- (NSDictionary *)dictionary { return @{}; }
- (NSString *)version { return nil; }
- (void)awakeFromLocalInsert { SPLogOnce(); }
- (void)awakeFromRemoteInsert { SPLogOnce(); }
@end

@implementation Simperium {
    NSManagedObjectModel *_model;
    NSManagedObjectContext *_context;
    NSPersistentStoreCoordinator *_coordinator;
    NSMutableDictionary *_buckets;
}
- (instancetype)initWithModel:(NSManagedObjectModel *)model context:(NSManagedObjectContext *)context coordinator:(NSPersistentStoreCoordinator *)coordinator { return [self initWithModel:model context:context coordinator:coordinator label:nil bucketOverrides:nil]; }
- (instancetype)initWithModel:(NSManagedObjectModel *)model context:(NSManagedObjectContext *)context coordinator:(NSPersistentStoreCoordinator *)coordinator label:(NSString *)label bucketOverrides:(NSDictionary *)overrides { (void)label; if ((self = [super init])) { _model=model; _context=context; _coordinator=coordinator; _buckets=[NSMutableDictionary dictionary]; _bucketOverrides=[overrides copy]; _authenticator=[[SPAuthenticator alloc] initWithDelegate:nil simperium:self]; } return self; }
- (void)authenticateWithAppID:(NSString *)identifier APIKey:(NSString *)key rootViewController:(UIViewController *)controller { (void)identifier; (void)key; (void)controller; SPLogOnce(); if ([_delegate respondsToSelector:@selector(simperium:didFailWithError:)]) [_delegate simperium:self didFailWithError:SPUnavailableError()]; }
- (void)authenticateWithAppID:(NSString *)identifier token:(NSString *)token { (void)identifier; (void)token; SPLogOnce(); }
- (BOOL)save { SPLogOnce(); return NO; }
- (SPBucket *)bucketForName:(NSString *)name { if (!name) return nil; SPBucket *bucket=_buckets[name]; if (!bucket) { bucket=[[SPBucket alloc] initWithName:name]; _buckets[name]=bucket; } return bucket; }
- (NSManagedObjectContext *)managedObjectContext { return _context; }
- (NSManagedObjectContext *)writerManagedObjectContext { return _context; }
- (NSManagedObjectModel *)managedObjectModel { return _model; }
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator { return _coordinator; }
- (BOOL)saveWithoutSyncing { SPLogOnce(); return NO; }
- (void)signOutAndRemoveLocalData:(BOOL)remove completion:(void (^)(void))completion { (void)remove; SPLogOnce(); if (completion) completion(); }
- (void)resetMetadata { SPLogOnce(); }
- (void)setAllBucketDelegates:(id)delegate { for (SPBucket *b in _buckets.allValues) b.delegate=delegate; }
- (void)setAllBucketPropertyMismatchFailsafeEnabled:(BOOL)enabled { for (SPBucket *b in _buckets.allValues) b.propertyMismatchFailsafeEnabled=enabled; }
- (BOOL)authenticateIfNecessary { SPLogOnce(); return NO; }
- (NSString *)appURL { return @""; } - (NSString *)appID { return @""; } - (NSString *)APIKey { return @""; } - (NSString *)clientID { return @""; }
- (BOOL)requiresConnection { return YES; } - (NSString *)networkStatus { return @"unavailable"; } - (NSDate *)networkLastSeenTime { return nil; }
- (NSUInteger)bytesSent { return 0; } - (NSUInteger)bytesReceived { return 0; }
@end
