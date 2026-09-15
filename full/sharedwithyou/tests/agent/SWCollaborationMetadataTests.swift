import SharedWithYou

func testCollaborationMetadataTypeIdentifierValue() {
    swRequire(
        SWCollaborationMetadataTypeIdentifier
            == "com.apple.sharedwithyou.collaboration-metadata",
        "metadata uti"
    )
    swRequire(!SWCollaborationMetadataTypeIdentifier.isEmpty, "nonempty")
}
