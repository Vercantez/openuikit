import Foundation
import MusicKit

func testSuggestionsResponse() {
    let json = """
    {"results":{"suggestions":[{"displayTerm":"Fleet Foxes","searchTerm":"fleet foxes"}],"topResults":{"data":[{"id":"1","type":"songs","attributes":{"name":"S","artistName":"A"}}]}}}
    """
    let decoded = try! JSONDecoder().decode(MusicCatalogSearchSuggestionsResponse.self, from: Data(json.utf8))
    precondition(decoded.suggestions.count == 1)
    let suggestion = decoded.suggestions[0]
    let suggestionID: MusicCatalogSearchSuggestionsResponse.Suggestion.ID = suggestion.id
    precondition(suggestionID == "fleet foxes")
    precondition(suggestion.displayTerm == "Fleet Foxes")
    precondition(suggestion.searchTerm == "fleet foxes")
    precondition(suggestion.description == "Fleet Foxes")
    precondition(suggestion.debugDescription == "Fleet Foxes")
    precondition(suggestion == suggestion)
    var hasher = Hasher()
    suggestion.hash(into: &hasher)
    _ = suggestion.hashValue
    let encodedSuggestion = try! JSONEncoder().encode(suggestion)
    let roundSuggestion = try! JSONDecoder().decode(
        MusicCatalogSearchSuggestionsResponse.Suggestion.self,
        from: encodedSuggestion
    )
    precondition(roundSuggestion.searchTerm == "fleet foxes")
    precondition(decoded.topResults.count == 1)
    let alias: MusicCatalogSearchSuggestionsResponse.TopResult = decoded.topResults[0]
    precondition(alias.title == "S")
    precondition(decoded.description.contains("1"))
    precondition(decoded.debugDescription == decoded.description)
    precondition(decoded == decoded)
    decoded.hash(into: &hasher)
    _ = decoded.hashValue
    let encoded = try! JSONEncoder().encode(decoded)
    let roundTrip = try! JSONDecoder().decode(MusicCatalogSearchSuggestionsResponse.self, from: encoded)
    precondition(roundTrip.suggestions[0].displayTerm == "Fleet Foxes")
    let constructed = MusicCatalogSearchSuggestionsResponse.Suggestion(displayTerm: "A", searchTerm: "a")
    precondition(constructed.id == "a")
}
