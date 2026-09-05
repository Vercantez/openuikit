import Foundation
import CoreData
func testUnknownVersionNumberIsNotFabricated() {
    do {
            guard NSCoreDataVersionNumber == 0 else {
                throw ProbeFailure.message("NSCoreDataVersionNumber must stay unknown (0) until an Apple-oracle value exists")
            }
    } catch {
        fatalError("testUnknownVersionNumberIsNotFabricated failed: \(error)")
    }
}

