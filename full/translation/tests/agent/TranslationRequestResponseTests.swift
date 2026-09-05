import Foundation
import Translation

func testTranslationSessionRequest() {
    let request = TranslationSession.Request(sourceText: "hello")
    precondition(type(of: request) == TranslationSession.Request.self)
}

func testTranslationSessionRequestInit() {
    let unlabeled = TranslationSession.Request(sourceText: "hello")
    precondition(unlabeled.sourceText == "hello")
    precondition(unlabeled.clientIdentifier == nil)
    let labeled = TranslationSession.Request(sourceText: "hi", clientIdentifier: "abc")
    precondition(labeled.sourceText == "hi")
    precondition(labeled.clientIdentifier == "abc")
}

func testTranslationSessionRequestSourceText() {
    var request = TranslationSession.Request(sourceText: "hello")
    precondition(request.sourceText == "hello")
    request.sourceText = "bonjour"
    precondition(request.sourceText == "bonjour")
}

func testTranslationSessionRequestClientIdentifier() {
    var request = TranslationSession.Request(sourceText: "hello")
    precondition(request.clientIdentifier == nil)
    request.clientIdentifier = "client-1"
    precondition(request.clientIdentifier == "client-1")
}

func testTranslationSessionResponse() {
    let response = TranslationSession.Response(
        sourceLanguage: translationEnglish(),
        targetLanguage: translationFrench(),
        sourceText: "hello",
        targetText: "bonjour"
    )
    precondition(type(of: response) == TranslationSession.Response.self)
}

func testTranslationSessionResponseInit() {
    let response = TranslationSession.Response(
        sourceLanguage: translationEnglish(),
        targetLanguage: translationFrench(),
        sourceText: "hello",
        targetText: "bonjour",
        clientIdentifier: "abc"
    )
    precondition(response.sourceLanguage == translationEnglish())
    precondition(response.targetLanguage == translationFrench())
    precondition(response.sourceText == "hello")
    precondition(response.targetText == "bonjour")
    precondition(response.clientIdentifier == "abc")
}

func testTranslationSessionResponseSourceLanguage() {
    let english = translationEnglish()
    let response = TranslationSession.Response(
        sourceLanguage: english,
        targetLanguage: translationFrench(),
        sourceText: "hello",
        targetText: "bonjour"
    )
    precondition(response.sourceLanguage == english)
}

func testTranslationSessionResponseTargetLanguage() {
    let french = translationFrench()
    let response = TranslationSession.Response(
        sourceLanguage: translationEnglish(),
        targetLanguage: french,
        sourceText: "hello",
        targetText: "bonjour"
    )
    precondition(response.targetLanguage == french)
}

func testTranslationSessionResponseSourceText() {
    let response = TranslationSession.Response(
        sourceLanguage: translationEnglish(),
        targetLanguage: translationFrench(),
        sourceText: "hello",
        targetText: "bonjour"
    )
    precondition(response.sourceText == "hello")
}

func testTranslationSessionResponseTargetText() {
    let response = TranslationSession.Response(
        sourceLanguage: translationEnglish(),
        targetLanguage: translationFrench(),
        sourceText: "hello",
        targetText: "bonjour"
    )
    precondition(response.targetText == "bonjour")
}

func testTranslationSessionResponseClientIdentifier() {
    let missing = TranslationSession.Response(
        sourceLanguage: translationEnglish(),
        targetLanguage: translationFrench(),
        sourceText: "hello",
        targetText: "bonjour"
    )
    precondition(missing.clientIdentifier == nil)
    let labeled = TranslationSession.Response(
        sourceLanguage: translationEnglish(),
        targetLanguage: translationFrench(),
        sourceText: "hello",
        targetText: "bonjour",
        clientIdentifier: "abc"
    )
    precondition(labeled.clientIdentifier == "abc")
}
