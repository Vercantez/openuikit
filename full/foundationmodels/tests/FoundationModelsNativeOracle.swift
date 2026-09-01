import Foundation
import FoundationModels

@available(macOS 26.0, *)
@Generable(description: "IceCubes hashtags")
struct NativeTags {
    @Guide(
        description: "The value of the hashtags, must be camelCased and prefixed with a # symbol.",
        .count(5)
    )
    let values: [String]
}

@main
struct FoundationModelsNativeOracle {
    static func main() throws {
        if #available(macOS 26.0, *) {
            let tags = NativeTags(values: ["#swiftOnLinux", "#iceCubes"])
            let content = tags.generatedContent
            let decoded = try NativeTags(content)
            let propertyCount = NativeTags.generationSchema.debugDescription
                .contains("values") ? 1 : 0
            print("json=\(content.jsonString)")
            print("roundtrip=\(decoded.values.joined(separator: ","))")
            print("schema-values=\(propertyCount)")
            print("options=\(GenerationOptions(temperature: 0.3).temperature ?? -1)")
        }
    }
}
