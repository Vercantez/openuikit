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

private struct StandInEchoTool: Tool {
    var name: String { "echo" }
    var description: String { "returns the argument" }
    func call(arguments: String) async throws -> String { "tool:" + arguments }
}

private struct NestedRecord: Generable {
    var title: String
    var count: Int
    var flag: Bool
    var score: Double
    var tags: [String]

    static var generationSchema: GenerationSchema {
        GenerationSchema(
            type: Self.self,
            description: "nested record",
            properties: [
                .init(name: "title", description: "title", type: String.self, guides: [.anyOf(["ok", "no"])]),
                .init(name: "count", description: "count", type: Int.self, guides: [.range(0...9)]),
                .init(name: "flag", type: Bool.self),
                .init(name: "score", type: Double.self, guides: [.minimum(0), .maximum(1)]),
                .init(name: "tags", type: [String].self, guides: [.count(1...4)]),
            ]
        )
    }

    init(_ content: GeneratedContent) throws {
        title = try content.value(String.self, forProperty: "title")
        count = try content.value(Int.self, forProperty: "count")
        flag = try content.value(Bool.self, forProperty: "flag")
        score = try content.value(Double.self, forProperty: "score")
        tags = try content.value([String].self, forProperty: "tags")
    }

    var generatedContent: GeneratedContent {
        GeneratedContent(properties: [
            "title": title,
            "count": count,
            "flag": flag,
            "score": score,
            "tags": tags,
        ])
    }
}

private enum ColorChoice: String, Generable {
    case red
    case blue

    static var generationSchema: GenerationSchema {
        GenerationSchema(type: Self.self, anyOf: ["red", "blue"])
    }

    init(_ content: GeneratedContent) throws {
        let value = try String(content)
        guard let parsed = Self(rawValue: value) else {
            throw GeneratedContentError.typeMismatch(expected: "red|blue", actual: value)
        }
        self = parsed
    }

    var generatedContent: GeneratedContent { .init(kind: .string(rawValue)) }
}

func testStandInAvailabilityAndLanguages() {
    SystemLanguageModel.removeLinuxStandInForTesting()
    let closed = SystemLanguageModel.default
    precondition(closed.isAvailable == false)
    precondition(closed.availability == .unavailable(.deviceNotEligible))
    precondition(closed.supportedLanguages.isEmpty)
    precondition(closed.supportsLocale(Locale(identifier: "en_US")) == false)

    SystemLanguageModel.installLinuxStandInForTesting()
    defer { SystemLanguageModel.removeLinuxStandInForTesting() }
    let open = SystemLanguageModel(useCase: .general, guardrails: .default)
    precondition(open.isAvailable)
    precondition(open.availability == .available)
    precondition(open.supportedLanguages.isEmpty == false)
    precondition(open.supportsLocale(Locale(identifier: "en_US")))
    precondition(open.useCase == .general)
    precondition(LinuxLanguageModelStandIn.echo("hi") == "STANDIN:hi")
}

func testStandInEchoAndTranscript() {
    SystemLanguageModel.installLinuxStandInForTesting()
    defer { SystemLanguageModel.removeLinuxStandInForTesting() }
    let session = LanguageModelSession(
        model: .default,
        tools: [],
        instructions: "Assist"
    )
    session.prewarm(promptPrefix: Prompt("pre:"))
    waitFor {
        precondition(session.isResponding == false)
        let response = try! await session.respond(
            to: "hello",
            options: GenerationOptions(sampling: .greedy, temperature: 0.2, maximumResponseTokens: 64)
        )
        precondition(response.content == "STANDIN:pre:hello")
        precondition(response.rawContent.isComplete)
        let kinds = session.transcript.map { entry -> String in
            switch entry {
            case .instructions: return "instructions"
            case .prompt: return "prompt"
            case .response: return "response"
            case .toolCalls: return "toolCalls"
            case .toolOutput: return "toolOutput"
            }
        }
        precondition(kinds == ["instructions", "prompt", "response"])
        precondition(session.isResponding == false)

        let typed = try! await session.respond(to: Prompt("again"), generating: String.self)
        precondition(typed.content == "STANDIN:again")

        let schema = try! await session.respond(
            to: "plain",
            schema: String.generationSchema
        )
        precondition(try! schema.content.value(String.self) == "STANDIN:plain")

        let built = try! await session.respond {
            "built"
        }
        precondition(built.content == "STANDIN:built")
    }
}

func testStandInStructuredAndEnumGenerable() {
    SystemLanguageModel.installLinuxStandInForTesting()
    defer { SystemLanguageModel.removeLinuxStandInForTesting() }
    let session = LanguageModelSession()
    let json = "{\"title\":\"ok\",\"count\":2,\"flag\":true,\"score\":0.5,\"tags\":[\"a\"]}"
    waitFor {
        let record = try! await session.respond(to: json, generating: NestedRecord.self)
        precondition(record.content.title == "ok")
        precondition(record.content.count == 2)
        precondition(record.content.tags == ["a"])
        _ = NestedRecord.generationSchema
        let color = try! await session.respond(to: "\"red\"", generating: ColorChoice.self)
        precondition(color.content == .red)
        let schemaResponse = try! await session.respond(
            to: json,
            schema: NestedRecord.generationSchema
        )
        precondition(try! schemaResponse.content.value(String.self, forProperty: "title") == "ok")
    }
}

func testStandInToolCalling() {
    SystemLanguageModel.installLinuxStandInForTesting()
    defer { SystemLanguageModel.removeLinuxStandInForTesting() }
    let tool = StandInEchoTool()
    let session = LanguageModelSession(model: .default, tools: [tool], instructions: "tools")
    waitFor {
        let prompt = LinuxLanguageModelStandIn.toolPrefix + "echo ping"
        let response = try! await session.respond(to: prompt)
        precondition(response.content.hasPrefix("STANDIN:"))
        var sawCall = false
        var sawOutput = false
        for entry in session.transcript {
            switch entry {
            case .toolCalls(let calls):
                precondition(calls[0].toolName == "echo")
                sawCall = true
            case .toolOutput(let output):
                precondition(output.toolName == "echo")
                precondition(output.description.contains("tool:ping"))
                sawOutput = true
            default:
                break
            }
        }
        precondition(sawCall && sawOutput)
    }
}

func testStandInGenerationErrors() {
    SystemLanguageModel.installLinuxStandInForTesting()
    defer { SystemLanguageModel.removeLinuxStandInForTesting() }
    let session = LanguageModelSession()
    waitFor {
        do {
            _ = try await session.respond(
                to: "x",
                options: GenerationOptions(temperature: 9)
            )
            fatalError("invalid temperature must fail")
        } catch LanguageModelSession.GenerationError.unsupportedGuide {
            ()
        } catch {
            fatalError("unexpected \(error)")
        }
        do {
            _ = try await session.respond(
                to: "x",
                options: GenerationOptions(maximumResponseTokens: 0)
            )
            fatalError("invalid token cap must fail")
        } catch LanguageModelSession.GenerationError.unsupportedGuide {
            ()
        } catch {
            fatalError("unexpected \(error)")
        }
        do {
            _ = try await session.respond(to: LinuxLanguageModelStandIn.guardrailPrefix)
            fatalError("guardrail sentinel must fail")
        } catch LanguageModelSession.GenerationError.guardrailViolation {
            ()
        } catch {
            fatalError("unexpected \(error)")
        }
        do {
            _ = try await session.respond(to: LinuxLanguageModelStandIn.refusalPrefix)
            fatalError("refusal sentinel must fail")
        } catch LanguageModelSession.GenerationError.refusal {
            ()
        } catch {
            fatalError("unexpected \(error)")
        }
        do {
            _ = try await session.respond(to: LinuxLanguageModelStandIn.regexGuidePrefix)
            fatalError("regex sentinel must fail")
        } catch LanguageModelSession.GenerationError.unsupportedGuide {
            ()
        } catch {
            fatalError("unexpected \(error)")
        }
        do {
            _ = try await session.respond(to: LinuxLanguageModelStandIn.localePrefix)
            fatalError("locale sentinel must fail")
        } catch LanguageModelSession.GenerationError.unsupportedLanguageOrLocale {
            ()
        } catch {
            fatalError("unexpected \(error)")
        }
        let huge = String(repeating: "a", count: LinuxLanguageModelStandIn.contextWindowCharacters + 1)
        do {
            _ = try await session.respond(to: huge)
            fatalError("context window must fail")
        } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
            ()
        } catch {
            fatalError("unexpected \(error)")
        }
    }
}

func testStandInStreamResponse() {
    SystemLanguageModel.installLinuxStandInForTesting()
    defer { SystemLanguageModel.removeLinuxStandInForTesting() }
    let session = LanguageModelSession()
    waitFor {
        do {
            var snapshots: [String] = []
            var completeFlags: [Bool] = []
            for try await snapshot in session.streamResponse(to: "stream-me") {
                snapshots.append(snapshot.content)
                completeFlags.append(snapshot.rawContent.isComplete)
            }
            precondition(snapshots.isEmpty == false)
            precondition(snapshots.last == "STANDIN:stream-me")
            precondition(completeFlags.contains(false))
            precondition(completeFlags.last == true)
            let collected = try await session.streamResponse(
                to: Prompt("collect"),
                options: GenerationOptions(sampling: .random(top: 2, seed: 1))
            ).collect()
            precondition(collected.content == "STANDIN:collect")
            let typed = try await session.streamResponse(
                to: "typed",
                generating: String.self
            ).collect()
            precondition(typed.content == "STANDIN:typed")
            let schema = try await session.streamResponse(
                to: "schema",
                schema: String.generationSchema
            ).collect()
            let schemaText = try schema.content.value(String.self)
            precondition(schemaText == "STANDIN:schema")
            let built = try await session.streamResponse {
                "builder"
            }.collect()
            precondition(built.content == "STANDIN:builder")
        } catch {
            fatalError("stream stand-in failed: \(error)")
        }
    }
}

func testTranscriptEntryCodableRoundTrip() {
    let transcript = Transcript(entries: [
        .instructions(
            Transcript.Instructions(
                segments: [.text(.init(content: "sys"))],
                toolDefinitions: [
                    Transcript.ToolDefinition(
                        name: "echo",
                        description: "echo",
                        parameters: String.generationSchema
                    )
                ]
            )
        ),
        .prompt(Transcript.Prompt(segments: [.text(.init(content: "ask"))])),
        .response(Transcript.Response(assetIDs: ["a"], segments: [.text(.init(content: "ans"))])),
        .toolCalls(
            Transcript.ToolCalls([
                Transcript.ToolCall(
                    id: "c1",
                    toolName: "echo",
                    arguments: GeneratedContent(kind: .string("ping"))
                )
            ])
        ),
        .toolOutput(
            Transcript.ToolOutput(
                id: "o1",
                toolName: "echo",
                segments: [.text(.init(content: "pong"))]
            )
        ),
    ])
    let data = try! JSONEncoder().encode(transcript)
    let decoded = try! JSONDecoder().decode(Transcript.self, from: data)
    precondition(decoded.count == 5)
    if case .instructions = decoded[0] { } else { fatalError("instructions") }
    if case .prompt = decoded[1] { } else { fatalError("prompt") }
    if case .response(let response) = decoded[2] {
        precondition(response.assetIDs == ["a"])
    } else {
        fatalError("response")
    }
    if case .toolCalls(let calls) = decoded[3] {
        precondition(calls[0].toolName == "echo")
    } else {
        fatalError("toolCalls")
    }
    if case .toolOutput(let output) = decoded[4] {
        precondition(output.toolName == "echo")
    } else {
        fatalError("toolOutput")
    }
}
