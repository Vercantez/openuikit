import Foundation
@_spi(OpenUIKitHost) import FamilyControls

func testSelectionEmptyInit() {
    let selection = FamilyActivitySelection()
    precondition(selection.includeEntireCategory == false)
    precondition(selection.applicationTokens.isEmpty)
    precondition(selection.categoryTokens.isEmpty)
    precondition(selection.webDomainTokens.isEmpty)
    precondition(type(of: selection) == FamilyActivitySelection.self)
}

func testSelectionIncludeEntireCategory() {
    let included = FamilyActivitySelection(includeEntireCategory: true)
    precondition(included.includeEntireCategory == true)
    precondition(included.applicationTokens.isEmpty)
    let excluded = FamilyActivitySelection(includeEntireCategory: false)
    precondition(excluded.includeEntireCategory == false)
    precondition(FamilyActivitySelection().includeEntireCategory == false)
}

func testSelectionTokens() {
    var selection = FamilyActivitySelection()
    let app = ApplicationToken()
    let category = ActivityCategoryToken()
    let domain = WebDomainToken()
    selection.applicationTokens.insert(app)
    selection.categoryTokens.insert(category)
    selection.webDomainTokens.insert(domain)
    precondition(selection.applicationTokens.count == 1)
    precondition(selection.categoryTokens.count == 1)
    precondition(selection.webDomainTokens.count == 1)
    precondition(selection.applicationTokens.contains(app))
    precondition(selection.categoryTokens.contains(category))
    precondition(selection.webDomainTokens.contains(domain))
    selection.applicationTokens.remove(app)
    precondition(selection.applicationTokens.isEmpty)
}

func testSelectionResolvedSetsEmpty() {
    var selection = FamilyActivitySelection(includeEntireCategory: true)
    selection.applicationTokens.insert(ApplicationToken())
    selection.categoryTokens.insert(ActivityCategoryToken())
    selection.webDomainTokens.insert(WebDomainToken())
    precondition(selection.applications.isEmpty)
    precondition(selection.categories.isEmpty)
    precondition(selection.webDomains.isEmpty)
    _ = Application()
    _ = ActivityCategory()
    _ = WebDomain(domain: "example.com")
}

func testSelectionEquality() {
    let a = FamilyActivitySelection()
    let b = FamilyActivitySelection(includeEntireCategory: false)
    precondition(a == b)
    let c = FamilyActivitySelection(includeEntireCategory: true)
    precondition(a != c)
    var d = FamilyActivitySelection()
    d.applicationTokens.insert(ApplicationToken())
    precondition(a != d)
    precondition(FamilyActivitySelection() == FamilyActivitySelection())
}

func testSelectionInequality() {
    precondition(FamilyActivitySelection() != FamilyActivitySelection(includeEntireCategory: true))
    precondition(!(FamilyActivitySelection() != FamilyActivitySelection()))
}

func testSelectionCodable() {
    var selection = FamilyActivitySelection(includeEntireCategory: true)
    let token = ApplicationToken()
    selection.applicationTokens.insert(token)
    let data = try! JSONEncoder().encode(selection)
    let decoded = try! JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    precondition(decoded.includeEntireCategory == true)
    precondition(decoded.applicationTokens == selection.applicationTokens)
    precondition(decoded.categoryTokens.isEmpty)
    precondition(decoded.webDomainTokens.isEmpty)
    precondition(decoded == selection)
}
