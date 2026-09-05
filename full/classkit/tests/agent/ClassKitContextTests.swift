import Foundation
import ClassKit

func testContextInit() {
    let context = CLSContext(type: .lesson, identifier: "lesson-1", title: "Lesson 1")
    classKitExpect(context.type == .lesson, "type")
    classKitExpect(context.identifier == "lesson-1", "identifier")
    classKitExpect(context.title == "Lesson 1", "title")
    classKitExpect(context.identifierPath == ["lesson-1"], "path without parent")
    context.setType(.custom)
    classKitExpect(context.type == .custom, "setType")
    context.customTypeName = "unit"
    classKitExpect(context.customTypeName == "unit", "customTypeName")
    context.setType(.chapter)
    classKitExpect(context.type == .chapter, "setType chapter")
    classKitExpect(context.customTypeName == nil, "custom cleared")
}

func testContextHierarchy() {
    classKitResetStore()
    let root = CLSDataStore.shared.mainAppContext
    classKitExpect(root.identifierPath.isEmpty, "main path empty")
    classKitExpect(root.parent == nil, "main parent")
    let chapter = CLSContext(type: .chapter, identifier: "ch1", title: "Chapter 1")
    let section = CLSContext(type: .section, identifier: "sec1", title: "Section 1")
    root.addChildContext(chapter)
    chapter.addChildContext(section)
    classKitExpect(chapter.parent === root, "chapter parent")
    classKitExpect(section.parent === chapter, "section parent")
    classKitExpect(chapter.identifierPath == ["ch1"], "chapter path")
    classKitExpect(section.identifierPath == ["ch1", "sec1"], "section path")
    section.removeFromParent()
    classKitExpect(section.parent == nil, "removed")
    classKitExpect(section.identifierPath == ["sec1"], "orphan path")
}

func testContextActive() {
    classKitResetStore()
    let store = CLSDataStore.shared
    let first = CLSContext(type: .task, identifier: "a", title: "A")
    let second = CLSContext(type: .task, identifier: "b", title: "B")
    store.mainAppContext.addChildContext(first)
    store.mainAppContext.addChildContext(second)
    first.becomeActive()
    classKitExpect(first.isActive, "first active")
    classKitExpect(store.activeContext === first, "store active")
    second.becomeActive()
    classKitExpect(second.isActive, "second active")
    classKitExpect(first.isActive == false, "first resigned")
    classKitExpect(store.activeContext === second, "store switched")
    second.resignActive()
    classKitExpect(second.isActive == false, "resigned")
    classKitExpect(store.activeContext == nil, "store cleared")
}

func testContextNavigation() {
    let parent = CLSContext(type: .course, identifier: "course", title: "Course")
    let related = CLSContext(type: .document, identifier: "doc", title: "Doc")
    classKitExpect(parent.navigationChildContexts.isEmpty, "empty")
    parent.addNavigationChildContext(related)
    classKitExpect(parent.navigationChildContexts.count == 1, "added")
    classKitExpect(related.parent == nil, "nav does not parent")
    parent.addNavigationChildContext(related)
    classKitExpect(parent.navigationChildContexts.count == 1, "deduped")
    parent.removeNavigationChildContext(related)
    classKitExpect(parent.navigationChildContexts.isEmpty, "removed")
}

func testContextCapabilities() {
    let context = CLSContext(type: .exercise, identifier: "ex", title: "Exercise")
    let duration = CLSProgressReportingCapability(kind: .duration, details: "minutes")
    let score = CLSProgressReportingCapability(kind: .score, details: nil)
    classKitExpect(context.progressReportingCapabilities.isEmpty, "empty")
    context.addProgressReportingCapabilities([duration, score])
    classKitExpect(context.progressReportingCapabilities.count == 2, "union")
    context.resetProgressReportingCapabilities()
    classKitExpect(context.progressReportingCapabilities.isEmpty, "reset")
}

func testContextProperties() {
    let context = CLSContext(type: .book, identifier: "book", title: "Book")
    context.isAssignable = true
    context.displayOrder = 4
    context.summary = "Summary"
    context.topic = .literacyAndWriting
    context.suggestedAge = NSRange(location: 8, length: 4)
    context.suggestedCompletionTime = NSRange(location: 10, length: 20)
    context.universalLinkURL = URL(string: "https://example.test/book")
    classKitExpect(context.isAssignable, "assignable")
    classKitExpect(context.displayOrder == 4, "order")
    classKitExpect(context.summary == "Summary", "summary")
    classKitExpect(context.topic == .literacyAndWriting, "topic")
    classKitExpect(context.suggestedAge.location == 8, "age")
    classKitExpect(context.suggestedCompletionTime.length == 20, "time")
    classKitExpect(context.universalLinkURL?.host == "example.test", "url")
}

func testContextActivity() {
    classKitResetStore()
    let context = CLSDataStore.shared.mainAppContext
    classKitExpect(context.currentActivity == nil, "none")
    let first = context.createNewActivity()
    classKitExpect(context.currentActivity === first, "first")
    first.start()
    let second = context.createNewActivity()
    classKitExpect(first.isStarted == false, "previous stopped")
    classKitExpect(context.currentActivity === second, "second")
}

func testProgressReportingCapability() {
    let capability = CLSProgressReportingCapability(kind: .percent, details: "pages")
    classKitExpect(capability.kind == .percent, "kind")
    classKitExpect(capability.details == "pages", "details")
    let bare = CLSProgressReportingCapability(kind: .binary, details: nil)
    classKitExpect(bare.details == nil, "nil details")
}
