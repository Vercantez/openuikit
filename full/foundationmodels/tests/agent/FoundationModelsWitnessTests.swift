import Dispatch
import Foundation
import FoundationModels

private func waitFor(_ body: @escaping () async -> Void) {
    let semaphore = DispatchSemaphore(value: 0)
    Task {
        await body()
        semaphore.signal()
    }
    precondition(
        semaphore.wait(timeout: .now() + 5) == .success,
        "async body did not complete"
    )
}

func testLocalizedErrorWitnesses() {
    let schemaContext = GenerationSchema.SchemaError.Context(debugDescription: "dup")
    let schemaError = GenerationSchema.SchemaError.duplicateProperty(
        schema: "S",
        property: "p",
        context: schemaContext
    )
    let assetError = SystemLanguageModel.Adapter.AssetError.invalidAsset(
        .init(debugDescription: "asset")
    )
    let generationError = LanguageModelSession.GenerationError.assetsUnavailable(
        .init(debugDescription: "ctx")
    )
    let toolError = LanguageModelSession.ToolCallError(
        tool: SimpleWitnessTool(),
        underlyingError: GeneratedContentError.missingProperty("x")
    )
    for error in [schemaError as LocalizedError, assetError, generationError, toolError] {
        _ = error.helpAnchor
        _ = error.failureReason
        _ = error.recoverySuggestion
        _ = (error as NSError).localizedDescription
    }
    precondition(schemaError.failureReason == "dup")
    precondition(assetError.recoverySuggestion?.isEmpty == false)
    precondition(generationError.errorDescription?.isEmpty == false)
    precondition(toolError.recoverySuggestion?.isEmpty == false)
}

private struct SimpleWitnessTool: Tool {
    var name: String { "witness" }
    var description: String { "witness tool" }
    func call(arguments: String) async throws -> String { arguments }
}

func testGenerableWitnesses() {
    let values: [any ConvertibleToGeneratedContent] = [
        Decimal(3),
        GeneratedContent(kind: .string("g")),
        "s",
        ["a"],
        true,
        1.5 as Double,
        Float(1.25),
        4,
        Optional("z"),
    ]
    for value in values {
        precondition(value.promptRepresentation.content.isEmpty == false)
        precondition(value.instructionsRepresentation.content.isEmpty == false)
    }
    _ = Decimal(3).asPartiallyGenerated()
    _ = GeneratedContent(kind: .null).asPartiallyGenerated()
    _ = "s".asPartiallyGenerated()
    _ = ["a"].asPartiallyGenerated()
    _ = true.asPartiallyGenerated()
    _ = (1.5 as Double).asPartiallyGenerated()
    _ = Float(1).asPartiallyGenerated()
    _ = 4.asPartiallyGenerated()
    precondition(Decimal.PartiallyGenerated.self == Decimal.self)
    precondition(String.PartiallyGenerated.self == String.self)
    precondition(Bool.PartiallyGenerated.self == Bool.self)
    precondition(Int.PartiallyGenerated.self == Int.self)
    precondition(Double.PartiallyGenerated.self == Double.self)
    precondition(Float.PartiallyGenerated.self == Float.self)
    precondition(GeneratedContent.PartiallyGenerated.self == GeneratedContent.self)
    precondition([String].PartiallyGenerated.self == [String].self)
    _ = Never.generationSchema
}

func testEquatableInequalityWitnesses() {
    let leftID = GenerationID(rawValue: "a")
    let rightID = GenerationID(rawValue: "b")
    precondition(leftID != rightID)
    precondition(GeneratedContent(kind: .null) != GeneratedContent(kind: .bool(true)))
    precondition(GeneratedContent.Kind.null != .bool(true))
    precondition(GenerationOptions(temperature: 0.1) != GenerationOptions())
    precondition(
        GenerationOptions.SamplingMode.greedy
            != .random(probabilityThreshold: 0.5, seed: 1)
    )
    precondition(
        SystemLanguageModel.Availability.available
            != .unavailable(.deviceNotEligible)
    )
    precondition(
        SystemLanguageModel.Availability.UnavailableReason.deviceNotEligible
            != .modelNotReady
    )
    precondition(SystemLanguageModel.UseCase.general != .contentTagging)
    precondition(LanguageModelFeedback.Sentiment.positive != .negative)
    precondition(
        LanguageModelFeedback.Issue.Category.incorrect
            != .unhelpful
    )
    let text = Transcript.TextSegment(content: "a")
    let other = Transcript.TextSegment(content: "b")
    precondition(text != other)
    precondition(
        Transcript.Segment.text(text) != .text(other)
    )
    let prompt = Transcript.Prompt(segments: [.text(text)])
    let response = Transcript.Response(assetIDs: [], segments: [.text(text)])
    precondition(
        Transcript.Entry.prompt(prompt) != .response(response)
    )
    let instructions = Transcript.Instructions(segments: [.text(text)], toolDefinitions: [])
    precondition(
        Transcript.Instructions(segments: [.text(other)], toolDefinitions: []) != instructions
    )
    let format = Transcript.ResponseFormat(type: String.self)
    precondition(format != Transcript.ResponseFormat(schema: Int.generationSchema))
    let definition = Transcript.ToolDefinition(
        name: "a",
        description: "a",
        parameters: String.generationSchema
    )
    precondition(
        definition
            != Transcript.ToolDefinition(
                name: "b",
                description: "b",
                parameters: String.generationSchema
            )
    )
    let structured = Transcript.StructuredSegment(
        source: "model",
        content: GeneratedContent(kind: .string("x"))
    )
    precondition(
        structured
            != Transcript.StructuredSegment(
                source: "user",
                content: GeneratedContent(kind: .string("y"))
            )
    )
    let output = Transcript.ToolOutput(
        id: "o",
        toolName: "echo",
        segments: [.text(text)]
    )
    precondition(
        output
            != Transcript.ToolOutput(
                id: "p",
                toolName: "echo",
                segments: [.text(other)]
            )
    )
    let call = Transcript.ToolCall(
        id: "c",
        toolName: "echo",
        arguments: GeneratedContent(kind: .string("a"))
    )
    precondition(
        call
            != Transcript.ToolCall(
                id: "d",
                toolName: "echo",
                arguments: GeneratedContent(kind: .string("b"))
            )
    )
    let calls = Transcript.ToolCalls([call])
    precondition(calls != Transcript.ToolCalls(id: "other", [call]))
    precondition(
        Transcript(entries: [.prompt(prompt)]) != Transcript()
    )
}

func testTranscriptCollectionWitnesses() {
    let text = Transcript.TextSegment(content: "one")
    let prompt = Transcript.Entry.prompt(Transcript.Prompt(segments: [.text(text)]))
    let response = Transcript.Entry.response(
        Transcript.Response(assetIDs: [], segments: [.text(.init(content: "two"))])
    )
    let transcript = Transcript(entries: [prompt, response])
    precondition(transcript.count == 2)
    precondition(transcript.isEmpty == false)
    precondition(transcript.first != nil)
    precondition(transcript.last != nil)
    precondition(transcript.underestimatedCount >= 0)
    _ = transcript.dropFirst()
    _ = transcript.dropLast()
    _ = transcript.prefix(1)
    _ = transcript.suffix(1)
    _ = transcript.prefix(while: { _ in true })
    _ = transcript.drop(while: { _ in false })
    _ = transcript.reversed()
    _ = transcript.map(\.id)
    _ = transcript.firstIndex(where: { $0.id == prompt.id })
    _ = transcript.lastIndex(where: { $0.id == response.id })
    _ = transcript.firstIndex(of: prompt)
    _ = transcript.lastIndex(of: response)
    var index = transcript.endIndex
    transcript.formIndex(before: &index)
    var start = transcript.startIndex
    transcript.formIndex(after: &start)
    var offset = transcript.startIndex
    transcript.formIndex(&offset, offsetBy: 1)
    var limited = transcript.startIndex
    _ = transcript.formIndex(&limited, offsetBy: 8, limitedBy: transcript.endIndex)
    _ = transcript.index(transcript.startIndex, offsetBy: 1, limitedBy: transcript.endIndex)
    _ = transcript.prefix(upTo: transcript.endIndex)
    _ = transcript.prefix(through: transcript.startIndex)
    _ = transcript.suffix(from: transcript.startIndex)
    _ = transcript.split(separator: prompt)
    _ = transcript.split(maxSplits: 1, omittingEmptySubsequences: true, whereSeparator: { _ in false })
    _ = transcript.indices(of: prompt)
    _ = transcript.indices(where: { _ in true })
    _ = transcript.removingSubranges(transcript.indices(where: { _ in false }))
    _ = transcript.randomElement()
    var generator = SystemRandomNumberGenerator()
    _ = transcript.randomElement(using: &generator)
    _ = transcript.trimmingPrefix(while: { _ in false })
    _ = transcript.difference(from: Transcript())
    _ = transcript.difference(from: Transcript(), by: { $0.id == $1.id })
    _ = transcript.makeIterator()
    _ = transcript.allSatisfy { _ in true }
    _ = transcript.compactMap(\.id)
    _ = Array(transcript.enumerated())
    _ = transcript.elementsEqual(Transcript(entries: [prompt, response]), by: { $0.id == $1.id })
    _ = transcript.lexicographicallyPrecedes(Transcript(), by: { $0.id < $1.id })
    _ = transcript.withContiguousStorageIfAvailable { _ in 1 }
    _ = transcript.map { $0.id }
    _ = transcript.max(by: { $0.id < $1.id })
    _ = transcript.min(by: { $0.id < $1.id })
    _ = transcript.lazy
    _ = transcript.count(where: { _ in true })
    _ = transcript.first(where: { _ in true })
    _ = transcript.filter { _ in true }
    _ = transcript.reduce(into: 0) { partial, _ in partial += 1 }
    _ = transcript.reduce(0) { partial, _ in partial + 1 }
    _ = transcript.sorted(by: { $0.id < $1.id })
    _ = transcript.starts(with: Transcript(entries: [prompt]), by: { $0.id == $1.id })
    _ = transcript.contains(where: { _ in true })
    _ = transcript.contains(prompt)
    let calls = Transcript.ToolCalls([
        Transcript.ToolCall(
            id: "c1",
            toolName: "echo",
            arguments: GeneratedContent(kind: .string("a"))
        ),
        Transcript.ToolCall(
            id: "c2",
            toolName: "echo",
            arguments: GeneratedContent(kind: .string("b"))
        ),
    ])
    _ = transcript.sorted(using: KeyPathComparator(\.id))
    _ = transcript.sorted(using: [KeyPathComparator(\.id)])
    _ = calls.sorted(using: KeyPathComparator(\.toolName))
    _ = calls.sorted(using: [KeyPathComparator(\.toolName)])
    _ = calls.allSatisfy { _ in true }
    _ = calls.compactMap(\.toolName)
    _ = Array(calls.enumerated())
    _ = calls.filter { _ in true }
    _ = calls.reduce(0) { partial, _ in partial + 1 }
    _ = calls.sorted(by: { $0.id < $1.id })
    _ = calls.last(where: { _ in true })
    _ = calls.last
    _ = calls.suffix(1)
    _ = calls.dropLast()
    _ = calls.reversed()
    var callIndex = calls.endIndex
    calls.formIndex(before: &callIndex)
    _ = calls.lastIndex(of: calls[0])
    _ = calls.difference(from: Transcript.ToolCalls([]))
    _ = calls.trimmingPrefix(while: { _ in false })
    _ = calls.firstRange(of: calls)
    _ = calls.ranges(of: calls)
    _ = calls.trimmingPrefix(calls.prefix(0))
    _ = transcript.trimmingPrefix(while: { _ in false })
    _ = transcript.firstRange(of: Transcript(entries: [prompt]))
    _ = transcript.ranges(of: Transcript(entries: [prompt]))
    _ = transcript.trimmingPrefix(Transcript())
    precondition(calls.count == 2)
    precondition(calls.isEmpty == false)
    precondition(calls.first != nil)
    precondition(calls.last != nil)
    _ = calls.dropFirst()
    _ = calls.dropLast()
    _ = calls.prefix(1)
    _ = calls.suffix(1)
    _ = calls.reversed()
    _ = calls.map(\.toolName)
    _ = calls.firstIndex(where: { $0.id == "c1" })
    _ = calls.lastIndex(where: { $0.id == "c2" })
    _ = calls.makeIterator()
    _ = calls.difference(from: Transcript.ToolCalls([]))
}

func testResponseStreamSequenceWitnesses() {
    SystemLanguageModel.installLinuxStandInForTesting()
    defer { SystemLanguageModel.removeLinuxStandInForTesting() }
    let session = LanguageModelSession()
    waitFor {
        do {
            let stream = session.streamResponse(to: "seq")
            let all = try await stream.contains(where: { _ in true })
            precondition(all)
            let first = try await session.streamResponse(to: "first").first(where: { _ in true })
            precondition(first != nil)
            _ = try await session.streamResponse(to: "sat").allSatisfy { _ in true }
            var mapped: [Int] = []
            for try await value in session.streamResponse(to: "map").map({ $0.content.count }) {
                mapped.append(value)
            }
            precondition(mapped.isEmpty == false)
            var filtered: [String] = []
            for try await value in session.streamResponse(to: "filter").filter({ !$0.content.isEmpty }) {
                filtered.append(value.content)
            }
            precondition(filtered.isEmpty == false)
            let reduced = try await session.streamResponse(to: "reduce").reduce(0) { $0 + $1.content.count }
            precondition(reduced > 0)
            var into = 0
            _ = try await session.streamResponse(to: "into").reduce(into: into) { partial, snapshot in
                partial += snapshot.content.count
                into = partial
            }
            let dropped = session.streamResponse(to: "drop").dropFirst()
            var dropCount = 0
            for try await _ in dropped { dropCount += 1 }
            _ = dropCount
            var prefixCount = 0
            for try await _ in session.streamResponse(to: "prefix").prefix(2) {
                prefixCount += 1
            }
            precondition(prefixCount >= 1)
            var compact: [String] = []
            for try await value in session.streamResponse(to: "compact").compactMap({ $0.content }) {
                compact.append(value)
            }
            precondition(compact.isEmpty == false)
            let minValue = try await session.streamResponse(to: "min").min { $0.content.count < $1.content.count }
            _ = minValue
            let maxValue = try await session.streamResponse(to: "max").max { $0.content.count < $1.content.count }
            _ = maxValue
            var prefixWhile = 0
            for try await _ in try session.streamResponse(to: "pwhile").prefix(while: { _ in true }) {
                prefixWhile += 1
            }
            var dropWhile = 0
            for try await _ in session.streamResponse(to: "dwhile").drop(while: { _ in false }) {
                dropWhile += 1
            }
            _ = prefixWhile
            _ = dropWhile
            var flat = 0
            for try await _ in session.streamResponse(to: "flat").flatMap({ snapshot in
                session.streamResponse(to: snapshot.content)
            }) {
                flat += 1
            }
            _ = flat
            var throwingMap = 0
            for try await _ in session.streamResponse(to: "tmap").map({ snapshot -> String in
                snapshot.content
            }) {
                throwingMap += 1
            }
            _ = throwingMap
        } catch {
            fatalError("stream witnesses failed: \(error)")
        }
    }
}
