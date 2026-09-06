import CoreFoundation
import CoreMedia
import Foundation

func testCMFormatDescriptionValueOverlayMembers() {
    let field = CMFormatDescription.Extensions.Value.FieldDetail.self
    precondition(CFEqual(field.temporalBottomFirst.rawValue, kCMFormatDescriptionFieldDetail_TemporalBottomFirst))
    precondition(CFEqual(field.spatialFirstLineLate.rawValue, kCMFormatDescriptionFieldDetail_SpatialFirstLineLate))
    precondition(CFEqual(field.spatialFirstLineEarly.rawValue, kCMFormatDescriptionFieldDetail_SpatialFirstLineEarly))
    let matrix = CMFormatDescription.Extensions.Value.YCbCrMatrix.self
    precondition(CFEqual(matrix.itu_R_2020.rawValue, kCMFormatDescriptionYCbCrMatrix_ITU_R_2020))
    precondition(CFEqual(matrix.itu_R_601_4.rawValue, kCMFormatDescriptionYCbCrMatrix_ITU_R_601_4))
    precondition(CFEqual(matrix.smpted_240M_1995.rawValue, kCMFormatDescriptionYCbCrMatrix_SMPTE_240M_1995))
    let chroma = CMFormatDescription.Extensions.Value.ChromaLocation.self
    precondition(CFEqual(chroma.bottomLeft.rawValue, kCMFormatDescriptionChromaLocation_BottomLeft))
    precondition(CFEqual(chroma.top.rawValue, kCMFormatDescriptionChromaLocation_Top))
    precondition(CFEqual(chroma.left.rawValue, kCMFormatDescriptionChromaLocation_Left))
    precondition(CFEqual(chroma.dv420.rawValue, kCMFormatDescriptionChromaLocation_DV420))
    precondition(CFEqual(chroma.bottom.rawValue, kCMFormatDescriptionChromaLocation_Bottom))
    precondition(CFEqual(chroma.center.rawValue, kCMFormatDescriptionChromaLocation_Center))
    precondition(CFEqual(chroma.topLeft.rawValue, kCMFormatDescriptionChromaLocation_TopLeft))
    let primaries = CMFormatDescription.Extensions.Value.ColorPrimaries.self
    precondition(CFEqual(primaries.itu_R_2020.rawValue, kCMFormatDescriptionColorPrimaries_ITU_R_2020))
    precondition(CFEqual(primaries.p22.rawValue, kCMFormatDescriptionColorPrimaries_P22))
    precondition(CFEqual(primaries.dci_P3.rawValue, kCMFormatDescriptionColorPrimaries_DCI_P3))
    precondition(CFEqual(primaries.p3_D65.rawValue, kCMFormatDescriptionColorPrimaries_P3_D65))
    precondition(CFEqual(primaries.smpte_C.rawValue, kCMFormatDescriptionColorPrimaries_SMPTE_C))
    precondition(CFEqual(primaries.ebu_3213.rawValue, kCMFormatDescriptionColorPrimaries_EBU_3213))
    let projection = CMFormatDescription.Extensions.Value.ProjectionKind.self
    precondition(CFEqual(projection.rectilinear.rawValue, kCMFormatDescriptionProjectionKind_Rectilinear))
    precondition(CFEqual(projection.equirectangular.rawValue, kCMFormatDescriptionProjectionKind_Equirectangular))
    precondition(CFEqual(projection.appleImmersiveVideo.rawValue, kCMFormatDescriptionProjectionKind_AppleImmersiveVideo))
    precondition(CFEqual(projection.halfEquirectangular.rawValue, kCMFormatDescriptionProjectionKind_HalfEquirectangular))
    precondition(CFEqual(projection.parametricImmersive.rawValue, kCMFormatDescriptionProjectionKind_ParametricImmersive))
    let packing = CMFormatDescription.Extensions.Value.ViewPackingKind.self
    precondition(CFEqual(packing.sideBySide.rawValue, kCMFormatDescriptionViewPackingKind_SideBySide))
    precondition(CFEqual(packing.overUnder.rawValue, kCMFormatDescriptionViewPackingKind_OverUnder))
    let alpha = CMFormatDescription.Extensions.Value.AlphaChannelMode.self
    precondition(CFEqual(alpha.premultipliedAlpha.rawValue, kCMFormatDescriptionAlphaChannelMode_PremultipliedAlpha))
    precondition(CFEqual(alpha.straightAlpha.rawValue, kCMFormatDescriptionAlphaChannelMode_StraightAlpha))
}

func testCMFormatDescriptionTransferAndTextOverlayMembers() {
    let transfer = CMFormatDescription.Extensions.Value.TransferFunction.self
    precondition(CFEqual(transfer.itu_R_2020.rawValue, kCMFormatDescriptionTransferFunction_ITU_R_2020))
    precondition(CFEqual(transfer.itu_R_2100_HLG.rawValue, kCMFormatDescriptionTransferFunction_ITU_R_2100_HLG))
    precondition(CFEqual(transfer.smpte_ST_428_1.rawValue, kCMFormatDescriptionTransferFunction_SMPTE_ST_428_1))
    precondition(CFEqual(transfer.smpte_240M_1995.rawValue, kCMFormatDescriptionTransferFunction_SMPTE_240M_1995))
    precondition(CFEqual(transfer.smpte_ST_2084_PQ.rawValue, kCMFormatDescriptionTransferFunction_SMPTE_ST_2084_PQ))
    precondition(CFEqual(transfer.sRGB.rawValue, kCMFormatDescriptionTransferFunction_sRGB))
    precondition(CFEqual(transfer.linear.rawValue, kCMFormatDescriptionTransferFunction_Linear))
    precondition(CFEqual(transfer.useGamma.rawValue, kCMFormatDescriptionTransferFunction_UseGamma))
    let display = CMFormatDescription.Extensions.Value.TextDisplayFlags.self
    precondition(display.fillTextRegion.rawValue == kCMTextDisplayFlag_fillTextRegion)
    precondition(display.writeTextVertically.rawValue == kCMTextDisplayFlag_writeTextVertically)
    precondition(display.continuousKaraoke.rawValue == kCMTextDisplayFlag_continuousKaraoke)
    precondition(display.allSubtitlesForced.rawValue == kCMTextDisplayFlag_allSubtitlesForced)
    precondition(display.forcedSubtitlesPresent.rawValue == kCMTextDisplayFlag_forcedSubtitlesPresent)
    precondition(display.obeySubtitleFormatting.rawValue == kCMTextDisplayFlag_obeySubtitleFormatting)
    precondition(display.scrollOut.rawValue == kCMTextDisplayFlag_scrollOut)
    precondition(CMFormatDescription.Extensions.Value.TextJustification.top.rawValue == kCMTextJustification_left_top)
    precondition(CMFormatDescription.Extensions.Value.TextJustification.left.rawValue == kCMTextJustification_left_top)
    precondition(CMFormatDescription.Extensions.Value.TextJustification.right.rawValue == kCMTextJustification_bottom_right)
    precondition(CMFormatDescription.Extensions.Value.TextJustification.bottom.rawValue == kCMTextJustification_bottom_right)
    precondition(
        CFEqual(
            CMFormatDescription.Extensions.Value.LogTransferFunction.appleLog.rawValue,
            kCMFormatDescriptionLogTransferFunction_AppleLog
        )
    )
    precondition(
        CFEqual(CMFormatDescription.Extensions.Value.Vendor.apple.rawValue, kCMFormatDescriptionVendor_Apple)
    )
    precondition(
        CFEqual(CMFormatDescription.Extensions.Value.HeroEye.left.rawValue, kCMFormatDescriptionHeroEye_Left)
    )
    precondition(
        CFEqual(CMFormatDescription.Extensions.Value.HeroEye.right.rawValue, kCMFormatDescriptionHeroEye_Right)
    )
}

func testCMFormatDescriptionMPEG2ProfileOverlayMembers() {
    let profile = CMFormatDescription.Extensions.Value.MPEG2VideoProfile.self
    precondition(profile.hdv_720p24.rawValue == UInt32(bitPattern: kCMMPEG2VideoProfile_HDV_720p24))
    precondition(profile.hdv_720p25.rawValue == UInt32(bitPattern: kCMMPEG2VideoProfile_HDV_720p25))
    precondition(profile.hdv_720p50.rawValue == UInt32(bitPattern: kCMMPEG2VideoProfile_HDV_720p50))
    precondition(profile.hdv_720p60.rawValue == UInt32(bitPattern: kCMMPEG2VideoProfile_HDV_720p60))
    precondition(profile.hdv_1080i50.rawValue == UInt32(bitPattern: kCMMPEG2VideoProfile_HDV_1080i50))
    precondition(profile.hdv_1080i60.rawValue == UInt32(bitPattern: kCMMPEG2VideoProfile_HDV_1080i60))
    precondition(profile.hdv_1080p24.rawValue == UInt32(bitPattern: kCMMPEG2VideoProfile_HDV_1080p24))
    precondition(profile.hdv_1080p25.rawValue == UInt32(bitPattern: kCMMPEG2VideoProfile_HDV_1080p25))
    precondition(profile.hdv_1080p30.rawValue == UInt32(bitPattern: kCMMPEG2VideoProfile_HDV_1080p30))
    precondition(profile.xdcam_HD_540p.rawValue == UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_HD_540p))
    precondition(profile.xdcam_HD422_540p.rawValue == UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_HD422_540p))
    precondition(profile.xdcam_EX_720p24_VBR35.rawValue == UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_EX_720p24_VBR35))
    precondition(profile.xdcam_EX_720p25_VBR35.rawValue == UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_EX_720p25_VBR35))
    precondition(profile.xdcam_EX_720p30_VBR35.rawValue == UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_EX_720p30_VBR35))
    precondition(profile.xdcam_EX_720p50_VBR35.rawValue == UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_EX_720p50_VBR35))
    precondition(profile.xdcam_EX_720p60_VBR35.rawValue == UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_EX_720p60_VBR35))
    precondition(profile.xdcam_EX_1080i50_VBR35.rawValue == UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_EX_1080i50_VBR35))
    precondition(profile.xdcam_EX_1080i60_VBR35.rawValue == UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_EX_1080i60_VBR35))
    precondition(profile.xdcam_EX_1080p24_VBR35.rawValue == UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_EX_1080p24_VBR35))
    precondition(profile.xdcam_EX_1080p25_VBR35.rawValue == UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_EX_1080p25_VBR35))
    precondition(profile.xdcam_EX_1080p30_VBR35.rawValue == UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_EX_1080p30_VBR35))
    precondition(profile.xdcam_HD_1080i50_VBR35.rawValue == UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_HD_1080i50_VBR35))
    precondition(profile.xdcam_HD_1080i60_VBR35.rawValue == UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_HD_1080i60_VBR35))
    precondition(profile.xdcam_HD_1080p24_VBR35.rawValue == UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_HD_1080p24_VBR35))
    precondition(profile.xdcam_HD_1080p25_VBR35.rawValue == UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_HD_1080p25_VBR35))
    precondition(profile.xdcam_HD_1080p30_VBR35.rawValue == UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_HD_1080p30_VBR35))
    precondition(profile.xdcam_HD422_720p24_CBR50.rawValue == UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_HD422_720p24_CBR50))
    precondition(profile.xdcam_HD422_720p25_CBR50.rawValue == UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_HD422_720p25_CBR50))
    precondition(profile.xdcam_HD422_720p30_CBR50.rawValue == UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_HD422_720p30_CBR50))
    precondition(profile.xdcam_HD422_720p50_CBR50.rawValue == UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_HD422_720p50_CBR50))
    precondition(profile.xdcam_HD422_720p60_CBR50.rawValue == UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_HD422_720p60_CBR50))
    precondition(profile.xdcam_HD422_1080i50_CBR50.rawValue == UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_HD422_1080i50_CBR50))
    precondition(profile.xdcam_HD422_1080i60_CBR50.rawValue == UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_HD422_1080i60_CBR50))
    precondition(profile.xdcam_HD422_1080p24_CBR50.rawValue == UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_HD422_1080p24_CBR50))
    precondition(profile.xdcam_HD422_1080p25_CBR50.rawValue == UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_HD422_1080p25_CBR50))
    precondition(profile.xdcam_HD422_1080p30_CBR50.rawValue == UInt32(bitPattern: kCMMPEG2VideoProfile_XDCAM_HD422_1080p30_CBR50))
    precondition(profile.xf.rawValue == UInt32(bitPattern: kCMMPEG2VideoProfile_XF))
}
