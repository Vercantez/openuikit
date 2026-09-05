import Foundation
import Translation

func testTranslationSessionConfigurationType() {
    let config = TranslationSession.Configuration()
    precondition(type(of: config) == TranslationSession.Configuration.self)
}

func testTranslationSessionConfigurationInit() {
    let empty = TranslationSession.Configuration()
    precondition(empty.source == nil)
    precondition(empty.target == nil)
    let labeled = TranslationSession.Configuration(
        source: translationEnglish(),
        target: translationFrench()
    )
    precondition(labeled.source == translationEnglish())
    precondition(labeled.target == translationFrench())
}

func testTranslationSessionConfigurationSource() {
    var config = TranslationSession.Configuration()
    precondition(config.source == nil)
    config.source = translationEnglish()
    precondition(config.source == translationEnglish())
}

func testTranslationSessionConfigurationTarget() {
    var config = TranslationSession.Configuration(source: translationEnglish())
    precondition(config.target == nil)
    config.target = translationFrench()
    precondition(config.target == translationFrench())
}

func testTranslationSessionConfigurationVersion() {
    var config = TranslationSession.Configuration(
        source: translationEnglish(),
        target: translationFrench()
    )
    precondition(config.version == 0)
    config.invalidate()
    precondition(config.version == 1)
    config.invalidate()
    precondition(config.version == 2)
}

func testTranslationSessionConfigurationInvalidate() {
    var config = TranslationSession.Configuration(
        source: translationEnglish(),
        target: translationFrench()
    )
    let before = config
    config.invalidate()
    precondition(config.source == before.source)
    precondition(config.target == before.target)
    precondition(config.version == before.version + 1)
    precondition(config != before)
}

func testTranslationSessionConfigurationEquality() {
    let english = translationEnglish()
    let french = translationFrench()
    let left = TranslationSession.Configuration(source: english, target: french)
    let right = TranslationSession.Configuration(source: english, target: french)
    precondition(left == right)
    var mutated = right
    mutated.invalidate()
    precondition(!(left == mutated))
}

func testTranslationSessionConfigurationInequality() {
    let english = translationEnglish()
    let french = translationFrench()
    var config = TranslationSession.Configuration(source: english, target: french)
    let same = TranslationSession.Configuration(source: english, target: french)
    precondition(!(config != same))
    config.invalidate()
    precondition(config != same)
}
