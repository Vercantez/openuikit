import Foundation
import ClassKit

func testTypedConstants() {
    classKitExpect(CLSErrorCodeDomain == "CLSErrorCodeDomain", "error domain")

    classKitExpect(CLSContextTopic.math.rawValue == "CLSContextTopicMath", "math")
    classKitExpect(CLSContextTopic.science.rawValue == "CLSContextTopicScience", "science")
    classKitExpect(CLSContextTopic.literacyAndWriting.rawValue == "CLSContextTopicLiteracyAndWriting", "literacy")
    classKitExpect(CLSContextTopic.worldLanguage.rawValue == "CLSContextTopicWorldLanguage", "world")
    classKitExpect(CLSContextTopic.socialScience.rawValue == "CLSContextTopicSocialScience", "social")
    classKitExpect(
        CLSContextTopic.computerScienceAndEngineering.rawValue == "CLSContextTopicComputerScienceAndEngineering",
        "cs"
    )
    classKitExpect(CLSContextTopic.artsAndMusic.rawValue == "CLSContextTopicArtsAndMusic", "arts")
    classKitExpect(CLSContextTopic.healthAndFitness.rawValue == "CLSContextTopicHealthAndFitness", "health")
    let customTopic = CLSContextTopic(rawValue: "custom.topic")
    classKitExpect(customTopic.rawValue == "custom.topic", "topic init")
    classKitExpect(CLSContextTopic.math != CLSContextTopic.science, "topic !=")
    classKitExpect(CLSContextTopic.math == CLSContextTopic(rawValue: "CLSContextTopicMath"), "topic ==")
    _ = CLSContextTopic.science.hashValue
    var topicHasher = Hasher()
    CLSContextTopic.math.hash(into: &topicHasher)
    _ = topicHasher.finalize()

    classKitExpect(CLSErrorUserInfoKey.objectKey.rawValue == "CLSErrorObjectKey", "objectKey")
    classKitExpect(
        CLSErrorUserInfoKey.successfulObjectsKey.rawValue == "CLSErrorSuccessfulObjectsKey",
        "successful"
    )
    classKitExpect(
        CLSErrorUserInfoKey.underlyingErrorsKey.rawValue == "CLSErrorUnderlyingErrorsKey",
        "underlying"
    )
    classKitExpect(CLSErrorUserInfoKey("x").rawValue == "x", "key init(_)")
    classKitExpect(CLSErrorUserInfoKey(rawValue: "y").rawValue == "y", "key init raw")
    classKitExpect(CLSErrorUserInfoKey.objectKey != .underlyingErrorsKey, "key !=")
    _ = CLSErrorUserInfoKey.objectKey.hashValue
    var keyHasher = Hasher()
    CLSErrorUserInfoKey.successfulObjectsKey.hash(into: &keyHasher)
    _ = keyHasher.finalize()

    classKitExpect(CLSPredicateKeyPath.dateCreated.rawValue == "dateCreated", "dateCreated")
    classKitExpect(CLSPredicateKeyPath.identifier.rawValue == "identifier", "identifier")
    classKitExpect(CLSPredicateKeyPath.parent.rawValue == "parent", "parent")
    classKitExpect(CLSPredicateKeyPath.title.rawValue == "title", "title")
    classKitExpect(CLSPredicateKeyPath.topic.rawValue == "topic", "topic")
    classKitExpect(CLSPredicateKeyPath.universalLinkURL.rawValue == "universalLinkURL", "url")
    classKitExpect(CLSPredicateKeyPath("title").rawValue == "title", "pred init(_)")
    classKitExpect(CLSPredicateKeyPath(rawValue: "identifier").rawValue == "identifier", "pred init raw")
    classKitExpect(CLSPredicateKeyPath.title != .identifier, "pred !=")
    _ = CLSPredicateKeyPath.title.hashValue
    var predHasher = Hasher()
    CLSPredicateKeyPath.topic.hash(into: &predHasher)
    _ = predHasher.finalize()
}
