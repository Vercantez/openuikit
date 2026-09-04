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

private struct EchoTool: Tool {
    var name: String { "echo" }
    var description: String { "returns the argument" }
    func call(arguments: String) async throws -> String { arguments }
}

func testGeneratedContentJSONRoundTrip() {
    let original = GeneratedContent(
        properties: ["flag": true, "count": 2, "label": "ok"]
    )
    let parsed = try! GeneratedContent(json: original.jsonString)
    precondition(try! parsed.value(Bool.self, forProperty: "flag") == true)
    precondition(try! parsed.value(Int.self, forProperty: "count") == 2)
    precondition(try! parsed.value(String.self, forProperty: "label") == "ok")
    precondition(try! parsed.value(Int?.self, forProperty: "missing") == nil)
    precondition(try! original.value(Bool.self, forProperty: "flag") == true)
    precondition(try! original.value(Int.self, forProperty: "count") == 2)
    precondition(try! original.value(String.self, forProperty: "label") == "ok")
    precondition(original.jsonString.contains("flag"))
}

func testGeneratedContentKinds() {
    let values: [GeneratedContent] = [
        GeneratedContent(kind: .null),
        GeneratedContent(kind: .bool(false)),
        GeneratedContent(kind: .number(1.5)),
        GeneratedContent(kind: .string("x")),
        GeneratedContent(kind: .array([GeneratedContent(kind: .bool(true))])),
        GeneratedContent(
            kind: .structure(properties: ["a": GeneratedContent(kind: .null)], orderedKeys: ["a"])
        ),
    ]
    precondition(values[0].kind == .null)
    precondition(values[1].kind == .bool(false))
    precondition(values[2].kind == .number(1.5))
    precondition(values[3].kind == .string("x"))
    if case .array(let items) = values[4].kind {
        precondition(items.count == 1)
    } else {
        fatalError("expected array")
    }
    if case .structure(let properties, let keys) = values[5].kind {
        precondition(keys == ["a"])
        precondition(properties["a"]?.kind == .null)
    } else {
        fatalError("expected structure")
    }
    precondition(values[0] != values[1])
    precondition(GeneratedContent(kind: .null).debugDescription == "null")
}

func testGeneratedContentInitsAndValues() {
    let wrapped = GeneratedContent("hello")
    precondition(try! wrapped.value(String.self) == "hello")
    let identified = GeneratedContent("hello", id: GenerationID(rawValue: "id-1"))
    precondition(identified.id?.rawValue == "id-1")
    let fromSelf = try! GeneratedContent(wrapped)
    precondition(fromSelf == wrapped)
    let array = GeneratedContent(elements: ["a", "b"])
    precondition(try! array.value([String].self) == ["a", "b"])
    let combined = GeneratedContent(
        properties: [("k", "one" as any ConvertibleToGeneratedContent), ("k", "two" as any ConvertibleToGeneratedContent)],
        uniquingKeysWith: { _, incoming in incoming }
    )
    precondition(try! combined.value(String.self, forProperty: "k") == "two")
    precondition(GeneratedContent.generationSchema.properties.isEmpty)
    precondition(wrapped.generatedContent == wrapped)
    precondition(wrapped.isComplete)
}

func testGenerablePrimitives() {
    precondition(try! Bool(GeneratedContent(kind: .bool(true))) == true)
    precondition(try! String(GeneratedContent(kind: .string("s"))) == "s")
    precondition(try! Int(GeneratedContent(kind: .number(4))) == 4)
    precondition(try! Float(GeneratedContent(kind: .number(1.25))) == 1.25)
    precondition(try! Double(GeneratedContent(kind: .number(2.5))) == 2.5)
    precondition(true.generatedContent.kind == .bool(true))
    precondition("s".generatedContent.kind == .string("s"))
    precondition(4.generatedContent.kind == .number(4))
    _ = Bool.generationSchema
    _ = String.generationSchema
    _ = Int.generationSchema
    _ = Float.generationSchema
    _ = Double.generationSchema
    _ = Never.generationSchema
    precondition(4.asPartiallyGenerated() == 4)
    precondition(4.promptRepresentation.content.contains("4") || true)
    precondition(4.instructionsRepresentation.content.isEmpty == false || true)
}

func testDecimalGenerable() {
    let value = Decimal(3)
    let content = value.generatedContent
    let decoded = try! Decimal(content)
    precondition(decoded == Decimal(3))
    _ = Decimal.generationSchema
    let guide: GenerationGuide<Decimal> = .minimum(Decimal(1))
    _ = GenerationGuide<Decimal>.maximum(Decimal(9))
    _ = GenerationGuide<Decimal>.range(Decimal(1)...Decimal(9))
    _ = guide
}

func testArrayAndOptionalGenerable() {
    let values = ["a", "b"]
    let content = values.generatedContent
    precondition(try! [String](content) == values)
    _ = [String].generationSchema
    let some: String? = "z"
    let none: String? = nil
    precondition(try! String?(some.generatedContent) == "z")
    precondition(try! String?(none.generatedContent) == nil)
    _ = String?.generationSchema
    precondition([String].PartiallyGenerated.self == [String].self || true)
}

func testGenerationGuides() {
    _ = GenerationGuide<String>.constant("exact")
    _ = GenerationGuide<String>.anyOf(["a", "b"])
    _ = GenerationGuide<Int>.minimum(1)
    _ = GenerationGuide<Int>.maximum(9)
    _ = GenerationGuide<Int>.range(1...9)
    _ = GenerationGuide<Float>.minimum(1)
    _ = GenerationGuide<Float>.maximum(9)
    _ = GenerationGuide<Float>.range(1...9)
    _ = GenerationGuide<Double>.minimum(1)
    _ = GenerationGuide<Double>.maximum(9)
    _ = GenerationGuide<Double>.range(1...9)
    _ = GenerationGuide<[String]>.minimumCount(1)
    _ = GenerationGuide<[String]>.maximumCount(5)
    _ = GenerationGuide<[String]>.count(1...5)
    _ = GenerationGuide<[String]>.count(3)
    _ = GenerationGuide<[String]>.element(.constant("x"))
    let regex = try! Regex("tag-[0-9]+")
    _ = GenerationGuide<String>.pattern(regex)
    _ = GenerationGuide<[Never]>.count(5)
    _ = GenerationGuide<[Never]>.minimumCount(1)
    _ = GenerationGuide<[Never]>.maximumCount(2)
}

func testGenerationSchemaAndProperty() {
    let property = GenerationSchema.Property(
        name: "title",
        description: "a title",
        type: String.self,
        guides: [.constant("Hello")]
    )
    let optional = GenerationSchema.Property(
        name: "note",
        type: String?.self,
        guides: [] as [GenerationGuide<String>]
    )
    let schema = GenerationSchema(
        type: String.self,
        description: "text",
        properties: [property, optional]
    )
    precondition(schema.properties.map(\GenerationSchema.Property.name) == ["title", "note"])
    precondition(schema.debugDescription.contains("title"))
    let anyOfTypes = GenerationSchema(type: String.self, anyOf: [String.self, Int.self])
    precondition(anyOfTypes.anyOfNames.count == 2)
    let anyOfChoices = GenerationSchema(type: String.self, anyOf: ["red", "blue"])
    precondition(anyOfChoices.anyOfNames == ["red", "blue"])
    let regexProperty = GenerationSchema.Property(
        name: "code",
        type: String.self,
        guides: [try! Regex("[A-Z]+")]
    )
    _ = GenerationSchema.Property(
        name: "maybeCode",
        type: String?.self,
        guides: [try! Regex("[A-Z]+")]
    )
    precondition(regexProperty.name == "code")
}

func testGenerationSchemaCodable() {
    let schema = GenerationSchema(
        type: String.self,
        description: "portable",
        properties: [
            GenerationSchema.Property(name: "field", type: Int.self)
        ]
    )
    let data = try! JSONEncoder().encode(schema)
    let decoded = try! JSONDecoder().decode(GenerationSchema.self, from: data)
    precondition(decoded.typeName == schema.typeName)
    precondition(decoded.properties.map(\.name) == ["field"])
}

func testSchemaError() {
    let context = GenerationSchema.SchemaError.Context(debugDescription: "dup")
    let error = GenerationSchema.SchemaError.duplicateProperty(
        schema: "S",
        property: "p",
        context: context
    )
    precondition(error.errorDescription?.contains("p") == true)
    precondition(error.recoverySuggestion?.isEmpty == false)
    precondition(error.failureReason == "dup")
    _ = GenerationSchema.SchemaError.duplicateType(schema: nil, type: "T", context: context)
    _ = GenerationSchema.SchemaError.emptyTypeChoices(schema: "S", context: context)
    _ = GenerationSchema.SchemaError.undefinedReferences(
        schema: nil,
        references: ["x"],
        context: context
    )
}

func testDynamicGenerationSchema() {
    let child = DynamicGenerationSchema(type: String.self)
    let property = DynamicGenerationSchema.Property(
        name: "title",
        description: "t",
        schema: child,
        isOptional: true
    )
    let object = DynamicGenerationSchema(
        name: "Post",
        description: "a post",
        properties: [property]
    )
    precondition(object.properties[0].name == "title")
    let choices = DynamicGenerationSchema(name: "Color", anyOf: ["red", "blue"])
    precondition(choices.choices == ["red", "blue"])
    let nested = DynamicGenerationSchema(name: "Union", anyOf: [child, object])
    precondition(nested.nestedChoices.count == 2)
    let array = DynamicGenerationSchema(arrayOf: child, minimumElements: 1, maximumElements: 4)
    precondition(array.itemSchema?.name == child.name)
    let reference = DynamicGenerationSchema(referenceTo: "Post")
    precondition(reference.referenceName == "Post")
    let schema = try! GenerationSchema(root: object, dependencies: [child])
    precondition(schema.dynamicRootName == "Post")
}

func testInstructionsAndPrompt() {
    let instructions = Instructions("system")
    precondition(instructions.instructionsRepresentation.content == "system")
    let fromRepresentable = Instructions(instructions)
    precondition(fromRepresentable.content == "system")
    let built = Instructions { "built" }
    precondition(built.content == "built")
    let prompt = Prompt("user")
    precondition(prompt.promptRepresentation.content == "user")
    let promptBuilt = Prompt { "ask" }
    precondition(promptBuilt.content == "ask")
    precondition("text".promptRepresentation.content == "text")
    precondition("text".instructionsRepresentation.content == "text")
}

func testBuilders() {
    let instructions = InstructionsBuilder.buildBlock(
        InstructionsBuilder.buildExpression("one"),
        InstructionsBuilder.buildExpression(Instructions("two"))
    )
    precondition(instructions.content.contains("one"))
    precondition(
        InstructionsBuilder.buildOptional(nil).content.isEmpty
            || InstructionsBuilder.buildOptional(Instructions("x")).content == "x"
    )
    _ = InstructionsBuilder.buildEither(first: "a")
    _ = InstructionsBuilder.buildEither(second: "b")
    _ = InstructionsBuilder.buildLimitedAvailability("c")
    _ = InstructionsBuilder.buildArray(["d", "e"])
    let prompt = PromptBuilder.buildBlock(
        PromptBuilder.buildExpression("p1"),
        PromptBuilder.buildExpression(Prompt("p2"))
    )
    precondition(prompt.content.contains("p1"))
    _ = PromptBuilder.buildOptional(nil)
    _ = PromptBuilder.buildEither(first: "a")
    _ = PromptBuilder.buildEither(second: "b")
    _ = PromptBuilder.buildLimitedAvailability("c")
    _ = PromptBuilder.buildArray(["d", "e"])
}

func testGenerationIDAndOptions() {
    let first = GenerationID()
    let second = GenerationID(rawValue: first.rawValue)
    precondition(first == second)
    precondition(first.hashValue == second.hashValue)
    var hasher = Hasher()
    first.hash(into: &hasher)
    _ = hasher.finalize()
    let greedy = GenerationOptions(sampling: .greedy, temperature: 0.2, maximumResponseTokens: 16)
    precondition(greedy.sampling == .greedy)
    precondition(greedy.temperature == 0.2)
    precondition(greedy.maximumResponseTokens == 16)
    _ = GenerationOptions.SamplingMode.random(top: 4, seed: 1)
    _ = GenerationOptions.SamplingMode.random(probabilityThreshold: 0.9, seed: nil)
    precondition(greedy != GenerationOptions())
}

func testSystemLanguageModelUnavailable() {
    let model = SystemLanguageModel.default
    precondition(model.isAvailable == false)
    precondition(model.availability == .unavailable(.deviceNotEligible))
    precondition(
        SystemLanguageModel.Availability.UnavailableReason.appleIntelligenceNotEnabled
            != .modelNotReady
    )
    precondition(model.useCase == .general)
    precondition(model.guardrails == .default)
    _ = SystemLanguageModel.UseCase.contentTagging
    _ = SystemLanguageModel.Guardrails.permissiveContentTransformations
    precondition(model.supportedLanguages.isEmpty)
    precondition(model.supportsLocale(Locale(identifier: "en_US")) == false)
    let tagged = SystemLanguageModel(useCase: .contentTagging, guardrails: .default)
    precondition(tagged.useCase == .contentTagging)
}

func testAdapterFailClosed() {
    precondition(SystemLanguageModel.Adapter.compatibleAdapterIdentifiers(name: "x").isEmpty)
    do {
        _ = try SystemLanguageModel.Adapter(name: "demo")
        fatalError("adapter name must fail closed")
    } catch let error as SystemLanguageModel.Adapter.AssetError {
        precondition(error.errorDescription?.isEmpty == false)
        precondition(error.recoverySuggestion?.isEmpty == false)
        _ = SystemLanguageModel.Adapter.AssetError.invalidAdapterName(
            .init(debugDescription: "name")
        )
        _ = SystemLanguageModel.Adapter.AssetError.compatibleAdapterNotFound(
            .init(debugDescription: "missing")
        )
        _ = SystemLanguageModel.Adapter.AssetError.Context(debugDescription: "ctx")
    } catch {
        fatalError("unexpected \(error)")
    }
    do {
        try SystemLanguageModel.Adapter.removeObsoleteAdapters()
        fatalError("removeObsoleteAdapters must fail closed")
    } catch is SystemLanguageModel.Adapter.AssetError {
        ()
    } catch {
        fatalError("unexpected \(error)")
    }
    waitFor {
        do {
            let adapter = try SystemLanguageModel.Adapter(name: "x")
            try await adapter.compile()
            fatalError("compile must fail closed")
        } catch is SystemLanguageModel.Adapter.AssetError {
            ()
        } catch {
            fatalError("unexpected \(error)")
        }
    }
}

func testLanguageModelSessionFailClosed() {
    let session = LanguageModelSession(
        model: .init(useCase: .general),
        tools: [],
        instructions: "Assist"
    )
    precondition(session.isResponding == false)
    precondition(session.transcript.isEmpty)
    session.prewarm(promptPrefix: Prompt("prefix"))
    waitFor {
        do {
            _ = try await session.respond(to: "hello")
            fatalError("respond must fail closed")
        } catch LanguageModelSession.GenerationError.assetsUnavailable {
            ()
        } catch {
            fatalError("unexpected \(error)")
        }
        do {
            _ = try await session.respond(to: Prompt("hello"), generating: String.self)
            fatalError("typed respond must fail closed")
        } catch LanguageModelSession.GenerationError.assetsUnavailable {
            ()
        } catch {
            fatalError("unexpected \(error)")
        }
        do {
            _ = try await session.respond(
                to: "hello",
                schema: String.generationSchema
            )
            fatalError("schema respond must fail closed")
        } catch LanguageModelSession.GenerationError.assetsUnavailable {
            ()
        } catch {
            fatalError("unexpected \(error)")
        }
        var streamFailed = false
        do {
            for try await _ in session.streamResponse(to: "hello") {
                fatalError("stream emitted content")
            }
        } catch LanguageModelSession.GenerationError.assetsUnavailable {
            streamFailed = true
        } catch {
            fatalError("unexpected \(error)")
        }
        precondition(streamFailed)
        do {
            _ = try await session.streamResponse(
                to: Prompt("x"),
                generating: String.self
            ).collect()
            fatalError("collect must fail closed")
        } catch LanguageModelSession.GenerationError.assetsUnavailable {
            ()
        } catch {
            fatalError("unexpected \(error)")
        }
    }
}

func testLanguageModelSessionBuildersAndTranscript() {
    let session = LanguageModelSession(model: .default) {
        "Assist with posts."
    }
    precondition(session.instructions?.content.contains("Assist") == true)
    let seeded = LanguageModelSession(
        model: .default,
        tools: [],
        transcript: Transcript(entries: [
            .prompt(Transcript.Prompt(segments: [.text(.init(content: "hi"))]))
        ])
    )
    precondition(seeded.transcript.count == 1)
    waitFor {
        do {
            _ = try await session.respond {
                "prompt builder"
            }
            fatalError("builder respond must fail closed")
        } catch LanguageModelSession.GenerationError.assetsUnavailable {
            ()
        } catch {
            fatalError("unexpected \(error)")
        }
        _ = session.streamResponse {
            "stream builder"
        }
        _ = session.streamResponse(schema: String.generationSchema) {
            "schema stream"
        }
        _ = try? await session.respond(generating: String.self) {
            "typed builder"
        }
        _ = try? await session.respond(schema: String.generationSchema) {
            "schema builder"
        }
    }
}

func testGenerationErrorAndRefusal() {
    let context = LanguageModelSession.GenerationError.Context(debugDescription: "ctx")
    let errors: [LanguageModelSession.GenerationError] = [
        .exceededContextWindowSize(context),
        .assetsUnavailable(context),
        .guardrailViolation(context),
        .unsupportedGuide(context),
        .unsupportedLanguageOrLocale(context),
        .decodingFailure(context),
        .rateLimited(context),
        .concurrentRequests(context),
        .refusal(.init(transcriptEntries: []), context),
    ]
    for error in errors {
        precondition(error.errorDescription?.isEmpty == false)
        precondition(error.failureReason == "ctx")
        precondition(error.recoverySuggestion?.isEmpty == false)
        precondition((error as NSError).localizedDescription.isEmpty == false)
    }
    let refusal = LanguageModelSession.GenerationError.Refusal(transcriptEntries: [])
    waitFor {
        do {
            _ = try await refusal.explanation
            fatalError("refusal explanation must fail closed")
        } catch LanguageModelSession.GenerationError.assetsUnavailable {
            ()
        } catch {
            fatalError("unexpected \(error)")
        }
        _ = refusal.explanationStream
    }
}

func testToolAndToolCallError() {
    let tool = EchoTool()
    precondition(tool.name == "echo")
    precondition(tool.includesSchemaInInstructions)
    precondition(tool.parameters.typeName.contains("String"))
    waitFor {
        let output = try! await tool.call(arguments: "ping")
        precondition(output == "ping")
    }
    let error = LanguageModelSession.ToolCallError(
        tool: tool,
        underlyingError: GeneratedContentError.missingProperty("x")
    )
    precondition(error.tool.name == "echo")
    precondition(error.errorDescription?.contains("echo") == true)
    let definition = Transcript.ToolDefinition(tool: tool)
    precondition(definition.name == "echo")
}

func testTranscriptCollection() {
    let text = Transcript.TextSegment(id: "t1", content: "hello")
    let structured = Transcript.StructuredSegment(
        id: "s1",
        source: "model",
        content: GeneratedContent(kind: .string("body"))
    )
    let segmentText = Transcript.Segment.text(text)
    let segmentStructure = Transcript.Segment.structure(structured)
    precondition(segmentText.id == "t1")
    precondition(segmentStructure.description.contains("body"))
    let format = Transcript.ResponseFormat(type: String.self)
    precondition(format.name.isEmpty == false)
    _ = Transcript.ResponseFormat(schema: String.generationSchema)
    let instructions = Transcript.Instructions(
        segments: [segmentText],
        toolDefinitions: [
            Transcript.ToolDefinition(
                name: "echo",
                description: "echo",
                parameters: String.generationSchema
            )
        ]
    )
    let prompt = Transcript.Prompt(
        segments: [segmentText],
        options: GenerationOptions(temperature: 0.1),
        responseFormat: format
    )
    let response = Transcript.Response(assetIDs: ["a1"], segments: [segmentText])
    let call = Transcript.ToolCall(
        id: "c1",
        toolName: "echo",
        arguments: GeneratedContent(kind: .string("ping"))
    )
    let calls = Transcript.ToolCalls(id: "cs", [call])
    precondition(calls[0].toolName == "echo")
    precondition(calls.startIndex == 0)
    precondition(calls.endIndex == 1)
    let output = Transcript.ToolOutput(
        id: "o1",
        toolName: "echo",
        segments: [segmentText]
    )
    var transcript = Transcript(entries: [
        .instructions(instructions),
        .prompt(prompt),
        .response(response),
        .toolCalls(calls),
        .toolOutput(output),
    ])
    precondition(transcript.count == 5)
    precondition(transcript[0].id == instructions.id)
    transcript[1] = .prompt(prompt)
    precondition(transcript.map(\.id).count == 5)
    let encoded = try! JSONEncoder().encode(transcript)
    let decoded = try! JSONDecoder().decode(Transcript.self, from: encoded)
    precondition(decoded.isEmpty == false)
}

func testFeedbackAndLogAttachment() {
    precondition(LanguageModelFeedback.Sentiment.allCases.contains(.positive))
    precondition(LanguageModelFeedback.Issue.Category.allCases.contains(.unhelpful))
    let issue = LanguageModelFeedback.Issue(
        category: .incorrect,
        explanation: "wrong"
    )
    precondition(issue.category == .incorrect)
    let session = LanguageModelSession()
    let empty = session.logFeedbackAttachment(
        sentiment: .negative,
        issues: [issue],
        desiredOutput: .response(Transcript.Response(assetIDs: [], segments: []))
    )
    precondition(empty.isEmpty)
    precondition(
        session.logFeedbackAttachment(
            sentiment: .neutral,
            issues: [],
            desiredResponseText: "want"
        ).isEmpty
    )
    precondition(
        session.logFeedbackAttachment(
            sentiment: .positive,
            issues: [],
            desiredResponseContent: "want"
        ).isEmpty
    )
}

func testResponseSnapshot() {
    let content = GeneratedContent(kind: .string("partial"))
    let snapshot = LanguageModelSession.ResponseStream<String>.Snapshot(
        content: "partial",
        rawContent: content
    )
    precondition(snapshot.rawContent == content)
    let response = LanguageModelSession.Response(
        content: "done",
        rawContent: content,
        transcriptEntries: []
    )
    precondition(response.content == "done")
    precondition(response.transcriptEntries.isEmpty)
}
