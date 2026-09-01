import Foundation
import FoundationModels

@Generable(description: "Tags payload")
struct MacroOracleTags {
    @Guide(description: "five hashtags", .count(5))
    let values: [String]
}

func consume(_ tags: MacroOracleTags) throws {
    _ = MacroOracleTags.generationSchema
    _ = tags.generatedContent
    _ = try MacroOracleTags(tags.generatedContent)
}
