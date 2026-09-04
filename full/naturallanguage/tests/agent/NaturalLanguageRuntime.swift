import Foundation
import NaturalLanguage

// Standalone host probe. The sealed schema-v2 gate compiles tests/agent/*Tests.swift
// and does not run this file.

precondition(NLLanguage.english.rawValue == "en")
precondition(NLLanguageRecognizer.dominantLanguage(for:
    "This is a thoughtful message about building a better social network together."
) == .english)

let tokenizer = NLTokenizer(unit: .word)
tokenizer.string = "Hello world"
precondition(!tokenizer.tokens(for: tokenizer.string!.startIndex..<tokenizer.string!.endIndex).isEmpty)

precondition(NLEmbedding.wordEmbedding(for: .english) == nil)
precondition(NLContextualEmbedding(language: .english) == nil)

print("NATURALLANGUAGE_AGENT_RUNTIME_OK")
