import Foundation
import Intents
import SwiftUI
import WidgetKit

final class WidgetNote: INObject, @unchecked Sendable {}

final class NoteWidgetIntent: INIntent, @unchecked Sendable {
    var note: WidgetNote?
}

struct Note {
    let title: String
    let body: String
    let url: URL
}

final class WidgetDefaults: @unchecked Sendable {
    static let shared = WidgetDefaults()
    var loggedIn = false
}

final class ResultsController {
    func firstNote() -> Note? { nil }
    func note(forSimperiumKey _: String) -> Note? { nil }
}

struct ExtensionCoreDataWrapper {
    func resultsController() -> ResultsController? { nil }
}

enum DemoContent {
    static let singleNoteTitle = "Note"
    static let singleNoteContent = "Content"
    static let demoURL = URL(string: "simplenote://note")!
}

enum WidgetConstants {
    static let rangeForSixEntries = 0..<6
}

extension Date {
    func increased(byHours hours: Int) -> Date? {
        addingTimeInterval(TimeInterval(hours * 3_600))
    }
}

struct NoteWidgetView: View {
    let entry: NoteWidgetEntry
    var body: some View { Text(entry.title) }
}

struct WidgetWarningView: View {
    enum Warning {
        case loggedOut
        case noteMissing
    }

    let warning: Warning
    var body: some View { Text(String(describing: warning)) }
}

struct NewNoteWidget: Widget {
    var body: some WidgetConfiguration { NoteWidget().body }
}

struct ListWidget: Widget {
    var body: some WidgetConfiguration { NoteWidget().body }
}
