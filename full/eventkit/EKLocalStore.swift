import Foundation

/// On-disk local calendar/reminder store for the EventKit port.
///
/// Directory (documented): Application Support `/OpenUIKit/EventKit/store.json`.
/// Override with `OPENUIKIT_EVENTKIT_STORE_DIRECTORY` or
/// `EKEventStore.useIsolatedStoreDirectory(_:)` (tests). This is not the host
/// Calendar.app / EventKit database and never talks to CalDAV/Exchange/iCloud.
enum EKLocalStoreRoot {
    static let lock = NSLock()
    nonisolated(unsafe) static var overrideDirectory: URL?
    nonisolated(unsafe) static var denyAccess = false
    nonisolated(unsafe) static var snapshot: EKLocalSnapshot?
    nonisolated(unsafe) static var fileDate: Date?

    static var directory: URL {
        if let overrideDirectory {
            return overrideDirectory
        }
        if let raw = getenv("OPENUIKIT_EVENTKIT_STORE_DIRECTORY") {
            return URL(fileURLWithPath: String(cString: raw), isDirectory: true)
        }
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory
        return base
            .appendingPathComponent("OpenUIKit", isDirectory: true)
            .appendingPathComponent("EventKit", isDirectory: true)
    }

    static var fileURL: URL {
        directory.appendingPathComponent("store.json", isDirectory: false)
    }

    static func useIsolatedDirectory(_ url: URL) {
        lock.lock()
        overrideDirectory = url
        snapshot = nil
        fileDate = nil
        denyAccess = false
        lock.unlock()
    }

    static func resetCache() {
        lock.lock()
        snapshot = nil
        fileDate = nil
        lock.unlock()
    }
}

struct EKLocalSnapshot {
    var eventStoreIdentifier: String
    var eventAuthorization: EKAuthorizationStatus
    var reminderAuthorization: EKAuthorizationStatus
    var sources: [EKSourceRecord]
    var calendars: [EKCalendarRecord]
    var events: [EKEventRecord]
    var reminders: [EKReminderRecord]
    var exceptionDates: [String: [Double]]

    static func empty() -> EKLocalSnapshot {
        EKLocalSnapshot(
            eventStoreIdentifier: UUID().uuidString,
            eventAuthorization: .notDetermined,
            reminderAuthorization: .notDetermined,
            sources: [],
            calendars: [],
            events: [],
            reminders: [],
            exceptionDates: [:]
        )
    }
}

struct EKSourceRecord {
    var identifier: String
    var sourceType: Int
    var title: String
    var isDelegate: Bool
}

struct EKCalendarRecord {
    var identifier: String
    var title: String
    var sourceIdentifier: String
    var type: Int
    var allowedEntityTypes: UInt
    var allowsContentModifications: Bool
    var isImmutable: Bool
    var isSubscribed: Bool
    var supportedEventAvailabilities: UInt
    var colorRed: Double
    var colorGreen: Double
    var colorBlue: Double
    var colorAlpha: Double
}

struct EKAlarmRecord {
    var relativeOffset: Double
    var absoluteDate: Double?
    var proximity: Int
    var locationTitle: String?
    var locationRadius: Double
    var latitude: Double?
    var longitude: Double?
}

struct EKRecurrenceRecord {
    var frequency: Int
    var interval: Int
    var daysOfTheWeek: [[Int]]
    var daysOfTheMonth: [Int]
    var monthsOfTheYear: [Int]
    var weeksOfTheYear: [Int]
    var daysOfTheYear: [Int]
    var setPositions: [Int]
    var endDate: Double?
    var occurrenceCount: Int
    var firstDayOfTheWeek: Int
}

struct EKEventRecord {
    var calendarItemIdentifier: String
    var calendarItemExternalIdentifier: String
    var eventIdentifier: String
    var calendarIdentifier: String
    var title: String?
    var location: String?
    var notes: String?
    var url: String?
    var timeZone: String?
    var start: Double
    var end: Double
    var isAllDay: Bool
    var availability: Int
    var status: Int
    var isDetached: Bool
    var occurrenceDate: Double?
    var birthdayContactIdentifier: String?
    var birthdayPersonID: Int
    var creationDate: Double?
    var lastModifiedDate: Double?
    var alarms: [EKAlarmRecord]
    var recurrence: [EKRecurrenceRecord]
    var structuredTitle: String?
    var structuredRadius: Double
    var structuredLatitude: Double?
    var structuredLongitude: Double?
}

struct EKReminderRecord {
    var calendarItemIdentifier: String
    var calendarItemExternalIdentifier: String
    var calendarIdentifier: String
    var title: String?
    var notes: String?
    var url: String?
    var timeZone: String?
    var priority: Int
    var completionDate: Double?
    var startComponents: [String: Any]
    var dueComponents: [String: Any]
    var creationDate: Double?
    var lastModifiedDate: Double?
    var alarms: [EKAlarmRecord]
    var recurrence: [EKRecurrenceRecord]
}

enum EKLocalStoreIO {
    static let localSourceIdentifier = "local"
    static let eventCalendarIdentifier = "local-calendar-events"
    static let reminderCalendarIdentifier = "local-calendar-reminders"
    static let defaultRed = 0.0
    static let defaultGreen = 0.478
    static let defaultBlue = 1.0
    static let defaultAlpha = 1.0

    static func loadLocked() -> EKLocalSnapshot {
        if let snapshot = EKLocalStoreRoot.snapshot {
            return snapshot
        }
        let url = EKLocalStoreRoot.fileURL
        guard let data = try? Data(contentsOf: url),
              let object = try? JSONSerialization.jsonObject(with: data),
              let dict = object as? [String: Any]
        else {
            let empty = EKLocalSnapshot.empty()
            EKLocalStoreRoot.snapshot = empty
            return empty
        }
        let snapshot = decode(dict)
        EKLocalStoreRoot.snapshot = snapshot
        EKLocalStoreRoot.fileDate = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))
            .flatMap(\.contentModificationDate)
        return snapshot
    }

    static func saveLocked(_ snapshot: EKLocalSnapshot) throws {
        let url = EKLocalStoreRoot.fileURL
        try FileManager.default.createDirectory(
            at: EKLocalStoreRoot.directory,
            withIntermediateDirectories: true
        )
        let data = try JSONSerialization.data(
            withJSONObject: encode(snapshot),
            options: [.prettyPrinted]
        )
        let tmp = url.appendingPathExtension("tmp")
        try data.write(to: tmp, options: [.atomic])
        if FileManager.default.fileExists(atPath: url.path) {
            _ = try FileManager.default.replaceItemAt(url, withItemAt: tmp)
        } else {
            try FileManager.default.moveItem(at: tmp, to: url)
        }
        EKLocalStoreRoot.snapshot = snapshot
        EKLocalStoreRoot.fileDate = Date()
    }

    static func fileChanged() -> Bool {
        let url = EKLocalStoreRoot.fileURL
        let date = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))
            .flatMap(\.contentModificationDate)
        if date == nil && EKLocalStoreRoot.fileDate == nil {
            return false
        }
        return date != EKLocalStoreRoot.fileDate
    }

    static func ensureLocalCalendars(
        _ snapshot: inout EKLocalSnapshot,
        events: Bool,
        reminders: Bool
    ) {
        if !snapshot.sources.contains(where: { $0.identifier == localSourceIdentifier }) {
            snapshot.sources.append(
                EKSourceRecord(
                    identifier: localSourceIdentifier,
                    sourceType: EKSourceType.local.rawValue,
                    title: "On This Device",
                    isDelegate: false
                )
            )
        }
        if events && !snapshot.calendars.contains(where: { $0.identifier == eventCalendarIdentifier }) {
            snapshot.calendars.append(
                defaultCalendar(
                    identifier: eventCalendarIdentifier,
                    title: "Calendar",
                    allowed: EKEntityMask.event.rawValue,
                    availabilities: EKCalendarEventAvailabilityMask.busy.union(.free).rawValue
                )
            )
        }
        if reminders && !snapshot.calendars.contains(where: { $0.identifier == reminderCalendarIdentifier }) {
            snapshot.calendars.append(
                defaultCalendar(
                    identifier: reminderCalendarIdentifier,
                    title: "Reminders",
                    allowed: EKEntityMask.reminder.rawValue,
                    availabilities: 0
                )
            )
        }
    }

    private static func defaultCalendar(
        identifier: String,
        title: String,
        allowed: UInt,
        availabilities: UInt
    ) -> EKCalendarRecord {
        EKCalendarRecord(
            identifier: identifier,
            title: title,
            sourceIdentifier: localSourceIdentifier,
            type: EKCalendarType.local.rawValue,
            allowedEntityTypes: allowed,
            allowsContentModifications: true,
            isImmutable: false,
            isSubscribed: false,
            supportedEventAvailabilities: availabilities,
            colorRed: defaultRed,
            colorGreen: defaultGreen,
            colorBlue: defaultBlue,
            colorAlpha: defaultAlpha
        )
    }

    static func encode(_ snapshot: EKLocalSnapshot) -> [String: Any] {
        [
            "schema": 1,
            "eventStoreIdentifier": snapshot.eventStoreIdentifier,
            "authorization": [
                "event": snapshot.eventAuthorization.rawValue,
                "reminder": snapshot.reminderAuthorization.rawValue,
            ],
            "sources": snapshot.sources.map { source -> [String: Any] in
                [
                    "identifier": source.identifier,
                    "sourceType": source.sourceType,
                    "title": source.title,
                    "isDelegate": source.isDelegate,
                ]
            },
            "calendars": snapshot.calendars.map(encodeCalendar),
            "events": snapshot.events.map(encodeEvent),
            "reminders": snapshot.reminders.map(encodeReminder),
            "exceptionDates": snapshot.exceptionDates.mapValues { $0 as Any },
        ]
    }

    static func decode(_ dict: [String: Any]) -> EKLocalSnapshot {
        let auth = dict["authorization"] as? [String: Any] ?? [:]
        return EKLocalSnapshot(
            eventStoreIdentifier: string(dict["eventStoreIdentifier"]) ?? UUID().uuidString,
            eventAuthorization: EKAuthorizationStatus(rawValue: int(auth["event"]) ?? 0) ?? .notDetermined,
            reminderAuthorization: EKAuthorizationStatus(rawValue: int(auth["reminder"]) ?? 0) ?? .notDetermined,
            sources: array(dict["sources"]).compactMap(decodeSource),
            calendars: array(dict["calendars"]).compactMap(decodeCalendar),
            events: array(dict["events"]).compactMap(decodeEvent),
            reminders: array(dict["reminders"]).compactMap(decodeReminder),
            exceptionDates: decodeExceptions(dict["exceptionDates"])
        )
    }

    private static func encodeCalendar(_ calendar: EKCalendarRecord) -> [String: Any] {
        [
            "identifier": calendar.identifier,
            "title": calendar.title,
            "sourceIdentifier": calendar.sourceIdentifier,
            "type": calendar.type,
            "allowedEntityTypes": calendar.allowedEntityTypes,
            "allowsContentModifications": calendar.allowsContentModifications,
            "isImmutable": calendar.isImmutable,
            "isSubscribed": calendar.isSubscribed,
            "supportedEventAvailabilities": calendar.supportedEventAvailabilities,
            "colorRed": calendar.colorRed,
            "colorGreen": calendar.colorGreen,
            "colorBlue": calendar.colorBlue,
            "colorAlpha": calendar.colorAlpha,
        ]
    }

    private static func encodeAlarm(_ alarm: EKAlarmRecord) -> [String: Any] {
        var dict: [String: Any] = [
            "relativeOffset": alarm.relativeOffset,
            "proximity": alarm.proximity,
            "locationRadius": alarm.locationRadius,
        ]
        if let absoluteDate = alarm.absoluteDate {
            dict["absoluteDate"] = absoluteDate
        }
        if let title = alarm.locationTitle {
            dict["locationTitle"] = title
        }
        if let latitude = alarm.latitude {
            dict["latitude"] = latitude
        }
        if let longitude = alarm.longitude {
            dict["longitude"] = longitude
        }
        return dict
    }

    private static func encodeRecurrence(_ rule: EKRecurrenceRecord) -> [String: Any] {
        var dict: [String: Any] = [
            "frequency": rule.frequency,
            "interval": rule.interval,
            "daysOfTheWeek": rule.daysOfTheWeek,
            "daysOfTheMonth": rule.daysOfTheMonth,
            "monthsOfTheYear": rule.monthsOfTheYear,
            "weeksOfTheYear": rule.weeksOfTheYear,
            "daysOfTheYear": rule.daysOfTheYear,
            "setPositions": rule.setPositions,
            "occurrenceCount": rule.occurrenceCount,
            "firstDayOfTheWeek": rule.firstDayOfTheWeek,
        ]
        if let endDate = rule.endDate {
            dict["endDate"] = endDate
        }
        return dict
    }

    private static func encodeEvent(_ event: EKEventRecord) -> [String: Any] {
        var dict: [String: Any] = [
            "calendarItemIdentifier": event.calendarItemIdentifier,
            "calendarItemExternalIdentifier": event.calendarItemExternalIdentifier,
            "eventIdentifier": event.eventIdentifier,
            "calendarIdentifier": event.calendarIdentifier,
            "start": event.start,
            "end": event.end,
            "isAllDay": event.isAllDay,
            "availability": event.availability,
            "status": event.status,
            "isDetached": event.isDetached,
            "birthdayPersonID": event.birthdayPersonID,
            "alarms": event.alarms.map(encodeAlarm),
            "recurrence": event.recurrence.map(encodeRecurrence),
            "structuredRadius": event.structuredRadius,
        ]
        put(&dict, "title", event.title)
        put(&dict, "location", event.location)
        put(&dict, "notes", event.notes)
        put(&dict, "url", event.url)
        put(&dict, "timeZone", event.timeZone)
        put(&dict, "birthdayContactIdentifier", event.birthdayContactIdentifier)
        put(&dict, "structuredTitle", event.structuredTitle)
        if let occurrenceDate = event.occurrenceDate {
            dict["occurrenceDate"] = occurrenceDate
        }
        if let creationDate = event.creationDate {
            dict["creationDate"] = creationDate
        }
        if let lastModifiedDate = event.lastModifiedDate {
            dict["lastModifiedDate"] = lastModifiedDate
        }
        if let latitude = event.structuredLatitude {
            dict["structuredLatitude"] = latitude
        }
        if let longitude = event.structuredLongitude {
            dict["structuredLongitude"] = longitude
        }
        return dict
    }

    private static func encodeReminder(_ reminder: EKReminderRecord) -> [String: Any] {
        var dict: [String: Any] = [
            "calendarItemIdentifier": reminder.calendarItemIdentifier,
            "calendarItemExternalIdentifier": reminder.calendarItemExternalIdentifier,
            "calendarIdentifier": reminder.calendarIdentifier,
            "priority": reminder.priority,
            "alarms": reminder.alarms.map(encodeAlarm),
            "recurrence": reminder.recurrence.map(encodeRecurrence),
            "startComponents": reminder.startComponents,
            "dueComponents": reminder.dueComponents,
        ]
        put(&dict, "title", reminder.title)
        put(&dict, "notes", reminder.notes)
        put(&dict, "url", reminder.url)
        put(&dict, "timeZone", reminder.timeZone)
        if let completionDate = reminder.completionDate {
            dict["completionDate"] = completionDate
        }
        if let creationDate = reminder.creationDate {
            dict["creationDate"] = creationDate
        }
        if let lastModifiedDate = reminder.lastModifiedDate {
            dict["lastModifiedDate"] = lastModifiedDate
        }
        return dict
    }

    private static func decodeSource(_ any: Any) -> EKSourceRecord? {
        guard let dict = any as? [String: Any] else { return nil }
        return EKSourceRecord(
            identifier: string(dict["identifier"]) ?? UUID().uuidString,
            sourceType: int(dict["sourceType"]) ?? 0,
            title: string(dict["title"]) ?? "",
            isDelegate: bool(dict["isDelegate"])
        )
    }

    private static func decodeCalendar(_ any: Any) -> EKCalendarRecord? {
        guard let dict = any as? [String: Any] else { return nil }
        return EKCalendarRecord(
            identifier: string(dict["identifier"]) ?? UUID().uuidString,
            title: string(dict["title"]) ?? "",
            sourceIdentifier: string(dict["sourceIdentifier"]) ?? localSourceIdentifier,
            type: int(dict["type"]) ?? 0,
            allowedEntityTypes: uint(dict["allowedEntityTypes"]) ?? EKEntityMask.event.rawValue,
            allowsContentModifications: bool(dict["allowsContentModifications"], default: true),
            isImmutable: bool(dict["isImmutable"]),
            isSubscribed: bool(dict["isSubscribed"]),
            supportedEventAvailabilities: uint(dict["supportedEventAvailabilities"]) ?? 0,
            colorRed: double(dict["colorRed"]) ?? defaultRed,
            colorGreen: double(dict["colorGreen"]) ?? defaultGreen,
            colorBlue: double(dict["colorBlue"]) ?? defaultBlue,
            colorAlpha: double(dict["colorAlpha"]) ?? defaultAlpha
        )
    }

    private static func decodeAlarm(_ any: Any) -> EKAlarmRecord? {
        guard let dict = any as? [String: Any] else { return nil }
        return EKAlarmRecord(
            relativeOffset: double(dict["relativeOffset"]) ?? 0,
            absoluteDate: double(dict["absoluteDate"]),
            proximity: int(dict["proximity"]) ?? 0,
            locationTitle: string(dict["locationTitle"]),
            locationRadius: double(dict["locationRadius"]) ?? 0,
            latitude: double(dict["latitude"]),
            longitude: double(dict["longitude"])
        )
    }

    private static func decodeRecurrence(_ any: Any) -> EKRecurrenceRecord? {
        guard let dict = any as? [String: Any] else { return nil }
        return EKRecurrenceRecord(
            frequency: int(dict["frequency"]) ?? 0,
            interval: max(1, int(dict["interval"]) ?? 1),
            daysOfTheWeek: intPairs(dict["daysOfTheWeek"]),
            daysOfTheMonth: intList(dict["daysOfTheMonth"]),
            monthsOfTheYear: intList(dict["monthsOfTheYear"]),
            weeksOfTheYear: intList(dict["weeksOfTheYear"]),
            daysOfTheYear: intList(dict["daysOfTheYear"]),
            setPositions: intList(dict["setPositions"]),
            endDate: double(dict["endDate"]),
            occurrenceCount: max(0, int(dict["occurrenceCount"]) ?? 0),
            firstDayOfTheWeek: int(dict["firstDayOfTheWeek"]) ?? 0
        )
    }

    private static func decodeEvent(_ any: Any) -> EKEventRecord? {
        guard let dict = any as? [String: Any] else { return nil }
        return EKEventRecord(
            calendarItemIdentifier: string(dict["calendarItemIdentifier"]) ?? UUID().uuidString,
            calendarItemExternalIdentifier: string(dict["calendarItemExternalIdentifier"]) ?? "",
            eventIdentifier: string(dict["eventIdentifier"]) ?? UUID().uuidString,
            calendarIdentifier: string(dict["calendarIdentifier"]) ?? "",
            title: string(dict["title"]),
            location: string(dict["location"]),
            notes: string(dict["notes"]),
            url: string(dict["url"]),
            timeZone: string(dict["timeZone"]),
            start: double(dict["start"]) ?? 0,
            end: double(dict["end"]) ?? 0,
            isAllDay: bool(dict["isAllDay"]),
            availability: int(dict["availability"]) ?? 0,
            status: int(dict["status"]) ?? 0,
            isDetached: bool(dict["isDetached"]),
            occurrenceDate: double(dict["occurrenceDate"]),
            birthdayContactIdentifier: string(dict["birthdayContactIdentifier"]),
            birthdayPersonID: int(dict["birthdayPersonID"]) ?? -1,
            creationDate: double(dict["creationDate"]),
            lastModifiedDate: double(dict["lastModifiedDate"]),
            alarms: array(dict["alarms"]).compactMap(decodeAlarm),
            recurrence: array(dict["recurrence"]).compactMap(decodeRecurrence),
            structuredTitle: string(dict["structuredTitle"]),
            structuredRadius: double(dict["structuredRadius"]) ?? 0,
            structuredLatitude: double(dict["structuredLatitude"]),
            structuredLongitude: double(dict["structuredLongitude"])
        )
    }

    private static func decodeReminder(_ any: Any) -> EKReminderRecord? {
        guard let dict = any as? [String: Any] else { return nil }
        return EKReminderRecord(
            calendarItemIdentifier: string(dict["calendarItemIdentifier"]) ?? UUID().uuidString,
            calendarItemExternalIdentifier: string(dict["calendarItemExternalIdentifier"]) ?? "",
            calendarIdentifier: string(dict["calendarIdentifier"]) ?? "",
            title: string(dict["title"]),
            notes: string(dict["notes"]),
            url: string(dict["url"]),
            timeZone: string(dict["timeZone"]),
            priority: int(dict["priority"]) ?? 0,
            completionDate: double(dict["completionDate"]),
            startComponents: dict["startComponents"] as? [String: Any] ?? [:],
            dueComponents: dict["dueComponents"] as? [String: Any] ?? [:],
            creationDate: double(dict["creationDate"]),
            lastModifiedDate: double(dict["lastModifiedDate"]),
            alarms: array(dict["alarms"]).compactMap(decodeAlarm),
            recurrence: array(dict["recurrence"]).compactMap(decodeRecurrence)
        )
    }

    private static func decodeExceptions(_ any: Any?) -> [String: [Double]] {
        guard let dict = any as? [String: Any] else { return [:] }
        var result: [String: [Double]] = [:]
        for (key, value) in dict {
            result[key] = array(value).compactMap { double($0) }
        }
        return result
    }

    private static func put(_ dict: inout [String: Any], _ key: String, _ value: String?) {
        if let value {
            dict[key] = value
        }
    }

    static func string(_ any: Any?) -> String? {
        any as? String
    }

    static func int(_ any: Any?) -> Int? {
        if let value = any as? Int { return value }
        if let value = any as? NSNumber { return value.intValue }
        return nil
    }

    static func uint(_ any: Any?) -> UInt? {
        if let value = any as? UInt { return value }
        if let value = any as? Int { return UInt(value) }
        if let value = any as? NSNumber { return value.uintValue }
        return nil
    }

    static func double(_ any: Any?) -> Double? {
        if let value = any as? Double { return value }
        if let value = any as? Int { return Double(value) }
        if let value = any as? NSNumber { return value.doubleValue }
        return nil
    }

    static func bool(_ any: Any?, default fallback: Bool = false) -> Bool {
        if let value = any as? Bool { return value }
        if let value = any as? NSNumber { return value.boolValue }
        return fallback
    }

    static func array(_ any: Any?) -> [Any] {
        any as? [Any] ?? []
    }

    private static func intList(_ any: Any?) -> [Int] {
        array(any).compactMap { int($0) }
    }

    private static func intPairs(_ any: Any?) -> [[Int]] {
        array(any).compactMap { item in
            if let pair = item as? [Int], pair.count >= 2 {
                return Array(pair.prefix(2))
            }
            if let pair = item as? [Any], pair.count >= 2,
               let first = int(pair[0]), let second = int(pair[1])
            {
                return [first, second]
            }
            return nil
        }
    }
}

func EKEncodeDateComponents(_ components: DateComponents?) -> [String: Any] {
    guard let components else { return [:] }
    var dict: [String: Any] = [:]
    if let year = components.year { dict["year"] = year }
    if let month = components.month { dict["month"] = month }
    if let day = components.day { dict["day"] = day }
    if let hour = components.hour { dict["hour"] = hour }
    if let minute = components.minute { dict["minute"] = minute }
    if let second = components.second { dict["second"] = second }
    if let nanosecond = components.nanosecond { dict["nanosecond"] = nanosecond }
    if let weekday = components.weekday { dict["weekday"] = weekday }
    if let weekOfMonth = components.weekOfMonth { dict["weekOfMonth"] = weekOfMonth }
    if let timeZone = components.timeZone {
        dict["timeZone"] = timeZone.identifier
    }
    if let calendar = components.calendar {
        dict["calendar"] = EKCalendarIdentifierName(calendar.identifier)
    }
    return dict
}

func EKCalendarIdentifierName(_ identifier: Calendar.Identifier) -> String {
    if identifier == .iso8601 { return "iso8601" }
    return "gregorian"
}

func EKDecodeDateComponents(_ dict: [String: Any]) -> DateComponents? {
    if dict.isEmpty { return nil }
    var components = DateComponents()
    if let year = EKLocalStoreIO.int(dict["year"]) { components.year = year }
    if let month = EKLocalStoreIO.int(dict["month"]) { components.month = month }
    if let day = EKLocalStoreIO.int(dict["day"]) { components.day = day }
    if let hour = EKLocalStoreIO.int(dict["hour"]) { components.hour = hour }
    if let minute = EKLocalStoreIO.int(dict["minute"]) { components.minute = minute }
    if let second = EKLocalStoreIO.int(dict["second"]) { components.second = second }
    if let nanosecond = EKLocalStoreIO.int(dict["nanosecond"]) { components.nanosecond = nanosecond }
    if let weekday = EKLocalStoreIO.int(dict["weekday"]) { components.weekday = weekday }
    if let weekOfMonth = EKLocalStoreIO.int(dict["weekOfMonth"]) { components.weekOfMonth = weekOfMonth }
    if let identifier = EKLocalStoreIO.string(dict["timeZone"]) {
        components.timeZone = TimeZone(identifier: identifier)
    }
    if let identifier = EKLocalStoreIO.string(dict["calendar"]) {
        if identifier == "iso8601" {
            components.calendar = Calendar(identifier: .iso8601)
        } else {
            components.calendar = Calendar(identifier: .gregorian)
        }
    }
    return components
}
