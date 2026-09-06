import CoreMedia

func testCMPackingProjectionStereoRawValues() {
    precondition(CMPackingType.none.rawValue == 0x6E6F6E65)
    precondition(CMPackingType.sideBySide.rawValue == 0x73696465)
    precondition(CMPackingType.overUnder.rawValue == 0x6F766572)
    precondition(kCMPackingType_None == CMPackingType.none.rawValue)
    precondition(kCMPackingType_SideBySide == CMPackingType.sideBySide.rawValue)
    precondition(kCMPackingType_OverUnder == CMPackingType.overUnder.rawValue)
    precondition(CMProjectionType.rectangular.rawValue == 0x72656374)
    precondition(CMProjectionType.equirectangular.rawValue == 0x65717569)
    precondition(CMProjectionType.halfEquirectangular.rawValue == 0x68657175)
    precondition(CMProjectionType.fisheye.rawValue == 0x66697368)
    precondition(CMProjectionType.parametricImmersive.rawValue == 0x7072696D)
    precondition(kCMProjectionType_Rectangular == CMProjectionType.rectangular.rawValue)
    precondition(kCMProjectionType_Equirectangular == CMProjectionType.equirectangular.rawValue)
    precondition(kCMProjectionType_HalfEquirectangular == CMProjectionType.halfEquirectangular.rawValue)
    precondition(kCMProjectionType_Fisheye == CMProjectionType.fisheye.rawValue)
    precondition(kCMProjectionType_ParametricImmersive == CMProjectionType.parametricImmersive.rawValue)
    precondition(CMStereoViewComponents.leftEye.rawValue == 1)
    precondition(CMStereoViewComponents.rightEye.rawValue == 2)
    precondition(kCMStereoView_LeftEye == CMStereoViewComponents.leftEye.rawValue)
    precondition(kCMStereoView_RightEye == CMStereoViewComponents.rightEye.rawValue)
    precondition(CMStereoViewInterpretationOptions.stereoOrderReversed.rawValue == 1)
    precondition(CMStereoViewInterpretationOptions.additionalViews.rawValue == 2)
    precondition(
        kCMStereoViewInterpretation_StereoOrderReversed
            == CMStereoViewInterpretationOptions.stereoOrderReversed.rawValue
    )
    precondition(
        kCMStereoViewInterpretation_AdditionalViews
            == CMStereoViewInterpretationOptions.additionalViews.rawValue
    )
    precondition(CMPackingType(rawValue: 0x6E6F6E65) == CMPackingType.none)
    precondition(CMProjectionType(rawValue: 0x72656374) == CMProjectionType.rectangular)
    precondition(CMStereoViewComponents(rawValue: 1) == CMStereoViewComponents.leftEye)
    precondition(CMStereoViewInterpretationOptions(rawValue: 1) == .stereoOrderReversed)
}
