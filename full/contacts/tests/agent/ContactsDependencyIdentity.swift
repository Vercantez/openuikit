// ContactsDependencyIdentity.swift
// Future EC2 guest-Foundation identity probe. The isolated host gate does
// not compile this file (it only links tests/agent/ContactsRuntime.swift).
//
// Required EC2 recipe (no local Docker):
//   1. Build the actual guest Foundation module and dylib first
//      (`full/foundation` → libFoundation.dylib and matching .swiftmodule).
//   2. Build Contacts with those -I/-L paths so the framework binds the
//      guest Foundation identities, not a guessed local substitute.
//   3. Link a client that `import`s both Contacts and Foundation, passing
//      real guest values through public Contacts APIs (descriptors,
//      predicates, notifications, Data, Date, coding).
//   4. Run with LD_LIBRARY_PATH covering both dylibs.
//   5. Confirm this exact marker and that libContacts.dylib is loaded.
//
// Unique marker: CONTACTS_DEPENDENCY_IDENTITY_OK

import Contacts
import Foundation

private func expect(_ condition: Bool, _ message: String) {
    if !condition {
        fputs("CONTACTS_DEPENDENCY_IDENTITY_FAIL \(message)\n", stderr)
        exit(1)
    }
}

private func keys(_ names: String...) -> [any CNKeyDescriptor] {
    names.map { $0 as NSString }
}

@main
struct ContactsDependencyIdentity {
    static func main() {
        // Descriptor identity: public keys are Foundation NSString values
        // that satisfy CNKeyDescriptor via NSObjectProtocol + NSCopying +
        // NSSecureCoding. Callers pass `as NSString`; Contacts does not
        // invent a same-named local descriptor type.
        let given: NSString = CNContactGivenNameKey as NSString
        let boxed: Any = given
        expect(boxed is any CNKeyDescriptor, "NSString is CNKeyDescriptor")
        expect(boxed is NSCopying, "descriptor is NSCopying")
        expect(boxed is NSSecureCoding, "descriptor is NSSecureCoding")
        expect(boxed is NSObjectProtocol, "descriptor is NSObjectProtocol")
        expect(type(of: given) == NSString.self, "descriptor type is NSString")

        let copied = given.copy() as? NSString
        expect(copied == given, "NSCopying round-trip")

        // Notification name identity stays Foundation's NSNotification.Name.
        let noteName: NSNotification.Name = .CNContactStoreDidChange
        expect(noteName.rawValue == "CNContactStoreDidChangeNotification", "notification name")
        expect(type(of: noteName) == NSNotification.Name.self, "NSNotification.Name identity")

        let store = CNContactStore()
        let grantedSem = DispatchSemaphore(value: 0)
        var granted = false
        store.requestAccess(for: .contacts) { ok, _ in
            granted = ok
            grantedSem.signal()
        }
        if grantedSem.wait(timeout: .now() + 5) == .timedOut {
            expect(false, "requestAccess callback")
        }
        expect(granted, "in-memory access")
        let container = store.defaultContainerIdentifier()

        // Date / DateComponents identity through birthday APIs.
        var contact = CNMutableContact()
        contact.givenName = "Identity"
        contact.familyName = "Probe"
        var birthday = DateComponents()
        birthday.year = 1991
        birthday.month = 4
        birthday.day = 12
        contact.birthday = birthday
        expect(type(of: birthday) == DateComponents.self, "DateComponents identity")
        if let storedBirthday = contact.birthday {
            expect(type(of: storedBirthday) == DateComponents.self, "stored DateComponents")
            expect(storedBirthday.year == 1991, "birthday year")
        } else {
            expect(false, "birthday present")
        }

        let now = Date()
        expect(type(of: now) == Date.self, "Date identity")
        let anniversary = NSDateComponents()
        anniversary.year = 2016
        anniversary.month = 6
        anniversary.day = 1
        contact.dates = [CNLabeledValue(label: CNLabelDateAnniversary, value: anniversary)]
        expect(contact.dates.first?.value is NSDateComponents, "dates carry NSDateComponents")

        // Data identity through imageData.
        let payload = Data("identity-bytes".utf8)
        expect(type(of: payload) == Data.self, "Data identity")
        contact.imageData = payload
        expect(contact.imageData == payload, "imageData round-trip")
        expect(contact.imageData.map { type(of: $0) == Data.self } == true, "imageData is Data")

        let request = CNSaveRequest()
        request.add(contact, toContainerWithIdentifier: container)
        try! store.execute(request)

        let fetched = try! store.unifiedContacts(
            matching: CNContact.predicateForContacts(matchingName: "Identity"),
            keysToFetch: keys(CNContactGivenNameKey, CNContactImageDataKey, CNContactBirthdayKey)
        )
        expect(fetched.count == 1, "fetched identity contact")
        expect(fetched[0].imageData == payload, "fetched imageData")
        expect(fetched[0].birthday?.year == 1991, "fetched birthday")

        // Predicate identity: store predicates are NSPredicate subclasses,
        // and custom Foundation NSPredicate values are accepted.
        let namePredicate = CNContact.predicateForContacts(matchingName: "Identity")
        expect(namePredicate is NSPredicate, "name predicate is NSPredicate")
        expect(type(of: namePredicate).isSubclass(of: NSPredicate.self), "predicate subclass")

        let custom = NSPredicate { _, _ in true }
        expect(custom is NSPredicate, "custom NSPredicate identity")
        expect(type(of: custom).isSubclass(of: NSPredicate.self), "custom predicate subclass")
        let customMatches = try! store.unifiedContacts(
            matching: custom,
            keysToFetch: keys(CNContactGivenNameKey)
        )
        expect(customMatches.contains(where: { $0.givenName == "Identity" }), "custom predicate fetch")

        // Coding APIs: CNPhoneNumber uses NSCoder / NSSecureCoding.
        let phone = CNPhoneNumber(stringValue: "+15551212")
        expect(CNPhoneNumber.supportsSecureCoding, "CNPhoneNumber supportsSecureCoding")
        let archived = try! NSKeyedArchiver.archivedData(withRootObject: phone, requiringSecureCoding: true)
        expect(type(of: archived) == Data.self, "archived Data identity")
        let restored = try! NSKeyedUnarchiver.unarchivedObject(ofClass: CNPhoneNumber.self, from: archived)
        expect(restored?.stringValue == "+15551212", "phone coding round-trip")

        expect(CNPostalAddress.supportsSecureCoding, "CNPostalAddress supportsSecureCoding")
        expect(CNLabeledValue<CNPhoneNumber>.supportsSecureCoding, "CNLabeledValue supportsSecureCoding")
        _ = CNLabeledValue(label: CNLabelHome, value: phone)

        // Confirm libContacts.dylib is mapped into this process.
        let maps = try! String(contentsOfFile: "/proc/self/maps", encoding: .utf8)
        expect(maps.contains("libContacts.dylib"), "libContacts.dylib is loaded")

        fputs("CONTACTS_DEPENDENCY_IDENTITY_OK\n", stderr)
    }
}
