// NetNewsWire's RSDatabaseObjC (FMDB plus the RS categories), unmodified, on
// an in-memory SQLite database. Deterministic output only.
#import "OFScenario.h"
#import "RSDatabaseObjC.h"
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

static NSString *Kind(id value) {
    if (value == nil) return @"nil";
    if ([value isKindOfClass:[NSNull class]]) return @"null";
    if ([value isKindOfClass:[NSString class]]) return @"string";
    if ([value isKindOfClass:[NSNumber class]]) return @"number";
    if ([value isKindOfClass:[NSData class]]) return @"data";
    return @"other";
}

void OFFMDBScenario(void) {
    FMDatabase *db = [FMDatabase databaseWithPath:nil];
    P(@"fmdb open=%@ path=%@ threadsafe=%@ version=%@", B([db open]), db.databasePath ?: @"(memory)",
      B([FMDatabase isSQLiteThreadSafe]), [FMDatabase sqliteLibVersion]);
    BOOL created = [db executeStatements:@"CREATE TABLE articles (articleID TEXT PRIMARY KEY, feedID TEXT, title TEXT, "
                                         @"read INTEGER, score REAL, body BLOB, published DOUBLE);"
                                         @"CREATE INDEX articles_feed ON articles (feedID);"];
    P(@"fmdb statements=%@ tableExists=%@ columnExists=%@ missingColumn=%@", B(created), B([db tableExists:@"articles"]),
      B([db columnExists:@"title" inTableWithName:@"articles"]), B([db columnExists:@"nope" inTableWithName:@"articles"]));

    NSDate *date = [NSDate dateWithTimeIntervalSince1970:1700000000];
    NSData *body = [@"<p>bödy</p>" dataUsingEncoding:NSUTF8StringEncoding];
    BOOL inserted = [db executeUpdate:@"INSERT INTO articles VALUES (?, ?, ?, ?, ?, ?, ?)", @"a1", @"f1", @"Café news", @0, @1.5, body, date];
    P(@"fmdb insert=%@ rowid=%lld changes=%d", B(inserted), [db lastInsertRowId], [db changes]);
    [db beginTransaction];
    for (int i = 2; i <= 4; i++) {
        [db executeUpdate:@"INSERT INTO articles (articleID, feedID, title, read, score) VALUES (?, ?, ?, ?, ?)"
            withArgumentsInArray:@[[NSString stringWithFormat:@"a%d", i], i % 2 ? @"f1" : @"f2",
                                   [NSString stringWithFormat:@"Title %d", i], @(i % 2), @(i * 0.25)]];
    }
    P(@"fmdb inTransaction=%@ commit=%@ inTransaction=%@", B([db inTransaction]), B([db commit]), B([db inTransaction]));

    FMResultSet *rs = [db executeQuery:@"SELECT * FROM articles WHERE feedID = ? ORDER BY articleID", @"f1"];
    while ([rs next]) {
        P(@"fmdb row %@ title=%@ read=%d bool=%@ score=%g long=%ld data=%lu date=%g nullBody=%@ published=%@ columnCount=%d",
          [rs stringForColumn:@"articleID"], [rs stringForColumn:@"title"], [rs intForColumn:@"read"], B([rs boolForColumn:@"read"]),
          [rs doubleForColumn:@"score"], [rs longForColumn:@"read"], (unsigned long)[rs dataForColumn:@"body"].length,
          [[rs dateForColumn:@"published"] timeIntervalSince1970], B([rs columnIsNull:@"body"]), Kind([rs objectForColumnName:@"published"]),
          [rs columnCount]);
    }
    [rs close];

    FMResultSet *dictRS = [db executeQuery:@"SELECT articleID, title, score, body FROM articles WHERE articleID = :id"
                   withParameterDictionary:@{@"id": @"a1"}];
    if ([dictRS next]) {
        NSDictionary *row = [dictRS resultDictionary];
        NSMutableArray *parts = [NSMutableArray array];
        for (NSString *key in [row.allKeys sortedArrayUsingSelector:@selector(compare:)])
            [parts addObject:[NSString stringWithFormat:@"%@:%@", key, Kind(row[key])]];
        P(@"fmdb resultDictionary %@ title=%@", [parts componentsJoinedByString:@","], row[@"title"]);
    }
    [dictRS close];

    P(@"fmdb placeholders=%@ keys=%@ pairs=%@", [NSString rs_SQLValueListWithPlaceholders:3],
      [NSString rs_SQLKeysListWithArray:@[@"a", @"b"]], [NSString rs_SQLKeyPlaceholderPairsWithKeys:@[@"x", @"y"]]);
    BOOL rsInsert = [db rs_insertRowWithDictionary:@{@"articleID": @"a9", @"feedID": @"f3", @"title": @"Inserted", @"read": @1}
                                        insertType:RSDatabaseInsertOrReplace tableName:@"articles"];
    BOOL rsUpdate = [db rs_updateRowsWithDictionary:@{@"read": @1} whereKey:@"articleID" inValues:@[@"a2", @"a4"] tableName:@"articles"];
    FMResultSet *ids = [db rs_selectColumnWithKey:@"articleID" tableName:@"articles"];
    NSArray *allIDs = [[ids rs_arrayForSingleColumnResultSet] sortedArrayUsingSelector:@selector(compare:)];
    FMResultSet *feeds = [db executeQuery:@"SELECT feedID FROM articles"];
    NSSet *feedSet = [feeds rs_setForSingleColumnResultSet];
    P(@"fmdb rsInsert=%@ rsUpdate=%@ ids=%@ feeds=%lu exists=%@ empty=%@", B(rsInsert), B(rsUpdate), [allIDs componentsJoinedByString:@","],
      (unsigned long)feedSet.count, B([db rs_rowExistsWithValue:@"a9" forKey:@"articleID" tableName:@"articles"]),
      B([db rs_tableIsEmpty:@"articles"]));
    FMResultSet *readRows = [db rs_selectRowsWhereKey:@"read" equalsValue:@1 tableName:@"articles"];
    NSMutableArray *readIDs = [NSMutableArray array];
    while ([readRows next]) [readIDs addObject:[readRows stringForColumn:@"articleID"]];
    [readIDs sortUsingSelector:@selector(compare:)];
    BOOL deleted = [db rs_deleteRowsWhereKey:@"feedID" inValues:@[@"f2"] tableName:@"articles"];
    FMResultSet *count = [db executeQuery:@"SELECT count(*) FROM articles"];
    [count next];
    P(@"fmdb read=%@ deleted=%@ changes=%d remaining=%d", [readIDs componentsJoinedByString:@","], B(deleted), [db changes], [count intForColumnIndex:0]);
    [count close];

    BOOL bad = [db executeUpdate:@"INSERT INTO nowhere VALUES (1)"];
    P(@"fmdb bad=%@ hadError=%@ code=%d message=%@ lastError=%@ %ld", B(bad), B([db hadError]), [db lastErrorCode],
      [db lastErrorMessage], [db lastError].domain, (long)[db lastError].code);
    P(@"fmdb close=%@", B([db close]));
}
