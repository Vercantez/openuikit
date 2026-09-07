#import "TracksContextManager.h"
#import "TracksEvent.h"
#import "TracksEventService.h"
#import "TracksServiceRemote.h"
#import "TracksService.h"

static void TracksLogOnce(void) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{ NSLog(@"[OpenUIKit] AutomatticTracks fail-closed shim active; no events or network success is fabricated"); });
}

NSString *const TrackServiceWillSendQueuedEventsNotification = @"OpenUIKit.TrackServiceWillSendQueuedEvents";
NSString *const TrackServiceDidSendQueuedEventsNotification = @"OpenUIKit.TrackServiceDidSendQueuedEvents";

@implementation TracksContextManager
@end

@implementation TracksEvent {
    NSMutableDictionary *_customProperties;
    NSMutableDictionary *_deviceProperties;
    NSMutableDictionary *_userProperties;
}
- (instancetype)init {
    if ((self = [super init])) {
        _uuid = [NSUUID UUID];
        _date = [NSDate date];
        _customProperties = [NSMutableDictionary dictionary];
        _deviceProperties = [NSMutableDictionary dictionary];
        _userProperties = [NSMutableDictionary dictionary];
    }
    return self;
}
- (NSMutableDictionary *)customProperties { return _customProperties; }
- (NSMutableDictionary *)deviceProperties { return _deviceProperties; }
- (NSMutableDictionary *)userProperties { return _userProperties; }
- (BOOL)validateObject:(NSError **)error { (void)error; TracksLogOnce(); return NO; }
@end

@implementation TracksEventService
@end

@implementation TracksServiceRemote
@end

@implementation TracksService {
    NSMutableDictionary *_userProperties;
}
- (instancetype)initWithContextManager:(TracksContextManager *)contextManager {
    (void)contextManager;
    if ((self = [super init])) {
        _userProperties = [NSMutableDictionary dictionary];
        _remoteCallsEnabled = NO;
    }
    return self;
}
- (NSUInteger)queuedEventCount { return 0; }
- (NSMutableDictionary *)userProperties { return _userProperties; }
- (NSDictionary *)dictionaryForTracksEvent:(TracksEvent *)tracksEvent withParentCommonProperties:(NSDictionary *)parentCommonProperties {
    (void)tracksEvent; (void)parentCommonProperties; TracksLogOnce(); return nil;
}
- (void)switchToAuthenticatedUserWithUsername:(NSString *)username userID:(NSString *)userID skipAliasEventCreation:(BOOL)skipEvent { (void)username; (void)userID; (void)skipEvent; TracksLogOnce(); }
- (void)switchToAuthenticatedUserWithUsername:(NSString *)username userID:(NSString *)userID wpComToken:(NSString *)token skipAliasEventCreation:(BOOL)skipEvent { (void)username; (void)userID; (void)token; (void)skipEvent; TracksLogOnce(); }
- (void)switchToAuthenticatedUserWithUsername:(NSString *)username userID:(NSString *)userID anonymousID:(NSString *)anonymousID wpComToken:(NSString *)token skipAliasEventCreation:(BOOL)skipEvent { (void)username; (void)userID; (void)anonymousID; (void)token; (void)skipEvent; TracksLogOnce(); }
- (void)switchToAnonymousUserWithAnonymousID:(NSString *)anonymousID { (void)anonymousID; TracksLogOnce(); }
- (void)trackEventName:(NSString *)eventName { (void)eventName; TracksLogOnce(); }
- (BOOL)trackEventName:(NSString *)eventName withCustomProperties:(NSDictionary *)customProperties { (void)eventName; (void)customProperties; TracksLogOnce(); return NO; }
- (void)sendQueuedEvents { TracksLogOnce(); }
- (void)clearQueuedEvents { TracksLogOnce(); }
@end
