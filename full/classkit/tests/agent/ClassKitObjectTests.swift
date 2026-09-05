import Foundation
import ClassKit

func testCLSObjectDates() {
    let context = CLSContext(type: .lesson, identifier: "dates", title: "Dates")
    classKitExpect(context.dateLastModified >= context.dateCreated, "created/modified")
    let created = context.dateCreated
    context.title = "Renamed"
    classKitExpect(context.dateLastModified >= created, "touched")
}

func testCLSObjectCoding() {
    let context = CLSContext(type: .quiz, identifier: "quiz-1", title: "Quiz")
    do {
        let data = try NSKeyedArchiver.archivedData(withRootObject: context, requiringSecureCoding: true)
        let decoded = try NSKeyedUnarchiver.unarchivedObject(ofClass: CLSContext.self, from: data)
        classKitExpect(decoded?.identifier == "quiz-1", "identifier")
        classKitExpect(decoded?.title == "Quiz", "title")
        classKitExpect(decoded?.type == .quiz, "type")
        classKitExpect(decoded?.dateCreated != nil, "dateCreated")
    } catch {
        fatalError("ClassKit test failed: coding \(error)")
    }
}
