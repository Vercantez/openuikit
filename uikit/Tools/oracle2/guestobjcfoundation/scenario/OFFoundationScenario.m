// Foundation behaviour an Objective-C app (FMDB first) depends on, printed
// deterministically: no addresses, no hash values, no unordered iteration.
#import "OFScenario.h"
#include <stdio.h>

static void P(NSString *format, ...) NS_FORMAT_FUNCTION(1, 2);
static void P(NSString *format, ...) {
    va_list ap;
    va_start(ap, format);
    NSString *line = [[NSString alloc] initWithFormat:format arguments:ap];
    va_end(ap);
    printf("%s\n", line.UTF8String);
}

static NSString *B(BOOL value) { return value ? @"YES" : @"NO"; }

@interface NSString (OFScenarioCategory)
+ (NSString *)of_joinedCount:(NSUInteger)count;
- (NSString *)of_bracketed;
@end

@implementation NSString (OFScenarioCategory)
+ (NSString *)of_joinedCount:(NSUInteger)count {
    NSMutableString *s = [NSMutableString stringWithCapacity:count * 2];
    for (NSUInteger i = 0; i < count; i++) {
        [s appendString:i ? @",?" : @"?"];
    }
    return s;
}
- (NSString *)of_bracketed { return [NSString stringWithFormat:@"[%@]", self]; }
@end

static void strings(void) {
    NSString *constant = @"hello world";
    P(@"string constant length=%lu utf8=%s kind=%@", (unsigned long)constant.length, constant.UTF8String,
      B([constant isKindOfClass:[NSString class]]));
    NSString *nonASCII = @"héllo ☃ \U0001F600";
    P(@"string nonascii length=%lu char1=%04x char8=%04x", (unsigned long)nonASCII.length,
      [nonASCII characterAtIndex:1], [nonASCII characterAtIndex:8]);
    NSString *fromUTF8 = [NSString stringWithUTF8String:"caf\xc3\xa9 cr\xc3\xa8me"];
    P(@"string utf8 length=%lu equal=%@ upper=%@ lower=%@", (unsigned long)fromUTF8.length,
      B([fromUTF8 isEqualToString:@"café crème"]), fromUTF8.uppercaseString, @"MiXeD".lowercaseString);
    P(@"format ints %d %i %u %ld %lld %lu %llu %x %X %o %5d|%-5d|%05d", -42, 7, 42u, -1234567890L, -9223372036854775807LL,
      18446744073709551615UL, 12345678901234ULL, 255, 255, 8, 42, 42, 42);
    P(@"format floats %f %.2f %e %g %g %.3g %10.4f", 3.14159, 2.005, 12345.678, 0.0001, 1e20, 2.0 / 3.0, -1.5);
    P(@"format strings %@ %s %c %C %% %@ %@ %@", @"obj", "cstr", 'x', (unichar)0x00e9, [NSNull null], @42, @3.25);
    P(@"format objects %@ | %@", @[@1, @"two", @[@3]], @{@"k": @"v"});
    P(@"format pointer-free %5s|%-6s|%.2s", "ab", "cd", "efgh");
    P(@"substring from=%@ to=%@ range=%@", [constant substringFromIndex:6], [constant substringToIndex:5],
      [constant substringWithRange:NSMakeRange(3, 4)]);
    NSRange found = [constant rangeOfString:@"o w"];
    NSRange missing = [constant rangeOfString:@"xyz"];
    P(@"range found=%lu,%lu missing=%@ contains=%@", (unsigned long)found.location, (unsigned long)found.length,
      B(missing.location == NSNotFound), B([constant containsString:@"wor"]));
    P(@"prefix=%@ suffix=%@ compare=%ld %ld %ld caseInsensitive=%ld", B([constant hasPrefix:@"hell"]), B([constant hasSuffix:@"xld"]),
      (long)[@"a" compare:@"b"], (long)[@"b" compare:@"a"], (long)[@"a" compare:@"a"], (long)[@"ABC" caseInsensitiveCompare:@"abc"]);
    P(@"append=%@ replace=%@ appendFormat=%@", [@"foo" stringByAppendingString:@"bar"],
      [@"a-b-c" stringByReplacingOccurrencesOfString:@"-" withString:@"+"], [@"n=" stringByAppendingFormat:@"%d", 5]);
    NSArray *parts = [@"one two  three" componentsSeparatedByString:@" "];
    P(@"components count=%lu joined=%@", (unsigned long)parts.count, [parts componentsJoinedByString:@"|"]);
    P(@"values int=%d integer=%ld longlong=%lld double=%g float=%g bool=%@ %@", [@"  42abc" intValue], (long)[@"-17" integerValue],
      [@"9007199254740993" longLongValue], [@"3.5e2" doubleValue], [@"0.25" floatValue], B([@"YES" boolValue]), B([@"0" boolValue]));
    NSData *utf8 = [@"hé" dataUsingEncoding:NSUTF8StringEncoding];
    NSString *back = [[NSString alloc] initWithData:utf8 encoding:NSUTF8StringEncoding];
    P(@"data length=%lu back=%@ equalHash=%@", (unsigned long)utf8.length, back, B(@"abc".hash == [NSString stringWithFormat:@"a%@", @"bc"].hash));
    NSMutableString *m = [NSMutableString stringWithString:@"middle"];
    [m insertString:@"<" atIndex:0];
    [m appendString:@">"];
    [m appendFormat:@" %d", 3];
    [m replaceOccurrencesOfString:@"d" withString:@"D" options:0 range:NSMakeRange(0, m.length)];
    [m deleteCharactersInRange:NSMakeRange(1, 2)];
    P(@"mutable %@ length=%lu kind=%@ copyKind=%@", m, (unsigned long)m.length, B([m isKindOfClass:[NSMutableString class]]),
      B([[m copy] isKindOfClass:[NSString class]]));
    P(@"category %@ %@", [NSString of_joinedCount:3], [@"x" of_bracketed]);
    P(@"respondsToSelector length=%@ nope=%@", B([constant respondsToSelector:@selector(length)]),
      B([constant respondsToSelector:NSSelectorFromString(@"of_nope")]));
}

static void numbers(void) {
    NSNumber *i = [NSNumber numberWithInt:-7];
    NSNumber *d = [NSNumber numberWithDouble:2.5];
    NSNumber *b = [NSNumber numberWithBool:YES];
    NSNumber *ll = [NSNumber numberWithLongLong:1LL << 40];
    NSNumber *ull = [NSNumber numberWithUnsignedLongLong:18446744073709551615ULL];
    P(@"number int=%@ double=%@ bool=%@ longlong=%@ ull=%@", i, d, b, ll, ull);
    P(@"number values %d %g %lld %@ %lu %d", i.intValue, d.doubleValue, ll.longLongValue, B(b.boolValue), (unsigned long)d.unsignedLongValue, d.intValue);
    P(@"number objCType %s %s %s %s", i.objCType, d.objCType, ll.objCType, [NSNumber numberWithFloat:1.5f].objCType);
    P(@"number stringValue %@ %@ %@", i.stringValue, d.stringValue, [NSNumber numberWithDouble:0.1].stringValue);
    P(@"number compare %ld %ld equal=%@ %@", (long)[i compare:d], (long)[@2 compare:@2.0], B([@2 isEqualToNumber:@2.0]), B([@1 isEqual:@"1"]));
    P(@"number literals %@ %@ %@ %@ %@", @YES, @NO, @'A', @(3 + 4), @(1.0 / 4));
    P(@"number short=%@ ushort=%@ uint=%@ long=%@ ulong=%@ uinteger=%@ float=%@", [NSNumber numberWithShort:-3],
      [NSNumber numberWithUnsignedShort:65535], [NSNumber numberWithUnsignedInt:4000000000u], [NSNumber numberWithLong:-5],
      [NSNumber numberWithUnsignedLong:6], [NSNumber numberWithUnsignedInteger:7], [NSNumber numberWithFloat:0.1f]);
}

static void collections(void) {
    NSArray *a = @[@"b", @"a", @"c"];
    P(@"array count=%lu first=%@ last=%@ at1=%@ sub=%@ index=%lu contains=%@", (unsigned long)a.count, a.firstObject, a.lastObject,
      [a objectAtIndex:1], a[2], (unsigned long)[a indexOfObject:@"c"], B([a containsObject:@"a"]));
    P(@"array sorted=%@", [[a sortedArrayUsingSelector:@selector(compare:)] componentsJoinedByString:@","]);
    P(@"array adding=%lu equal=%@ description=%@", (unsigned long)[a arrayByAddingObject:@"d"].count,
      B([a isEqualToArray:@[@"b", @"a", @"c"]]), a);
    NSMutableArray *m = [NSMutableArray arrayWithCapacity:4];
    [m addObject:@1];
    [m addObjectsFromArray:@[@2, @3]];
    [m insertObject:@0 atIndex:0];
    [m removeObjectAtIndex:1];
    [m removeLastObject];
    m[1] = @"two";
    [m addObject:@"z"];
    [m removeObject:@"z"];
    NSMutableString *seen = [NSMutableString string];
    for (id o in m) [seen appendFormat:@"%@;", o];
    __block NSUInteger blocks = 0;
    [m enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) { blocks += idx + 1; }];
    P(@"mutable array %@ count=%lu fast=%@ blockSum=%lu", [m componentsJoinedByString:@","], (unsigned long)m.count, seen, (unsigned long)blocks);
    NSArray *copy = [m copy];
    [m removeAllObjects];
    P(@"array copy count=%lu after removeAll=%lu", (unsigned long)copy.count, (unsigned long)m.count);

    NSDictionary *d = @{@"name": @"feed", @"count": @3, @"nested": @{@"x": @[@1]}};
    NSArray *keys = [d.allKeys sortedArrayUsingSelector:@selector(compare:)];
    P(@"dict count=%lu keys=%@ name=%@ count=%@ missing=%@", (unsigned long)d.count, [keys componentsJoinedByString:@","],
      d[@"name"], [d objectForKey:@"count"], [d objectForKey:@"nope"] ? @"present" : @"nil");
    NSMutableDictionary *md = [NSMutableDictionary dictionaryWithCapacity:2];
    md[@"a"] = @1;
    [md setObject:@2 forKey:@"b"];
    [md setValue:@3 forKey:@"c"];
    [md removeObjectForKey:@"a"];
    NSMutableArray *pairs = [NSMutableArray array];
    [md enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) { [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, obj]]; }];
    [pairs sortUsingSelector:@selector(compare:)];
    NSMutableArray *fastKeys = [NSMutableArray array];
    for (NSString *k in md) [fastKeys addObject:k];
    [fastKeys sortUsingSelector:@selector(compare:)];
    P(@"mutable dict %@ fast=%@ equal=%@", [pairs componentsJoinedByString:@","], [fastKeys componentsJoinedByString:@","],
      B([md isEqualToDictionary:@{@"b": @2, @"c": @3}]));
    NSDictionary *single = [NSDictionary dictionaryWithObject:@"v" forKey:@"k"];
    id objs[] = {@"x", @"y"};
    id ks[] = {@"kx", @"ky"};
    NSDictionary *counted = [NSDictionary dictionaryWithObjects:objs forKeys:ks count:2];
    NSArray *looked = [counted objectsForKeys:@[@"ky", @"zz"] notFoundMarker:[NSNull null]];
    P(@"dict single=%@ counted=%lu looked=%@", single[@"k"], (unsigned long)counted.count, [looked componentsJoinedByString:@","]);
    P(@"dict description=%@", @{@"k": @"v"});

    NSSet *s = [NSSet setWithArray:@[@"x", @"y", @"x"]];
    NSMutableSet *ms = [NSMutableSet set];
    [ms addObject:@"p"];
    [ms addObject:@"q"];
    [ms addObject:@"p"];
    [ms removeObject:@"q"];
    P(@"set count=%lu contains=%@ member=%@ mutable=%lu any=%@ description=%@", (unsigned long)s.count, B([s containsObject:@"y"]),
      [s member:@"x"], (unsigned long)ms.count, ms.anyObject, ms);
    NSSet *passing = [s objectsPassingTest:^BOOL(id obj, BOOL *stop) { return [obj isEqual:@"y"]; }];
    P(@"set passing=%@", passing.anyObject);
}

static void errorsAndValues(void) {
    NSError *e = [NSError errorWithDomain:@"OFDomain" code:7 userInfo:@{NSLocalizedDescriptionKey: @"Seven happened"}];
    P(@"error domain=%@ code=%ld description=%@ localized=%@", e.domain, (long)e.code, e, e.localizedDescription);
    NSError *bare = [NSError errorWithDomain:@"OFDomain" code:3 userInfo:nil];
    P(@"error bare=%@ localized=%@ userInfo=%lu", bare, bare.localizedDescription, (unsigned long)bare.userInfo.count);
    P(@"error cocoa=%@ key=%@", NSCocoaErrorDomain, NSLocalizedDescriptionKey);
    unsigned char bytes[] = {0x61, 0x62, 0x00, 0xff};
    NSData *data = [NSData dataWithBytes:bytes length:4];
    NSMutableData *md = [NSMutableData dataWithData:data];
    [md appendBytes:"!" length:1];
    P(@"data length=%lu last=%02x equal=%@ mutable=%lu description=%@", (unsigned long)data.length, ((const unsigned char *)data.bytes)[3],
      B([data isEqualToData:[NSData dataWithBytes:bytes length:4]]), (unsigned long)md.length, data);
    NSDate *epoch = [NSDate dateWithTimeIntervalSince1970:0];
    NSDate *later = [epoch dateByAddingTimeInterval:86400.5];
    P(@"date since1970=%g sinceRef=%g later=%g compare=%ld description=%@", epoch.timeIntervalSince1970,
      epoch.timeIntervalSinceReferenceDate, [later timeIntervalSinceDate:epoch], (long)[epoch compare:later], later);
    P(@"date ref=%@ equal=%@", [NSDate dateWithTimeIntervalSinceReferenceDate:0], B([epoch isEqualToDate:[NSDate dateWithTimeIntervalSince1970:0]]));
    P(@"null same=%@ description=%@", B([NSNull null] == [NSNull null]), [NSNull null]);
    NSObject *target = [[NSObject alloc] init];
    NSValue *v = [NSValue valueWithNonretainedObject:target];
    P(@"value nonretained same=%@", B(v.nonretainedObjectValue == target));
    NSLock *lock = [[NSLock alloc] init];
    [lock lock];
    BOOL again = [lock tryLock];
    [lock unlock];
    BOOL after = [lock tryLock];
    [lock unlock];
    P(@"lock tryWhileHeld=%@ tryAfter=%@", B(again), B(after));
    P(@"runtime class=%@ selector=%@ lookup=%@ range=%@", NSStringFromClass([NSObject class]), NSStringFromSelector(@selector(compare:)),
      B(NSClassFromString(@"OFBridgeProbe") != Nil), NSStringFromRange(NSMakeRange(2, 3)));
}

void OFFoundationScenario(void) {
    strings();
    numbers();
    collections();
    errorsAndValues();
}

@implementation OFBridgeProbe
- (instancetype)initWithName:(NSString *)name {
    if ((self = [super init])) _name = [name copy];
    return self;
}
- (NSString *)greeting { return [NSString stringWithFormat:@"Hello, %@ (%lu)", self.name, (unsigned long)self.name.length]; }
- (NSUInteger)utf16LengthOf:(NSString *)string { return string.length; }
- (NSDictionary<NSString *, id> *)record {
    return @{@"title": @"Café", @"count": @12, @"ratio": @0.5, @"flag": @YES, @"tags": @[@"a", @"b"], @"none": [NSNull null]};
}
- (NSString *)describeDictionary:(NSDictionary<NSString *, id> *)dictionary {
    NSMutableArray *parts = [NSMutableArray array];
    for (NSString *key in [dictionary.allKeys sortedArrayUsingSelector:@selector(compare:)]) {
        id value = dictionary[key];
        NSString *kind = [value isKindOfClass:[NSString class]] ? @"string"
            : [value isKindOfClass:[NSNumber class]] ? @"number"
            : [value isKindOfClass:[NSArray class]] ? @"array"
            : [value isKindOfClass:[NSDictionary class]] ? @"dictionary" : @"other";
        [parts addObject:[NSString stringWithFormat:@"%@:%@=%@", key, kind, value]];
    }
    return [parts componentsJoinedByString:@" "];
}
- (NSInteger)sumOf:(NSArray<NSNumber *> *)numbers {
    NSInteger sum = 0;
    for (NSNumber *n in numbers) sum += n.integerValue;
    return sum;
}
- (NSArray<NSString *> *)words:(NSString *)sentence { return [sentence componentsSeparatedByString:@" "]; }
- (NSData *)dataFor:(NSString *)string { return [string dataUsingEncoding:NSUTF8StringEncoding]; }
- (NSSet<NSString *> *)uniqueWords:(NSArray<NSString *> *)words { return [NSSet setWithArray:words]; }
- (NSDate *)dateAtInterval:(NSTimeInterval)interval { return [NSDate dateWithTimeIntervalSince1970:interval]; }
- (BOOL)failWithCode:(NSInteger)code error:(NSError **)error {
    if (code == 0) return YES;
    if (error) *error = [NSError errorWithDomain:@"OFBridgeDomain" code:code userInfo:@{NSLocalizedDescriptionKey: @"bridge failure"}];
    return NO;
}
- (NSString *)transform:(NSString *)string with:(NSString *(^)(NSString *))block { return [block(string) of_bracketed]; }
@end
