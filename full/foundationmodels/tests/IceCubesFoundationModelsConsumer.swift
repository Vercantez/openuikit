import FoundationModels

// This is the exact FoundationModels declaration shape consumed by untouched
// IceCubes StatusKit at commit b2db3033fbf67a97b54d25d6dac2df8a029b26b1.
@Generable
struct Tags {
    @Guide(
        description: "The value of the hashtags, must be camelCased and prefixed with a # symbol.",
        .count(5)
    )
    let values: [String]
}

@main
struct IceCubesFoundationModelsConsumer {
    static func main() async throws {
        let model = SystemLanguageModel.default
        guard !model.isAvailable,
              model.availability == .unavailable(.deviceNotEligible),
              !model.supportsLocale()
        else {
            fatalError("portable model must report its unavailable service boundary")
        }

        let session = LanguageModelSession(model: .init(useCase: .general)) {
            "Assist with social media posts."
        }
        session.prewarm()
        guard !session.isResponding else {
            fatalError("an unavailable model cannot be responding")
        }

        let tags = Tags(values: ["#swiftOnLinux", "#iceCubes"])
        let rawContent = tags.generatedContent
        let decoded = try Tags(rawContent)
        guard decoded.values == tags.values,
              rawContent.jsonString ==
                "{\"values\": [\"#swiftOnLinux\", \"#iceCubes\"]}",
              Tags.generationSchema.properties.map(\.name) == ["values"],
              Tags.generationSchema.properties[0].guideDescriptions.count == 1
        else {
            fatalError("Generable schema/content round trip drifted")
        }

        var directFailedClosed = false
        do {
            let _: LanguageModelSession.Response<Tags> = try await session.respond(
                to: "Generate hashtags",
                generating: Tags.self
            )
        } catch LanguageModelSession.GenerationError.assetsUnavailable {
            directFailedClosed = true
        }
        guard directFailedClosed else {
            fatalError("direct inference did not fail closed")
        }

        let stream: LanguageModelSession.ResponseStream<String> =
            session.streamResponse(
                to: "Fix spelling",
                options: .init(temperature: 0.3)
            )
        var streamFailedClosed = false
        do {
            for try await _ in stream {
                fatalError("unavailable model emitted fabricated content")
            }
        } catch LanguageModelSession.GenerationError.assetsUnavailable {
            streamFailedClosed = true
        }
        guard streamFailedClosed else {
            fatalError("stream inference did not fail closed")
        }

        print("json=\(rawContent.jsonString)")
        print("roundtrip=\(decoded.values.joined(separator: ","))")
        print("schema-values=1")
        print("options=\(GenerationOptions(temperature: 0.3).temperature ?? -1)")
        print("FOUNDATIONMODELS_GUEST_MACHO_OK macro=generable guide=count generated=roundtrip direct=fail-closed stream=fail-closed available=false")
    }
}
