@_spi(OpenUIKitHost) import Speech
import Foundation

func testCustomLanguageModelData() {
    let data = SFCustomLanguageModelData(
        locale: Locale(identifier: "en-US"),
        identifier: "probe",
        version: "1"
    )
    precondition(data.identifier == "probe")
    precondition(data.version == "1")
    precondition(data.locale.identifier == "en-US")
    let other = SFCustomLanguageModelData(
        locale: Locale(identifier: "en-US"),
        identifier: "probe",
        version: "1"
    )
    precondition(data == other)
    precondition(data != SFCustomLanguageModelData(locale: Locale(identifier: "fr-FR"), identifier: "x", version: "1"))
    _ = speechHash(data)
    _ = data.hashValue
    let encoded = try! JSONEncoder().encode(data)
    let decoded = try! JSONDecoder().decode(SFCustomLanguageModelData.self, from: encoded)
    precondition(decoded.identifier == "probe")
}

func testCustomLanguageModelInsert() {
    let data = SFCustomLanguageModelData(
        locale: Locale(identifier: "en-US"),
        identifier: "probe",
        version: "1"
    )
    let phrase = SFCustomLanguageModelData.PhraseCount(phrase: "OpenUIKit", count: 3)
    precondition(phrase.phrase == "OpenUIKit")
    precondition(phrase.count == 3)
    precondition(phrase.description.contains("OpenUIKit"))
    precondition(phrase != SFCustomLanguageModelData.PhraseCount(phrase: "other", count: 1))
    _ = speechHash(phrase)
    _ = phrase.hashValue
    data.insert(phraseCount: phrase)
    phrase.insert(data: data)
    let pronunciation = SFCustomLanguageModelData.CustomPronunciation(grapheme: "ui", phonemes: ["y", "u"])
    precondition(pronunciation.grapheme == "ui")
    precondition(pronunciation.phonemes == ["y", "u"])
    precondition(pronunciation.description.contains("ui"))
    precondition(pronunciation != SFCustomLanguageModelData.CustomPronunciation(grapheme: "b", phonemes: ["b"]))
    _ = speechHash(pronunciation)
    _ = pronunciation.hashValue
    data.insert(term: pronunciation)
    pronunciation.insert(data: data)
    precondition(data.snapshotPhraseCounts().contains(where: { $0.phrase == "OpenUIKit" && $0.count == 3 }))
    precondition(data.snapshotPronunciations().contains(where: { $0.grapheme == "ui" }))
    precondition(SFCustomLanguageModelData.supportedPhonemes(locale: Locale(identifier: "en-US")).isEmpty)
    let encodedPhrase = try! JSONEncoder().encode(phrase)
    let decodedPhrase = try! JSONDecoder().decode(SFCustomLanguageModelData.PhraseCount.self, from: encodedPhrase)
    precondition(decodedPhrase.count == 3)
    let encodedPron = try! JSONEncoder().encode(pronunciation)
    let decodedPron = try! JSONDecoder().decode(SFCustomLanguageModelData.CustomPronunciation.self, from: encodedPron)
    precondition(decodedPron.grapheme == "ui")
}

func testCustomLanguageModelBuilder() {
    let optionalPhrase: String? = "optional"
    let flag = true
    let items = ["a", "b"]
    let data = SFCustomLanguageModelData(
        locale: Locale(identifier: "en-US"),
        identifier: "builder",
        version: "1",
        builder: {
            SFCustomLanguageModelData.PhraseCount(phrase: "OpenUIKit", count: 3)
            SFCustomLanguageModelData.CustomPronunciation(grapheme: "ui", phonemes: ["y", "u"])
            if let phrase = optionalPhrase {
                SFCustomLanguageModelData.PhraseCount(phrase: phrase, count: 1)
            }
            if flag {
                SFCustomLanguageModelData.PhraseCount(phrase: "yes", count: 1)
            } else {
                SFCustomLanguageModelData.PhraseCount(phrase: "no", count: 1)
            }
            for item in items {
                SFCustomLanguageModelData.PhraseCount(phrase: item, count: 1)
            }
            SFCustomLanguageModelData.PhraseCountsFromTemplates(
                classes: ["App": ["Mail"]]
            ) {
                SFCustomLanguageModelData.TemplatePhraseCountGenerator.Template("open {App}", count: 2)
                if flag {
                    SFCustomLanguageModelData.TemplatePhraseCountGenerator.Template("launch {App}", count: 1)
                } else {
                    SFCustomLanguageModelData.TemplatePhraseCountGenerator.Template("close {App}", count: 1)
                }
            }
        }
    )
    precondition(data.snapshotPhraseCounts().contains(where: { $0.phrase == "OpenUIKit" }))
    let compound = SFCustomLanguageModelData.CompoundTemplate([
        SFCustomLanguageModelData.TemplatePhraseCountGenerator.Template("x", count: 1)
    ])
    let generator = SFCustomLanguageModelData.TemplatePhraseCountGenerator()
    compound.insert(generator: generator)
}

func testPhraseCountGenerator() {
    let generator = SFCustomLanguageModelData.PhraseCountGenerator()
    let data = SFCustomLanguageModelData(
        locale: Locale(identifier: "en-US"),
        identifier: "gen",
        version: "1"
    )
    let encoded = try! JSONEncoder().encode(generator)
    let decoded = try! JSONDecoder().decode(SFCustomLanguageModelData.PhraseCountGenerator.self, from: encoded)
    precondition(generator == decoded)
    _ = speechHash(generator)
    _ = generator.hashValue
    generator.insert(data: data)
    data.insert(phraseCountGenerator: generator)
    _ = SFCustomLanguageModelData.PhraseCountGenerator.Element.self
    _ = SFCustomLanguageModelData.PhraseCountGenerator.AsyncIterator.self
    let nestedIterator = generator.makeAsyncIterator()
    _ = type(of: nestedIterator)
}

func testPhraseCountGeneratorSequence() {
    let generator = SFCustomLanguageModelData.TemplatePhraseCountGenerator()
    generator.define(className: "App", values: ["Mail"])
    generator.insert(template: "open {App}", count: 2)
    speechRunAsync {
        do {
            let containsWhere = try await generator.contains { $0.phrase == "open {App}" }
            precondition(containsWhere)
            let containsValue = try await generator.contains(
                SFCustomLanguageModelData.PhraseCount(phrase: "open {App}", count: 2)
            )
            precondition(containsValue)
            let first = try await generator.first { $0.count == 2 }
            precondition(first?.count == 2)
            let all = try await generator.allSatisfy { $0.count > 0 }
            precondition(all)
            let reduced = try await generator.reduce(0) { $0 + $1.count }
            precondition(reduced == 2)
            _ = try await generator.reduce(into: 0) { partial, item in
                partial += item.count
            }
            var mapped: [String] = []
            for try await phrase in generator.map({ $0.phrase }) {
                mapped.append(phrase)
            }
            precondition(mapped == ["open {App}"])
            func throwingIdentity(_ value: String) throws -> String { value }
            var throwingMapped: [String] = []
            for try await phrase in generator.map({ try throwingIdentity($0.phrase) }) {
                throwingMapped.append(phrase)
            }
            precondition(throwingMapped == ["open {App}"])
            var filtered: [SFCustomLanguageModelData.PhraseCount] = []
            for try await item in generator.filter({ $0.count == 2 }) {
                filtered.append(item)
            }
            precondition(filtered.count == 1)
            var prefixed: [SFCustomLanguageModelData.PhraseCount] = []
            for try await item in generator.prefix(1) {
                prefixed.append(item)
            }
            precondition(prefixed.count == 1)
            var dropped: [SFCustomLanguageModelData.PhraseCount] = []
            for try await item in generator.dropFirst(0) {
                dropped.append(item)
            }
            precondition(dropped.count == 1)
            var compactValues: [String] = []
            for try await item in generator.compactMap({ $0.count > 0 ? $0.phrase : nil }) {
                compactValues.append(item)
            }
            precondition(compactValues == ["open {App}"])
            var throwingCompact: [String] = []
            for try await item in generator.compactMap({ try throwingIdentity($0.phrase) as String? }) {
                throwingCompact.append(item)
            }
            precondition(throwingCompact == ["open {App}"])
            _ = try generator.prefix(while: { $0.count > 0 })
            _ = generator.drop(while: { $0.count == 0 })
            _ = try await generator.min(by: { $0.count < $1.count })
            _ = try await generator.max(by: { $0.count < $1.count })
            var emptyFlat: [SFCustomLanguageModelData.PhraseCount] = []
            for try await item in generator.flatMap({ _ in
                SpeechEmptyResults<SFCustomLanguageModelData.PhraseCount>()
            }) {
                emptyFlat.append(item)
            }
            precondition(emptyFlat.isEmpty)
            var streamFlat: [SFCustomLanguageModelData.PhraseCount] = []
            for try await item in generator.flatMap({ _ in
                SpeechNeverResults<SFCustomLanguageModelData.PhraseCount>()
            }) {
                streamFlat.append(item)
            }
            precondition(streamFlat.isEmpty)
            func throwingEmpty() throws -> SpeechEmptyResults<SFCustomLanguageModelData.PhraseCount> {
                SpeechEmptyResults()
            }
            var throwingFlat: [SFCustomLanguageModelData.PhraseCount] = []
            for try await item in generator.flatMap({ _ in try throwingEmpty() }) {
                throwingFlat.append(item)
            }
            precondition(throwingFlat.isEmpty)
            let iterator = generator.makeAsyncIterator()
            _ = try await iterator.next()
            var isolatedIterator = generator.makeAsyncIterator()
            _ = try await isolatedIterator.next(isolation: nil)
        } catch {
            fatalError("phrase generator sequence failed: \(error)")
        }
    }
}

func testTemplatePhraseCountGenerator() {
    let generator = SFCustomLanguageModelData.TemplatePhraseCountGenerator()
    generator.define(className: "App", values: ["Mail"])
    generator.insert(template: "open {App}", count: 2)
    precondition(generator != SFCustomLanguageModelData.TemplatePhraseCountGenerator())
    _ = speechHash(generator)
    let template = SFCustomLanguageModelData.TemplatePhraseCountGenerator.Template("x", count: 1)
    precondition(template.body == "x")
    precondition(template.count == 1)
    precondition(template != SFCustomLanguageModelData.TemplatePhraseCountGenerator.Template("y", count: 1))
    _ = speechHash(template)
    _ = template.hashValue
    template.insert(generator: generator)
    let encoded = try! JSONEncoder().encode(template)
    let decoded = try! JSONDecoder().decode(
        SFCustomLanguageModelData.TemplatePhraseCountGenerator.Template.self,
        from: encoded
    )
    precondition(decoded.count == 1)
    let encodedGen = try! JSONEncoder().encode(generator)
    _ = try! JSONDecoder().decode(SFCustomLanguageModelData.TemplatePhraseCountGenerator.self, from: encodedGen)
    let iterator = SFCustomLanguageModelData.TemplatePhraseCountGenerator.Iterator(
        templates: [template],
        templateClasses: ["App": ["Mail"]]
    )
    _ = type(of: iterator)
    speechRunAsync {
        let next = try? await iterator.next()
        precondition(next?.phrase == "x")
        let asyncIterator = generator.makeAsyncIterator()
        _ = try? await asyncIterator.next()
    }
}

func testCustomLanguageModelExport() {
    let data = SFCustomLanguageModelData(
        locale: Locale(identifier: "en-US"),
        identifier: "probe",
        version: "1"
    )
    speechRunAsync {
        do {
            try await data.export(to: URL(fileURLWithPath: "/tmp/out.bin"))
            fatalError("export should fail closed")
        } catch {
            precondition((error as? SFSpeechError)?.code == .internalServiceError)
        }
    }
}
