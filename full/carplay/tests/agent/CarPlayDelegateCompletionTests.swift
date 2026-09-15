import Foundation
@_spi(OpenUIKitHost) import CarPlay

/// Recorders for the Apple-required completion-handler delegate callbacks
/// (`CPListTemplate.h`, `CPSearchTemplate.h` in the Xcode 26.1 SDK). Each
/// invoked callback must call its completion handler exactly once.
final class CompletionListSelectionRecorder: NSObject, CPListTemplateDelegate {
    var selected: [CPListItem] = []
    var completions = 0
    func listTemplate(_ listTemplate: CPListTemplate, didSelect item: CPListItem, completionHandler: @escaping () -> Void) {
        selected.append(item)
        completionHandler()
        completions += 1
    }
}

final class CompletionSearchRecorder: NSObject, CPSearchTemplateDelegate {
    var selected: [CPListItem] = []
    var queries: [String] = []
    var selectionCompletions = 0
    var queryCompletions = 0
    func searchTemplate(_ searchTemplate: CPSearchTemplate, selectedResult item: CPListItem, completionHandler: @escaping () -> Void) {
        selected.append(item)
        completionHandler()
        selectionCompletions += 1
    }
    func searchTemplate(_ searchTemplate: CPSearchTemplate, updatedSearchText searchText: String, completionHandler: @escaping ([CPListItem]) -> Void) {
        queries.append(searchText)
        completionHandler([CPListItem(text: searchText, detailText: "hit")])
        queryCompletions += 1
    }
    func searchTemplateSearchButtonPressed(_ searchTemplate: CPSearchTemplate) {}
}

func testListTemplateDidSelectCompletion() {
    carPlayOnMain {
        let list = CPListTemplate(title: "Home", sections: [])
        let item = CPListItem(text: "Albums", detailText: "On this device")
        let recorder = CompletionListSelectionRecorder()
        list.delegate = recorder
        var completed = false
        recorder.listTemplate(list, didSelect: item) {
            completed = true
        }
        precondition(completed)
        precondition(recorder.selected.count == 1)
        precondition(recorder.selected.first === item)
        precondition(recorder.completions == 1)
        _ = list.delegate
    }
}

func testSearchTemplateSelectedResultCompletion() {
    carPlayOnMain {
        let search = CPSearchTemplate()
        let item = CPListItem(text: "Result", detailText: nil)
        let recorder = CompletionSearchRecorder()
        search.delegate = recorder
        var completed = false
        recorder.searchTemplate(search, selectedResult: item) {
            completed = true
        }
        precondition(completed)
        precondition(recorder.selected.count == 1)
        precondition(recorder.selected.first === item)
        precondition(recorder.selectionCompletions == 1)
        _ = search.delegate
    }
}

func testSearchTemplateUpdatedSearchTextCompletion() {
    carPlayOnMain {
        let search = CPSearchTemplate()
        let recorder = CompletionSearchRecorder()
        search.delegate = recorder
        var results: [CPListItem] = []
        var completed = false
        recorder.searchTemplate(search, updatedSearchText: "abc") { items in
            results = items
            completed = true
        }
        precondition(completed)
        precondition(recorder.queries == ["abc"])
        precondition(results.count == 1)
        precondition(results.first?.text == "abc")
        precondition(recorder.queryCompletions == 1)
        _ = search.delegate
    }
}
