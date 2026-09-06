import Foundation
import Matter

func testColorControlParams() {
    let _MTRColorControlClusterColorLoopSetParams = MTRColorControlClusterColorLoopSetParams()
    _MTRColorControlClusterColorLoopSetParams.action = n(1)
    _ = _MTRColorControlClusterColorLoopSetParams.action
    _MTRColorControlClusterColorLoopSetParams.direction = n(1)
    _ = _MTRColorControlClusterColorLoopSetParams.direction
    _MTRColorControlClusterColorLoopSetParams.optionsMask = n(1)
    _ = _MTRColorControlClusterColorLoopSetParams.optionsMask
    _MTRColorControlClusterColorLoopSetParams.optionsOverride = n(1)
    _ = _MTRColorControlClusterColorLoopSetParams.optionsOverride
    _MTRColorControlClusterColorLoopSetParams.serverSideProcessingTimeout = n(1)
    _ = _MTRColorControlClusterColorLoopSetParams.serverSideProcessingTimeout
    _MTRColorControlClusterColorLoopSetParams.startHue = n(1)
    _ = _MTRColorControlClusterColorLoopSetParams.startHue
    _MTRColorControlClusterColorLoopSetParams.time = n(1)
    _ = _MTRColorControlClusterColorLoopSetParams.time
    _MTRColorControlClusterColorLoopSetParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRColorControlClusterColorLoopSetParams.timedInvokeTimeoutMs
    _MTRColorControlClusterColorLoopSetParams.updateFlags = n(1)
    _ = _MTRColorControlClusterColorLoopSetParams.updateFlags
    mtrRequire(_MTRColorControlClusterColorLoopSetParams.description.contains("MTRColorControlClusterColorLoopSetParams"), "MTRColorControlClusterColorLoopSetParams desc")
    let _MTRColorControlClusterEnhancedMoveHueParams = MTRColorControlClusterEnhancedMoveHueParams()
    _MTRColorControlClusterEnhancedMoveHueParams.moveMode = n(1)
    _ = _MTRColorControlClusterEnhancedMoveHueParams.moveMode
    _MTRColorControlClusterEnhancedMoveHueParams.optionsMask = n(1)
    _ = _MTRColorControlClusterEnhancedMoveHueParams.optionsMask
    _MTRColorControlClusterEnhancedMoveHueParams.optionsOverride = n(1)
    _ = _MTRColorControlClusterEnhancedMoveHueParams.optionsOverride
    _MTRColorControlClusterEnhancedMoveHueParams.rate = n(1)
    _ = _MTRColorControlClusterEnhancedMoveHueParams.rate
    _MTRColorControlClusterEnhancedMoveHueParams.serverSideProcessingTimeout = n(1)
    _ = _MTRColorControlClusterEnhancedMoveHueParams.serverSideProcessingTimeout
    _MTRColorControlClusterEnhancedMoveHueParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRColorControlClusterEnhancedMoveHueParams.timedInvokeTimeoutMs
    mtrRequire(_MTRColorControlClusterEnhancedMoveHueParams.description.contains("MTRColorControlClusterEnhancedMoveHueParams"), "MTRColorControlClusterEnhancedMoveHueParams desc")
    let _MTRColorControlClusterEnhancedMoveToHueAndSaturationParams = MTRColorControlClusterEnhancedMoveToHueAndSaturationParams()
    _MTRColorControlClusterEnhancedMoveToHueAndSaturationParams.enhancedHue = n(1)
    _ = _MTRColorControlClusterEnhancedMoveToHueAndSaturationParams.enhancedHue
    _MTRColorControlClusterEnhancedMoveToHueAndSaturationParams.optionsMask = n(1)
    _ = _MTRColorControlClusterEnhancedMoveToHueAndSaturationParams.optionsMask
    _MTRColorControlClusterEnhancedMoveToHueAndSaturationParams.optionsOverride = n(1)
    _ = _MTRColorControlClusterEnhancedMoveToHueAndSaturationParams.optionsOverride
    _MTRColorControlClusterEnhancedMoveToHueAndSaturationParams.saturation = n(1)
    _ = _MTRColorControlClusterEnhancedMoveToHueAndSaturationParams.saturation
    _MTRColorControlClusterEnhancedMoveToHueAndSaturationParams.serverSideProcessingTimeout = n(1)
    _ = _MTRColorControlClusterEnhancedMoveToHueAndSaturationParams.serverSideProcessingTimeout
    _MTRColorControlClusterEnhancedMoveToHueAndSaturationParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRColorControlClusterEnhancedMoveToHueAndSaturationParams.timedInvokeTimeoutMs
    _MTRColorControlClusterEnhancedMoveToHueAndSaturationParams.transitionTime = n(1)
    _ = _MTRColorControlClusterEnhancedMoveToHueAndSaturationParams.transitionTime
    mtrRequire(_MTRColorControlClusterEnhancedMoveToHueAndSaturationParams.description.contains("MTRColorControlClusterEnhancedMoveToHueAndSaturationParams"), "MTRColorControlClusterEnhancedMoveToHueAndSaturationParams desc")
    let _MTRColorControlClusterEnhancedMoveToHueParams = MTRColorControlClusterEnhancedMoveToHueParams()
    _MTRColorControlClusterEnhancedMoveToHueParams.direction = n(1)
    _ = _MTRColorControlClusterEnhancedMoveToHueParams.direction
    _MTRColorControlClusterEnhancedMoveToHueParams.enhancedHue = n(1)
    _ = _MTRColorControlClusterEnhancedMoveToHueParams.enhancedHue
    _MTRColorControlClusterEnhancedMoveToHueParams.optionsMask = n(1)
    _ = _MTRColorControlClusterEnhancedMoveToHueParams.optionsMask
    _MTRColorControlClusterEnhancedMoveToHueParams.optionsOverride = n(1)
    _ = _MTRColorControlClusterEnhancedMoveToHueParams.optionsOverride
    _MTRColorControlClusterEnhancedMoveToHueParams.serverSideProcessingTimeout = n(1)
    _ = _MTRColorControlClusterEnhancedMoveToHueParams.serverSideProcessingTimeout
    _MTRColorControlClusterEnhancedMoveToHueParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRColorControlClusterEnhancedMoveToHueParams.timedInvokeTimeoutMs
    _MTRColorControlClusterEnhancedMoveToHueParams.transitionTime = n(1)
    _ = _MTRColorControlClusterEnhancedMoveToHueParams.transitionTime
    mtrRequire(_MTRColorControlClusterEnhancedMoveToHueParams.description.contains("MTRColorControlClusterEnhancedMoveToHueParams"), "MTRColorControlClusterEnhancedMoveToHueParams desc")
    let _MTRColorControlClusterEnhancedStepHueParams = MTRColorControlClusterEnhancedStepHueParams()
    _MTRColorControlClusterEnhancedStepHueParams.optionsMask = n(1)
    _ = _MTRColorControlClusterEnhancedStepHueParams.optionsMask
    _MTRColorControlClusterEnhancedStepHueParams.optionsOverride = n(1)
    _ = _MTRColorControlClusterEnhancedStepHueParams.optionsOverride
    _MTRColorControlClusterEnhancedStepHueParams.serverSideProcessingTimeout = n(1)
    _ = _MTRColorControlClusterEnhancedStepHueParams.serverSideProcessingTimeout
    _MTRColorControlClusterEnhancedStepHueParams.stepMode = n(1)
    _ = _MTRColorControlClusterEnhancedStepHueParams.stepMode
    _MTRColorControlClusterEnhancedStepHueParams.stepSize = n(1)
    _ = _MTRColorControlClusterEnhancedStepHueParams.stepSize
    _MTRColorControlClusterEnhancedStepHueParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRColorControlClusterEnhancedStepHueParams.timedInvokeTimeoutMs
    _MTRColorControlClusterEnhancedStepHueParams.transitionTime = n(1)
    _ = _MTRColorControlClusterEnhancedStepHueParams.transitionTime
    mtrRequire(_MTRColorControlClusterEnhancedStepHueParams.description.contains("MTRColorControlClusterEnhancedStepHueParams"), "MTRColorControlClusterEnhancedStepHueParams desc")
    let _MTRColorControlClusterMoveColorParams = MTRColorControlClusterMoveColorParams()
    _MTRColorControlClusterMoveColorParams.optionsMask = n(1)
    _ = _MTRColorControlClusterMoveColorParams.optionsMask
    _MTRColorControlClusterMoveColorParams.optionsOverride = n(1)
    _ = _MTRColorControlClusterMoveColorParams.optionsOverride
    _MTRColorControlClusterMoveColorParams.rateX = n(1)
    _ = _MTRColorControlClusterMoveColorParams.rateX
    _MTRColorControlClusterMoveColorParams.rateY = n(1)
    _ = _MTRColorControlClusterMoveColorParams.rateY
    _MTRColorControlClusterMoveColorParams.serverSideProcessingTimeout = n(1)
    _ = _MTRColorControlClusterMoveColorParams.serverSideProcessingTimeout
    _MTRColorControlClusterMoveColorParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRColorControlClusterMoveColorParams.timedInvokeTimeoutMs
    mtrRequire(_MTRColorControlClusterMoveColorParams.description.contains("MTRColorControlClusterMoveColorParams"), "MTRColorControlClusterMoveColorParams desc")
    let _MTRColorControlClusterMoveColorTemperatureParams = MTRColorControlClusterMoveColorTemperatureParams()
    _MTRColorControlClusterMoveColorTemperatureParams.colorTemperatureMaximumMireds = n(1)
    _ = _MTRColorControlClusterMoveColorTemperatureParams.colorTemperatureMaximumMireds
    _MTRColorControlClusterMoveColorTemperatureParams.colorTemperatureMinimumMireds = n(1)
    _ = _MTRColorControlClusterMoveColorTemperatureParams.colorTemperatureMinimumMireds
    _MTRColorControlClusterMoveColorTemperatureParams.moveMode = n(1)
    _ = _MTRColorControlClusterMoveColorTemperatureParams.moveMode
    _MTRColorControlClusterMoveColorTemperatureParams.optionsMask = n(1)
    _ = _MTRColorControlClusterMoveColorTemperatureParams.optionsMask
    _MTRColorControlClusterMoveColorTemperatureParams.optionsOverride = n(1)
    _ = _MTRColorControlClusterMoveColorTemperatureParams.optionsOverride
    _MTRColorControlClusterMoveColorTemperatureParams.rate = n(1)
    _ = _MTRColorControlClusterMoveColorTemperatureParams.rate
    _MTRColorControlClusterMoveColorTemperatureParams.serverSideProcessingTimeout = n(1)
    _ = _MTRColorControlClusterMoveColorTemperatureParams.serverSideProcessingTimeout
    _MTRColorControlClusterMoveColorTemperatureParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRColorControlClusterMoveColorTemperatureParams.timedInvokeTimeoutMs
    mtrRequire(_MTRColorControlClusterMoveColorTemperatureParams.description.contains("MTRColorControlClusterMoveColorTemperatureParams"), "MTRColorControlClusterMoveColorTemperatureParams desc")
    let _MTRColorControlClusterMoveHueParams = MTRColorControlClusterMoveHueParams()
    _MTRColorControlClusterMoveHueParams.moveMode = n(1)
    _ = _MTRColorControlClusterMoveHueParams.moveMode
    _MTRColorControlClusterMoveHueParams.optionsMask = n(1)
    _ = _MTRColorControlClusterMoveHueParams.optionsMask
    _MTRColorControlClusterMoveHueParams.optionsOverride = n(1)
    _ = _MTRColorControlClusterMoveHueParams.optionsOverride
    _MTRColorControlClusterMoveHueParams.rate = n(1)
    _ = _MTRColorControlClusterMoveHueParams.rate
    _MTRColorControlClusterMoveHueParams.serverSideProcessingTimeout = n(1)
    _ = _MTRColorControlClusterMoveHueParams.serverSideProcessingTimeout
    _MTRColorControlClusterMoveHueParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRColorControlClusterMoveHueParams.timedInvokeTimeoutMs
    mtrRequire(_MTRColorControlClusterMoveHueParams.description.contains("MTRColorControlClusterMoveHueParams"), "MTRColorControlClusterMoveHueParams desc")
    let _MTRColorControlClusterMoveSaturationParams = MTRColorControlClusterMoveSaturationParams()
    _MTRColorControlClusterMoveSaturationParams.moveMode = n(1)
    _ = _MTRColorControlClusterMoveSaturationParams.moveMode
    _MTRColorControlClusterMoveSaturationParams.optionsMask = n(1)
    _ = _MTRColorControlClusterMoveSaturationParams.optionsMask
    _MTRColorControlClusterMoveSaturationParams.optionsOverride = n(1)
    _ = _MTRColorControlClusterMoveSaturationParams.optionsOverride
    _MTRColorControlClusterMoveSaturationParams.rate = n(1)
    _ = _MTRColorControlClusterMoveSaturationParams.rate
    _MTRColorControlClusterMoveSaturationParams.serverSideProcessingTimeout = n(1)
    _ = _MTRColorControlClusterMoveSaturationParams.serverSideProcessingTimeout
    _MTRColorControlClusterMoveSaturationParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRColorControlClusterMoveSaturationParams.timedInvokeTimeoutMs
    mtrRequire(_MTRColorControlClusterMoveSaturationParams.description.contains("MTRColorControlClusterMoveSaturationParams"), "MTRColorControlClusterMoveSaturationParams desc")
    let _MTRColorControlClusterMoveToColorParams = MTRColorControlClusterMoveToColorParams()
    _MTRColorControlClusterMoveToColorParams.colorX = n(1)
    _ = _MTRColorControlClusterMoveToColorParams.colorX
    _MTRColorControlClusterMoveToColorParams.colorY = n(1)
    _ = _MTRColorControlClusterMoveToColorParams.colorY
    _MTRColorControlClusterMoveToColorParams.optionsMask = n(1)
    _ = _MTRColorControlClusterMoveToColorParams.optionsMask
    _MTRColorControlClusterMoveToColorParams.optionsOverride = n(1)
    _ = _MTRColorControlClusterMoveToColorParams.optionsOverride
    _MTRColorControlClusterMoveToColorParams.serverSideProcessingTimeout = n(1)
    _ = _MTRColorControlClusterMoveToColorParams.serverSideProcessingTimeout
    _MTRColorControlClusterMoveToColorParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRColorControlClusterMoveToColorParams.timedInvokeTimeoutMs
    _MTRColorControlClusterMoveToColorParams.transitionTime = n(1)
    _ = _MTRColorControlClusterMoveToColorParams.transitionTime
    mtrRequire(_MTRColorControlClusterMoveToColorParams.description.contains("MTRColorControlClusterMoveToColorParams"), "MTRColorControlClusterMoveToColorParams desc")
    let _MTRColorControlClusterMoveToColorTemperatureParams = MTRColorControlClusterMoveToColorTemperatureParams()
    _MTRColorControlClusterMoveToColorTemperatureParams.colorTemperature = n(1)
    _ = _MTRColorControlClusterMoveToColorTemperatureParams.colorTemperature
    _MTRColorControlClusterMoveToColorTemperatureParams.colorTemperatureMireds = n(1)
    _ = _MTRColorControlClusterMoveToColorTemperatureParams.colorTemperatureMireds
    _MTRColorControlClusterMoveToColorTemperatureParams.optionsMask = n(1)
    _ = _MTRColorControlClusterMoveToColorTemperatureParams.optionsMask
    _MTRColorControlClusterMoveToColorTemperatureParams.optionsOverride = n(1)
    _ = _MTRColorControlClusterMoveToColorTemperatureParams.optionsOverride
    _MTRColorControlClusterMoveToColorTemperatureParams.serverSideProcessingTimeout = n(1)
    _ = _MTRColorControlClusterMoveToColorTemperatureParams.serverSideProcessingTimeout
    _MTRColorControlClusterMoveToColorTemperatureParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRColorControlClusterMoveToColorTemperatureParams.timedInvokeTimeoutMs
    _MTRColorControlClusterMoveToColorTemperatureParams.transitionTime = n(1)
    _ = _MTRColorControlClusterMoveToColorTemperatureParams.transitionTime
    mtrRequire(_MTRColorControlClusterMoveToColorTemperatureParams.description.contains("MTRColorControlClusterMoveToColorTemperatureParams"), "MTRColorControlClusterMoveToColorTemperatureParams desc")
    let _MTRColorControlClusterMoveToHueAndSaturationParams = MTRColorControlClusterMoveToHueAndSaturationParams()
    _MTRColorControlClusterMoveToHueAndSaturationParams.hue = n(1)
    _ = _MTRColorControlClusterMoveToHueAndSaturationParams.hue
    _MTRColorControlClusterMoveToHueAndSaturationParams.optionsMask = n(1)
    _ = _MTRColorControlClusterMoveToHueAndSaturationParams.optionsMask
    _MTRColorControlClusterMoveToHueAndSaturationParams.optionsOverride = n(1)
    _ = _MTRColorControlClusterMoveToHueAndSaturationParams.optionsOverride
    _MTRColorControlClusterMoveToHueAndSaturationParams.saturation = n(1)
    _ = _MTRColorControlClusterMoveToHueAndSaturationParams.saturation
    _MTRColorControlClusterMoveToHueAndSaturationParams.serverSideProcessingTimeout = n(1)
    _ = _MTRColorControlClusterMoveToHueAndSaturationParams.serverSideProcessingTimeout
    _MTRColorControlClusterMoveToHueAndSaturationParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRColorControlClusterMoveToHueAndSaturationParams.timedInvokeTimeoutMs
    _MTRColorControlClusterMoveToHueAndSaturationParams.transitionTime = n(1)
    _ = _MTRColorControlClusterMoveToHueAndSaturationParams.transitionTime
    mtrRequire(_MTRColorControlClusterMoveToHueAndSaturationParams.description.contains("MTRColorControlClusterMoveToHueAndSaturationParams"), "MTRColorControlClusterMoveToHueAndSaturationParams desc")
    let _MTRColorControlClusterMoveToHueParams = MTRColorControlClusterMoveToHueParams()
    _MTRColorControlClusterMoveToHueParams.direction = n(1)
    _ = _MTRColorControlClusterMoveToHueParams.direction
    _MTRColorControlClusterMoveToHueParams.hue = n(1)
    _ = _MTRColorControlClusterMoveToHueParams.hue
    _MTRColorControlClusterMoveToHueParams.optionsMask = n(1)
    _ = _MTRColorControlClusterMoveToHueParams.optionsMask
    _MTRColorControlClusterMoveToHueParams.optionsOverride = n(1)
    _ = _MTRColorControlClusterMoveToHueParams.optionsOverride
    _MTRColorControlClusterMoveToHueParams.serverSideProcessingTimeout = n(1)
    _ = _MTRColorControlClusterMoveToHueParams.serverSideProcessingTimeout
    _MTRColorControlClusterMoveToHueParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRColorControlClusterMoveToHueParams.timedInvokeTimeoutMs
    _MTRColorControlClusterMoveToHueParams.transitionTime = n(1)
    _ = _MTRColorControlClusterMoveToHueParams.transitionTime
    mtrRequire(_MTRColorControlClusterMoveToHueParams.description.contains("MTRColorControlClusterMoveToHueParams"), "MTRColorControlClusterMoveToHueParams desc")
    let _MTRColorControlClusterMoveToSaturationParams = MTRColorControlClusterMoveToSaturationParams()
    _MTRColorControlClusterMoveToSaturationParams.optionsMask = n(1)
    _ = _MTRColorControlClusterMoveToSaturationParams.optionsMask
    _MTRColorControlClusterMoveToSaturationParams.optionsOverride = n(1)
    _ = _MTRColorControlClusterMoveToSaturationParams.optionsOverride
    _MTRColorControlClusterMoveToSaturationParams.saturation = n(1)
    _ = _MTRColorControlClusterMoveToSaturationParams.saturation
    _MTRColorControlClusterMoveToSaturationParams.serverSideProcessingTimeout = n(1)
    _ = _MTRColorControlClusterMoveToSaturationParams.serverSideProcessingTimeout
    _MTRColorControlClusterMoveToSaturationParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRColorControlClusterMoveToSaturationParams.timedInvokeTimeoutMs
    _MTRColorControlClusterMoveToSaturationParams.transitionTime = n(1)
    _ = _MTRColorControlClusterMoveToSaturationParams.transitionTime
    mtrRequire(_MTRColorControlClusterMoveToSaturationParams.description.contains("MTRColorControlClusterMoveToSaturationParams"), "MTRColorControlClusterMoveToSaturationParams desc")
    let _MTRColorControlClusterStepColorParams = MTRColorControlClusterStepColorParams()
    _MTRColorControlClusterStepColorParams.optionsMask = n(1)
    _ = _MTRColorControlClusterStepColorParams.optionsMask
    _MTRColorControlClusterStepColorParams.optionsOverride = n(1)
    _ = _MTRColorControlClusterStepColorParams.optionsOverride
    _MTRColorControlClusterStepColorParams.serverSideProcessingTimeout = n(1)
    _ = _MTRColorControlClusterStepColorParams.serverSideProcessingTimeout
    _MTRColorControlClusterStepColorParams.stepX = n(1)
    _ = _MTRColorControlClusterStepColorParams.stepX
    _MTRColorControlClusterStepColorParams.stepY = n(1)
    _ = _MTRColorControlClusterStepColorParams.stepY
    _MTRColorControlClusterStepColorParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRColorControlClusterStepColorParams.timedInvokeTimeoutMs
    _MTRColorControlClusterStepColorParams.transitionTime = n(1)
    _ = _MTRColorControlClusterStepColorParams.transitionTime
    mtrRequire(_MTRColorControlClusterStepColorParams.description.contains("MTRColorControlClusterStepColorParams"), "MTRColorControlClusterStepColorParams desc")
    let _MTRColorControlClusterStepColorTemperatureParams = MTRColorControlClusterStepColorTemperatureParams()
    _MTRColorControlClusterStepColorTemperatureParams.colorTemperatureMaximumMireds = n(1)
    _ = _MTRColorControlClusterStepColorTemperatureParams.colorTemperatureMaximumMireds
    _MTRColorControlClusterStepColorTemperatureParams.colorTemperatureMinimumMireds = n(1)
    _ = _MTRColorControlClusterStepColorTemperatureParams.colorTemperatureMinimumMireds
    _MTRColorControlClusterStepColorTemperatureParams.optionsMask = n(1)
    _ = _MTRColorControlClusterStepColorTemperatureParams.optionsMask
    _MTRColorControlClusterStepColorTemperatureParams.optionsOverride = n(1)
    _ = _MTRColorControlClusterStepColorTemperatureParams.optionsOverride
    _MTRColorControlClusterStepColorTemperatureParams.serverSideProcessingTimeout = n(1)
    _ = _MTRColorControlClusterStepColorTemperatureParams.serverSideProcessingTimeout
    _MTRColorControlClusterStepColorTemperatureParams.stepMode = n(1)
    _ = _MTRColorControlClusterStepColorTemperatureParams.stepMode
    _MTRColorControlClusterStepColorTemperatureParams.stepSize = n(1)
    _ = _MTRColorControlClusterStepColorTemperatureParams.stepSize
    _MTRColorControlClusterStepColorTemperatureParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRColorControlClusterStepColorTemperatureParams.timedInvokeTimeoutMs
    _MTRColorControlClusterStepColorTemperatureParams.transitionTime = n(1)
    _ = _MTRColorControlClusterStepColorTemperatureParams.transitionTime
    mtrRequire(_MTRColorControlClusterStepColorTemperatureParams.description.contains("MTRColorControlClusterStepColorTemperatureParams"), "MTRColorControlClusterStepColorTemperatureParams desc")
    let _MTRColorControlClusterStepHueParams = MTRColorControlClusterStepHueParams()
    _MTRColorControlClusterStepHueParams.optionsMask = n(1)
    _ = _MTRColorControlClusterStepHueParams.optionsMask
    _MTRColorControlClusterStepHueParams.optionsOverride = n(1)
    _ = _MTRColorControlClusterStepHueParams.optionsOverride
    _MTRColorControlClusterStepHueParams.serverSideProcessingTimeout = n(1)
    _ = _MTRColorControlClusterStepHueParams.serverSideProcessingTimeout
    _MTRColorControlClusterStepHueParams.stepMode = n(1)
    _ = _MTRColorControlClusterStepHueParams.stepMode
    _MTRColorControlClusterStepHueParams.stepSize = n(1)
    _ = _MTRColorControlClusterStepHueParams.stepSize
    _MTRColorControlClusterStepHueParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRColorControlClusterStepHueParams.timedInvokeTimeoutMs
    _MTRColorControlClusterStepHueParams.transitionTime = n(1)
    _ = _MTRColorControlClusterStepHueParams.transitionTime
    mtrRequire(_MTRColorControlClusterStepHueParams.description.contains("MTRColorControlClusterStepHueParams"), "MTRColorControlClusterStepHueParams desc")
    let _MTRColorControlClusterStepSaturationParams = MTRColorControlClusterStepSaturationParams()
    _MTRColorControlClusterStepSaturationParams.optionsMask = n(1)
    _ = _MTRColorControlClusterStepSaturationParams.optionsMask
    _MTRColorControlClusterStepSaturationParams.optionsOverride = n(1)
    _ = _MTRColorControlClusterStepSaturationParams.optionsOverride
    _MTRColorControlClusterStepSaturationParams.serverSideProcessingTimeout = n(1)
    _ = _MTRColorControlClusterStepSaturationParams.serverSideProcessingTimeout
    _MTRColorControlClusterStepSaturationParams.stepMode = n(1)
    _ = _MTRColorControlClusterStepSaturationParams.stepMode
    _MTRColorControlClusterStepSaturationParams.stepSize = n(1)
    _ = _MTRColorControlClusterStepSaturationParams.stepSize
    _MTRColorControlClusterStepSaturationParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRColorControlClusterStepSaturationParams.timedInvokeTimeoutMs
    _MTRColorControlClusterStepSaturationParams.transitionTime = n(1)
    _ = _MTRColorControlClusterStepSaturationParams.transitionTime
    mtrRequire(_MTRColorControlClusterStepSaturationParams.description.contains("MTRColorControlClusterStepSaturationParams"), "MTRColorControlClusterStepSaturationParams desc")
    let _MTRColorControlClusterStopMoveStepParams = MTRColorControlClusterStopMoveStepParams()
    _MTRColorControlClusterStopMoveStepParams.optionsMask = n(1)
    _ = _MTRColorControlClusterStopMoveStepParams.optionsMask
    _MTRColorControlClusterStopMoveStepParams.optionsOverride = n(1)
    _ = _MTRColorControlClusterStopMoveStepParams.optionsOverride
    _MTRColorControlClusterStopMoveStepParams.serverSideProcessingTimeout = n(1)
    _ = _MTRColorControlClusterStopMoveStepParams.serverSideProcessingTimeout
    _MTRColorControlClusterStopMoveStepParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRColorControlClusterStopMoveStepParams.timedInvokeTimeoutMs
    mtrRequire(_MTRColorControlClusterStopMoveStepParams.description.contains("MTRColorControlClusterStopMoveStepParams"), "MTRColorControlClusterStopMoveStepParams desc")
}

func testDoorLockParamsGroup1() {
    let _MTRDoorLockClusterClearAliroReaderConfigParams = MTRDoorLockClusterClearAliroReaderConfigParams()
    _MTRDoorLockClusterClearAliroReaderConfigParams.serverSideProcessingTimeout = n(1)
    _ = _MTRDoorLockClusterClearAliroReaderConfigParams.serverSideProcessingTimeout
    _MTRDoorLockClusterClearAliroReaderConfigParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRDoorLockClusterClearAliroReaderConfigParams.timedInvokeTimeoutMs
    mtrRequire(_MTRDoorLockClusterClearAliroReaderConfigParams.description.contains("MTRDoorLockClusterClearAliroReaderConfigParams"), "MTRDoorLockClusterClearAliroReaderConfigParams desc")
    let _MTRDoorLockClusterClearCredentialParams = MTRDoorLockClusterClearCredentialParams()
    _MTRDoorLockClusterClearCredentialParams.credential = MTRDoorLockClusterCredentialStruct()
    _ = _MTRDoorLockClusterClearCredentialParams.credential
    _MTRDoorLockClusterClearCredentialParams.serverSideProcessingTimeout = n(1)
    _ = _MTRDoorLockClusterClearCredentialParams.serverSideProcessingTimeout
    _MTRDoorLockClusterClearCredentialParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRDoorLockClusterClearCredentialParams.timedInvokeTimeoutMs
    mtrRequire(_MTRDoorLockClusterClearCredentialParams.description.contains("MTRDoorLockClusterClearCredentialParams"), "MTRDoorLockClusterClearCredentialParams desc")
    let _MTRDoorLockClusterClearHolidayScheduleParams = MTRDoorLockClusterClearHolidayScheduleParams()
    _MTRDoorLockClusterClearHolidayScheduleParams.holidayIndex = n(1)
    _ = _MTRDoorLockClusterClearHolidayScheduleParams.holidayIndex
    _MTRDoorLockClusterClearHolidayScheduleParams.serverSideProcessingTimeout = n(1)
    _ = _MTRDoorLockClusterClearHolidayScheduleParams.serverSideProcessingTimeout
    _MTRDoorLockClusterClearHolidayScheduleParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRDoorLockClusterClearHolidayScheduleParams.timedInvokeTimeoutMs
    mtrRequire(_MTRDoorLockClusterClearHolidayScheduleParams.description.contains("MTRDoorLockClusterClearHolidayScheduleParams"), "MTRDoorLockClusterClearHolidayScheduleParams desc")
    let _MTRDoorLockClusterClearUserParams = MTRDoorLockClusterClearUserParams()
    _MTRDoorLockClusterClearUserParams.serverSideProcessingTimeout = n(1)
    _ = _MTRDoorLockClusterClearUserParams.serverSideProcessingTimeout
    _MTRDoorLockClusterClearUserParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRDoorLockClusterClearUserParams.timedInvokeTimeoutMs
    _MTRDoorLockClusterClearUserParams.userIndex = n(1)
    _ = _MTRDoorLockClusterClearUserParams.userIndex
    mtrRequire(_MTRDoorLockClusterClearUserParams.description.contains("MTRDoorLockClusterClearUserParams"), "MTRDoorLockClusterClearUserParams desc")
    let _MTRDoorLockClusterClearWeekDayScheduleParams = MTRDoorLockClusterClearWeekDayScheduleParams()
    _MTRDoorLockClusterClearWeekDayScheduleParams.serverSideProcessingTimeout = n(1)
    _ = _MTRDoorLockClusterClearWeekDayScheduleParams.serverSideProcessingTimeout
    _MTRDoorLockClusterClearWeekDayScheduleParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRDoorLockClusterClearWeekDayScheduleParams.timedInvokeTimeoutMs
    _MTRDoorLockClusterClearWeekDayScheduleParams.userIndex = n(1)
    _ = _MTRDoorLockClusterClearWeekDayScheduleParams.userIndex
    _MTRDoorLockClusterClearWeekDayScheduleParams.weekDayIndex = n(1)
    _ = _MTRDoorLockClusterClearWeekDayScheduleParams.weekDayIndex
    mtrRequire(_MTRDoorLockClusterClearWeekDayScheduleParams.description.contains("MTRDoorLockClusterClearWeekDayScheduleParams"), "MTRDoorLockClusterClearWeekDayScheduleParams desc")
    let _MTRDoorLockClusterClearYearDayScheduleParams = MTRDoorLockClusterClearYearDayScheduleParams()
    _MTRDoorLockClusterClearYearDayScheduleParams.serverSideProcessingTimeout = n(1)
    _ = _MTRDoorLockClusterClearYearDayScheduleParams.serverSideProcessingTimeout
    _MTRDoorLockClusterClearYearDayScheduleParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRDoorLockClusterClearYearDayScheduleParams.timedInvokeTimeoutMs
    _MTRDoorLockClusterClearYearDayScheduleParams.userIndex = n(1)
    _ = _MTRDoorLockClusterClearYearDayScheduleParams.userIndex
    _MTRDoorLockClusterClearYearDayScheduleParams.yearDayIndex = n(1)
    _ = _MTRDoorLockClusterClearYearDayScheduleParams.yearDayIndex
    mtrRequire(_MTRDoorLockClusterClearYearDayScheduleParams.description.contains("MTRDoorLockClusterClearYearDayScheduleParams"), "MTRDoorLockClusterClearYearDayScheduleParams desc")
    let _MTRDoorLockClusterCredentialStruct = MTRDoorLockClusterCredentialStruct()
    _MTRDoorLockClusterCredentialStruct.credentialIndex = n(1)
    _ = _MTRDoorLockClusterCredentialStruct.credentialIndex
    _MTRDoorLockClusterCredentialStruct.credentialType = n(1)
    _ = _MTRDoorLockClusterCredentialStruct.credentialType
    mtrRequire(_MTRDoorLockClusterCredentialStruct.description.contains("MTRDoorLockClusterCredentialStruct"), "MTRDoorLockClusterCredentialStruct desc")
    let _MTRDoorLockClusterDlCredential = MTRDoorLockClusterDlCredential()
    _MTRDoorLockClusterDlCredential.credentialIndex = n(1)
    _ = _MTRDoorLockClusterDlCredential.credentialIndex
    _MTRDoorLockClusterDlCredential.credentialType = n(1)
    _ = _MTRDoorLockClusterDlCredential.credentialType
    mtrRequire(_MTRDoorLockClusterDlCredential.description.contains("MTRDoorLockClusterDlCredential"), "MTRDoorLockClusterDlCredential desc")
    let _MTRDoorLockClusterDoorLockAlarmEvent = MTRDoorLockClusterDoorLockAlarmEvent()
    _MTRDoorLockClusterDoorLockAlarmEvent.alarmCode = n(1)
    _ = _MTRDoorLockClusterDoorLockAlarmEvent.alarmCode
    mtrRequire(_MTRDoorLockClusterDoorLockAlarmEvent.description.contains("MTRDoorLockClusterDoorLockAlarmEvent"), "MTRDoorLockClusterDoorLockAlarmEvent desc")
    let _MTRDoorLockClusterDoorStateChangeEvent = MTRDoorLockClusterDoorStateChangeEvent()
    _MTRDoorLockClusterDoorStateChangeEvent.doorState = n(1)
    _ = _MTRDoorLockClusterDoorStateChangeEvent.doorState
    mtrRequire(_MTRDoorLockClusterDoorStateChangeEvent.description.contains("MTRDoorLockClusterDoorStateChangeEvent"), "MTRDoorLockClusterDoorStateChangeEvent desc")
    let _MTRDoorLockClusterGetCredentialStatusParams = MTRDoorLockClusterGetCredentialStatusParams()
    _MTRDoorLockClusterGetCredentialStatusParams.credential = MTRDoorLockClusterCredentialStruct()
    _ = _MTRDoorLockClusterGetCredentialStatusParams.credential
    _MTRDoorLockClusterGetCredentialStatusParams.serverSideProcessingTimeout = n(1)
    _ = _MTRDoorLockClusterGetCredentialStatusParams.serverSideProcessingTimeout
    _MTRDoorLockClusterGetCredentialStatusParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRDoorLockClusterGetCredentialStatusParams.timedInvokeTimeoutMs
    mtrRequire(_MTRDoorLockClusterGetCredentialStatusParams.description.contains("MTRDoorLockClusterGetCredentialStatusParams"), "MTRDoorLockClusterGetCredentialStatusParams desc")
    let _MTRDoorLockClusterGetCredentialStatusResponseParams = (try? MTRDoorLockClusterGetCredentialStatusResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRDoorLockClusterGetCredentialStatusResponseParams()
    _MTRDoorLockClusterGetCredentialStatusResponseParams.creatorFabricIndex = n(1)
    _ = _MTRDoorLockClusterGetCredentialStatusResponseParams.creatorFabricIndex
    _MTRDoorLockClusterGetCredentialStatusResponseParams.credentialData = Data([1])
    _ = _MTRDoorLockClusterGetCredentialStatusResponseParams.credentialData
    _MTRDoorLockClusterGetCredentialStatusResponseParams.credentialExists = n(1)
    _ = _MTRDoorLockClusterGetCredentialStatusResponseParams.credentialExists
    _MTRDoorLockClusterGetCredentialStatusResponseParams.lastModifiedFabricIndex = n(1)
    _ = _MTRDoorLockClusterGetCredentialStatusResponseParams.lastModifiedFabricIndex
    _MTRDoorLockClusterGetCredentialStatusResponseParams.nextCredentialIndex = n(1)
    _ = _MTRDoorLockClusterGetCredentialStatusResponseParams.nextCredentialIndex
    _MTRDoorLockClusterGetCredentialStatusResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRDoorLockClusterGetCredentialStatusResponseParams.timedInvokeTimeoutMs
    _MTRDoorLockClusterGetCredentialStatusResponseParams.userIndex = n(1)
    _ = _MTRDoorLockClusterGetCredentialStatusResponseParams.userIndex
    mtrRequire(_MTRDoorLockClusterGetCredentialStatusResponseParams.description.contains("MTRDoorLockClusterGetCredentialStatusResponseParams"), "MTRDoorLockClusterGetCredentialStatusResponseParams desc")
    let _MTRDoorLockClusterGetHolidayScheduleParams = MTRDoorLockClusterGetHolidayScheduleParams()
    _MTRDoorLockClusterGetHolidayScheduleParams.holidayIndex = n(1)
    _ = _MTRDoorLockClusterGetHolidayScheduleParams.holidayIndex
    _MTRDoorLockClusterGetHolidayScheduleParams.serverSideProcessingTimeout = n(1)
    _ = _MTRDoorLockClusterGetHolidayScheduleParams.serverSideProcessingTimeout
    _MTRDoorLockClusterGetHolidayScheduleParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRDoorLockClusterGetHolidayScheduleParams.timedInvokeTimeoutMs
    mtrRequire(_MTRDoorLockClusterGetHolidayScheduleParams.description.contains("MTRDoorLockClusterGetHolidayScheduleParams"), "MTRDoorLockClusterGetHolidayScheduleParams desc")
    let _MTRDoorLockClusterGetHolidayScheduleResponseParams = (try? MTRDoorLockClusterGetHolidayScheduleResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRDoorLockClusterGetHolidayScheduleResponseParams()
    _MTRDoorLockClusterGetHolidayScheduleResponseParams.holidayIndex = n(1)
    _ = _MTRDoorLockClusterGetHolidayScheduleResponseParams.holidayIndex
    _MTRDoorLockClusterGetHolidayScheduleResponseParams.localEndTime = n(1)
    _ = _MTRDoorLockClusterGetHolidayScheduleResponseParams.localEndTime
    _MTRDoorLockClusterGetHolidayScheduleResponseParams.localStartTime = n(1)
    _ = _MTRDoorLockClusterGetHolidayScheduleResponseParams.localStartTime
    _MTRDoorLockClusterGetHolidayScheduleResponseParams.operatingMode = n(1)
    _ = _MTRDoorLockClusterGetHolidayScheduleResponseParams.operatingMode
    _MTRDoorLockClusterGetHolidayScheduleResponseParams.status = n(1)
    _ = _MTRDoorLockClusterGetHolidayScheduleResponseParams.status
    _MTRDoorLockClusterGetHolidayScheduleResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRDoorLockClusterGetHolidayScheduleResponseParams.timedInvokeTimeoutMs
    mtrRequire(_MTRDoorLockClusterGetHolidayScheduleResponseParams.description.contains("MTRDoorLockClusterGetHolidayScheduleResponseParams"), "MTRDoorLockClusterGetHolidayScheduleResponseParams desc")
    let _MTRDoorLockClusterGetUserParams = MTRDoorLockClusterGetUserParams()
    _MTRDoorLockClusterGetUserParams.serverSideProcessingTimeout = n(1)
    _ = _MTRDoorLockClusterGetUserParams.serverSideProcessingTimeout
    _MTRDoorLockClusterGetUserParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRDoorLockClusterGetUserParams.timedInvokeTimeoutMs
    _MTRDoorLockClusterGetUserParams.userIndex = n(1)
    _ = _MTRDoorLockClusterGetUserParams.userIndex
    mtrRequire(_MTRDoorLockClusterGetUserParams.description.contains("MTRDoorLockClusterGetUserParams"), "MTRDoorLockClusterGetUserParams desc")
    let _MTRDoorLockClusterGetUserResponseParams = (try? MTRDoorLockClusterGetUserResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRDoorLockClusterGetUserResponseParams()
    _MTRDoorLockClusterGetUserResponseParams.creatorFabricIndex = n(1)
    _ = _MTRDoorLockClusterGetUserResponseParams.creatorFabricIndex
    _MTRDoorLockClusterGetUserResponseParams.credentialRule = n(1)
    _ = _MTRDoorLockClusterGetUserResponseParams.credentialRule
    _MTRDoorLockClusterGetUserResponseParams.credentials = [n(1)] as [Any]
    _ = _MTRDoorLockClusterGetUserResponseParams.credentials
    _MTRDoorLockClusterGetUserResponseParams.lastModifiedFabricIndex = n(1)
    _ = _MTRDoorLockClusterGetUserResponseParams.lastModifiedFabricIndex
    _MTRDoorLockClusterGetUserResponseParams.nextUserIndex = n(1)
    _ = _MTRDoorLockClusterGetUserResponseParams.nextUserIndex
    _MTRDoorLockClusterGetUserResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRDoorLockClusterGetUserResponseParams.timedInvokeTimeoutMs
    _MTRDoorLockClusterGetUserResponseParams.userIndex = n(1)
    _ = _MTRDoorLockClusterGetUserResponseParams.userIndex
    _MTRDoorLockClusterGetUserResponseParams.userName = "x"
    _ = _MTRDoorLockClusterGetUserResponseParams.userName
    _MTRDoorLockClusterGetUserResponseParams.userStatus = n(1)
    _ = _MTRDoorLockClusterGetUserResponseParams.userStatus
    _MTRDoorLockClusterGetUserResponseParams.userType = n(1)
    _ = _MTRDoorLockClusterGetUserResponseParams.userType
    _MTRDoorLockClusterGetUserResponseParams.userUniqueID = n(1)
    _ = _MTRDoorLockClusterGetUserResponseParams.userUniqueID
    _MTRDoorLockClusterGetUserResponseParams.userUniqueId = n(1)
    _ = _MTRDoorLockClusterGetUserResponseParams.userUniqueId
    mtrRequire(_MTRDoorLockClusterGetUserResponseParams.description.contains("MTRDoorLockClusterGetUserResponseParams"), "MTRDoorLockClusterGetUserResponseParams desc")
    let _MTRDoorLockClusterGetWeekDayScheduleParams = MTRDoorLockClusterGetWeekDayScheduleParams()
    _MTRDoorLockClusterGetWeekDayScheduleParams.serverSideProcessingTimeout = n(1)
    _ = _MTRDoorLockClusterGetWeekDayScheduleParams.serverSideProcessingTimeout
    _MTRDoorLockClusterGetWeekDayScheduleParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRDoorLockClusterGetWeekDayScheduleParams.timedInvokeTimeoutMs
    _MTRDoorLockClusterGetWeekDayScheduleParams.userIndex = n(1)
    _ = _MTRDoorLockClusterGetWeekDayScheduleParams.userIndex
    _MTRDoorLockClusterGetWeekDayScheduleParams.weekDayIndex = n(1)
    _ = _MTRDoorLockClusterGetWeekDayScheduleParams.weekDayIndex
    mtrRequire(_MTRDoorLockClusterGetWeekDayScheduleParams.description.contains("MTRDoorLockClusterGetWeekDayScheduleParams"), "MTRDoorLockClusterGetWeekDayScheduleParams desc")
    let _MTRDoorLockClusterGetWeekDayScheduleResponseParams = (try? MTRDoorLockClusterGetWeekDayScheduleResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRDoorLockClusterGetWeekDayScheduleResponseParams()
    _MTRDoorLockClusterGetWeekDayScheduleResponseParams.daysMask = n(1)
    _ = _MTRDoorLockClusterGetWeekDayScheduleResponseParams.daysMask
    _MTRDoorLockClusterGetWeekDayScheduleResponseParams.endHour = n(1)
    _ = _MTRDoorLockClusterGetWeekDayScheduleResponseParams.endHour
    _MTRDoorLockClusterGetWeekDayScheduleResponseParams.endMinute = n(1)
    _ = _MTRDoorLockClusterGetWeekDayScheduleResponseParams.endMinute
    _MTRDoorLockClusterGetWeekDayScheduleResponseParams.startHour = n(1)
    _ = _MTRDoorLockClusterGetWeekDayScheduleResponseParams.startHour
    _MTRDoorLockClusterGetWeekDayScheduleResponseParams.startMinute = n(1)
    _ = _MTRDoorLockClusterGetWeekDayScheduleResponseParams.startMinute
    _MTRDoorLockClusterGetWeekDayScheduleResponseParams.status = n(1)
    _ = _MTRDoorLockClusterGetWeekDayScheduleResponseParams.status
    _MTRDoorLockClusterGetWeekDayScheduleResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRDoorLockClusterGetWeekDayScheduleResponseParams.timedInvokeTimeoutMs
    _MTRDoorLockClusterGetWeekDayScheduleResponseParams.userIndex = n(1)
    _ = _MTRDoorLockClusterGetWeekDayScheduleResponseParams.userIndex
    _MTRDoorLockClusterGetWeekDayScheduleResponseParams.weekDayIndex = n(1)
    _ = _MTRDoorLockClusterGetWeekDayScheduleResponseParams.weekDayIndex
    mtrRequire(_MTRDoorLockClusterGetWeekDayScheduleResponseParams.description.contains("MTRDoorLockClusterGetWeekDayScheduleResponseParams"), "MTRDoorLockClusterGetWeekDayScheduleResponseParams desc")
    let _MTRDoorLockClusterGetYearDayScheduleParams = MTRDoorLockClusterGetYearDayScheduleParams()
    _MTRDoorLockClusterGetYearDayScheduleParams.serverSideProcessingTimeout = n(1)
    _ = _MTRDoorLockClusterGetYearDayScheduleParams.serverSideProcessingTimeout
    _MTRDoorLockClusterGetYearDayScheduleParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRDoorLockClusterGetYearDayScheduleParams.timedInvokeTimeoutMs
    _MTRDoorLockClusterGetYearDayScheduleParams.userIndex = n(1)
    _ = _MTRDoorLockClusterGetYearDayScheduleParams.userIndex
    _MTRDoorLockClusterGetYearDayScheduleParams.yearDayIndex = n(1)
    _ = _MTRDoorLockClusterGetYearDayScheduleParams.yearDayIndex
    mtrRequire(_MTRDoorLockClusterGetYearDayScheduleParams.description.contains("MTRDoorLockClusterGetYearDayScheduleParams"), "MTRDoorLockClusterGetYearDayScheduleParams desc")
    let _MTRDoorLockClusterGetYearDayScheduleResponseParams = (try? MTRDoorLockClusterGetYearDayScheduleResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRDoorLockClusterGetYearDayScheduleResponseParams()
    _MTRDoorLockClusterGetYearDayScheduleResponseParams.localEndTime = n(1)
    _ = _MTRDoorLockClusterGetYearDayScheduleResponseParams.localEndTime
    _MTRDoorLockClusterGetYearDayScheduleResponseParams.localStartTime = n(1)
    _ = _MTRDoorLockClusterGetYearDayScheduleResponseParams.localStartTime
    _MTRDoorLockClusterGetYearDayScheduleResponseParams.status = n(1)
    _ = _MTRDoorLockClusterGetYearDayScheduleResponseParams.status
    _MTRDoorLockClusterGetYearDayScheduleResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRDoorLockClusterGetYearDayScheduleResponseParams.timedInvokeTimeoutMs
    _MTRDoorLockClusterGetYearDayScheduleResponseParams.userIndex = n(1)
    _ = _MTRDoorLockClusterGetYearDayScheduleResponseParams.userIndex
    _MTRDoorLockClusterGetYearDayScheduleResponseParams.yearDayIndex = n(1)
    _ = _MTRDoorLockClusterGetYearDayScheduleResponseParams.yearDayIndex
    mtrRequire(_MTRDoorLockClusterGetYearDayScheduleResponseParams.description.contains("MTRDoorLockClusterGetYearDayScheduleResponseParams"), "MTRDoorLockClusterGetYearDayScheduleResponseParams desc")
    let _MTRDoorLockClusterLockDoorParams = MTRDoorLockClusterLockDoorParams()
    _MTRDoorLockClusterLockDoorParams.pinCode = Data([1])
    _ = _MTRDoorLockClusterLockDoorParams.pinCode
    _MTRDoorLockClusterLockDoorParams.serverSideProcessingTimeout = n(1)
    _ = _MTRDoorLockClusterLockDoorParams.serverSideProcessingTimeout
    _MTRDoorLockClusterLockDoorParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRDoorLockClusterLockDoorParams.timedInvokeTimeoutMs
    mtrRequire(_MTRDoorLockClusterLockDoorParams.description.contains("MTRDoorLockClusterLockDoorParams"), "MTRDoorLockClusterLockDoorParams desc")
    let _MTRDoorLockClusterLockOperationErrorEvent = MTRDoorLockClusterLockOperationErrorEvent()
    _MTRDoorLockClusterLockOperationErrorEvent.credentials = [n(1)] as [Any]
    _ = _MTRDoorLockClusterLockOperationErrorEvent.credentials
    _MTRDoorLockClusterLockOperationErrorEvent.fabricIndex = n(1)
    _ = _MTRDoorLockClusterLockOperationErrorEvent.fabricIndex
    _MTRDoorLockClusterLockOperationErrorEvent.lockOperationType = n(1)
    _ = _MTRDoorLockClusterLockOperationErrorEvent.lockOperationType
    _MTRDoorLockClusterLockOperationErrorEvent.operationError = n(1)
    _ = _MTRDoorLockClusterLockOperationErrorEvent.operationError
    _MTRDoorLockClusterLockOperationErrorEvent.operationSource = n(1)
    _ = _MTRDoorLockClusterLockOperationErrorEvent.operationSource
    _MTRDoorLockClusterLockOperationErrorEvent.sourceNode = n(1)
    _ = _MTRDoorLockClusterLockOperationErrorEvent.sourceNode
    _MTRDoorLockClusterLockOperationErrorEvent.userIndex = n(1)
    _ = _MTRDoorLockClusterLockOperationErrorEvent.userIndex
    mtrRequire(_MTRDoorLockClusterLockOperationErrorEvent.description.contains("MTRDoorLockClusterLockOperationErrorEvent"), "MTRDoorLockClusterLockOperationErrorEvent desc")
    let _MTRDoorLockClusterLockOperationEvent = MTRDoorLockClusterLockOperationEvent()
    _MTRDoorLockClusterLockOperationEvent.credentials = [n(1)] as [Any]
    _ = _MTRDoorLockClusterLockOperationEvent.credentials
    _MTRDoorLockClusterLockOperationEvent.fabricIndex = n(1)
    _ = _MTRDoorLockClusterLockOperationEvent.fabricIndex
    _MTRDoorLockClusterLockOperationEvent.lockOperationType = n(1)
    _ = _MTRDoorLockClusterLockOperationEvent.lockOperationType
    _MTRDoorLockClusterLockOperationEvent.operationSource = n(1)
    _ = _MTRDoorLockClusterLockOperationEvent.operationSource
    _MTRDoorLockClusterLockOperationEvent.sourceNode = n(1)
    _ = _MTRDoorLockClusterLockOperationEvent.sourceNode
    _MTRDoorLockClusterLockOperationEvent.userIndex = n(1)
    _ = _MTRDoorLockClusterLockOperationEvent.userIndex
    mtrRequire(_MTRDoorLockClusterLockOperationEvent.description.contains("MTRDoorLockClusterLockOperationEvent"), "MTRDoorLockClusterLockOperationEvent desc")
    let _MTRDoorLockClusterLockUserChangeEvent = MTRDoorLockClusterLockUserChangeEvent()
    _MTRDoorLockClusterLockUserChangeEvent.dataIndex = n(1)
    _ = _MTRDoorLockClusterLockUserChangeEvent.dataIndex
    _MTRDoorLockClusterLockUserChangeEvent.dataOperationType = n(1)
    _ = _MTRDoorLockClusterLockUserChangeEvent.dataOperationType
    _MTRDoorLockClusterLockUserChangeEvent.fabricIndex = n(1)
    _ = _MTRDoorLockClusterLockUserChangeEvent.fabricIndex
    _MTRDoorLockClusterLockUserChangeEvent.lockDataType = n(1)
    _ = _MTRDoorLockClusterLockUserChangeEvent.lockDataType
    _MTRDoorLockClusterLockUserChangeEvent.operationSource = n(1)
    _ = _MTRDoorLockClusterLockUserChangeEvent.operationSource
    _MTRDoorLockClusterLockUserChangeEvent.sourceNode = n(1)
    _ = _MTRDoorLockClusterLockUserChangeEvent.sourceNode
    _MTRDoorLockClusterLockUserChangeEvent.userIndex = n(1)
    _ = _MTRDoorLockClusterLockUserChangeEvent.userIndex
    mtrRequire(_MTRDoorLockClusterLockUserChangeEvent.description.contains("MTRDoorLockClusterLockUserChangeEvent"), "MTRDoorLockClusterLockUserChangeEvent desc")
    let _MTRDoorLockClusterSetAliroReaderConfigParams = MTRDoorLockClusterSetAliroReaderConfigParams()
    _MTRDoorLockClusterSetAliroReaderConfigParams.groupIdentifier = Data([1])
    _ = _MTRDoorLockClusterSetAliroReaderConfigParams.groupIdentifier
    _MTRDoorLockClusterSetAliroReaderConfigParams.groupResolvingKey = Data([1])
    _ = _MTRDoorLockClusterSetAliroReaderConfigParams.groupResolvingKey
    _MTRDoorLockClusterSetAliroReaderConfigParams.serverSideProcessingTimeout = n(1)
    _ = _MTRDoorLockClusterSetAliroReaderConfigParams.serverSideProcessingTimeout
    _MTRDoorLockClusterSetAliroReaderConfigParams.signingKey = Data([1])
    _ = _MTRDoorLockClusterSetAliroReaderConfigParams.signingKey
    _MTRDoorLockClusterSetAliroReaderConfigParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRDoorLockClusterSetAliroReaderConfigParams.timedInvokeTimeoutMs
    _MTRDoorLockClusterSetAliroReaderConfigParams.verificationKey = Data([1])
    _ = _MTRDoorLockClusterSetAliroReaderConfigParams.verificationKey
    mtrRequire(_MTRDoorLockClusterSetAliroReaderConfigParams.description.contains("MTRDoorLockClusterSetAliroReaderConfigParams"), "MTRDoorLockClusterSetAliroReaderConfigParams desc")
    let _MTRDoorLockClusterSetCredentialParams = MTRDoorLockClusterSetCredentialParams()
    _MTRDoorLockClusterSetCredentialParams.credential = MTRDoorLockClusterCredentialStruct()
    _ = _MTRDoorLockClusterSetCredentialParams.credential
    _MTRDoorLockClusterSetCredentialParams.credentialData = Data([1])
    _ = _MTRDoorLockClusterSetCredentialParams.credentialData
    _MTRDoorLockClusterSetCredentialParams.operationType = n(1)
    _ = _MTRDoorLockClusterSetCredentialParams.operationType
    _MTRDoorLockClusterSetCredentialParams.serverSideProcessingTimeout = n(1)
    _ = _MTRDoorLockClusterSetCredentialParams.serverSideProcessingTimeout
    _MTRDoorLockClusterSetCredentialParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRDoorLockClusterSetCredentialParams.timedInvokeTimeoutMs
    _MTRDoorLockClusterSetCredentialParams.userIndex = n(1)
    _ = _MTRDoorLockClusterSetCredentialParams.userIndex
    _MTRDoorLockClusterSetCredentialParams.userStatus = n(1)
    _ = _MTRDoorLockClusterSetCredentialParams.userStatus
    _MTRDoorLockClusterSetCredentialParams.userType = n(1)
    _ = _MTRDoorLockClusterSetCredentialParams.userType
    mtrRequire(_MTRDoorLockClusterSetCredentialParams.description.contains("MTRDoorLockClusterSetCredentialParams"), "MTRDoorLockClusterSetCredentialParams desc")
    let _MTRDoorLockClusterSetCredentialResponseParams = (try? MTRDoorLockClusterSetCredentialResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRDoorLockClusterSetCredentialResponseParams()
    _MTRDoorLockClusterSetCredentialResponseParams.nextCredentialIndex = n(1)
    _ = _MTRDoorLockClusterSetCredentialResponseParams.nextCredentialIndex
    _MTRDoorLockClusterSetCredentialResponseParams.status = n(1)
    _ = _MTRDoorLockClusterSetCredentialResponseParams.status
    _MTRDoorLockClusterSetCredentialResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRDoorLockClusterSetCredentialResponseParams.timedInvokeTimeoutMs
    _MTRDoorLockClusterSetCredentialResponseParams.userIndex = n(1)
    _ = _MTRDoorLockClusterSetCredentialResponseParams.userIndex
    mtrRequire(_MTRDoorLockClusterSetCredentialResponseParams.description.contains("MTRDoorLockClusterSetCredentialResponseParams"), "MTRDoorLockClusterSetCredentialResponseParams desc")
}

func testDoorLockParamsGroup2() {
    let _MTRDoorLockClusterSetHolidayScheduleParams = MTRDoorLockClusterSetHolidayScheduleParams()
    _MTRDoorLockClusterSetHolidayScheduleParams.holidayIndex = n(1)
    _ = _MTRDoorLockClusterSetHolidayScheduleParams.holidayIndex
    _MTRDoorLockClusterSetHolidayScheduleParams.localEndTime = n(1)
    _ = _MTRDoorLockClusterSetHolidayScheduleParams.localEndTime
    _MTRDoorLockClusterSetHolidayScheduleParams.localStartTime = n(1)
    _ = _MTRDoorLockClusterSetHolidayScheduleParams.localStartTime
    _MTRDoorLockClusterSetHolidayScheduleParams.operatingMode = n(1)
    _ = _MTRDoorLockClusterSetHolidayScheduleParams.operatingMode
    _MTRDoorLockClusterSetHolidayScheduleParams.serverSideProcessingTimeout = n(1)
    _ = _MTRDoorLockClusterSetHolidayScheduleParams.serverSideProcessingTimeout
    _MTRDoorLockClusterSetHolidayScheduleParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRDoorLockClusterSetHolidayScheduleParams.timedInvokeTimeoutMs
    mtrRequire(_MTRDoorLockClusterSetHolidayScheduleParams.description.contains("MTRDoorLockClusterSetHolidayScheduleParams"), "MTRDoorLockClusterSetHolidayScheduleParams desc")
    let _MTRDoorLockClusterSetUserParams = MTRDoorLockClusterSetUserParams()
    _MTRDoorLockClusterSetUserParams.credentialRule = n(1)
    _ = _MTRDoorLockClusterSetUserParams.credentialRule
    _MTRDoorLockClusterSetUserParams.operationType = n(1)
    _ = _MTRDoorLockClusterSetUserParams.operationType
    _MTRDoorLockClusterSetUserParams.serverSideProcessingTimeout = n(1)
    _ = _MTRDoorLockClusterSetUserParams.serverSideProcessingTimeout
    _MTRDoorLockClusterSetUserParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRDoorLockClusterSetUserParams.timedInvokeTimeoutMs
    _MTRDoorLockClusterSetUserParams.userIndex = n(1)
    _ = _MTRDoorLockClusterSetUserParams.userIndex
    _MTRDoorLockClusterSetUserParams.userName = "x"
    _ = _MTRDoorLockClusterSetUserParams.userName
    _MTRDoorLockClusterSetUserParams.userStatus = n(1)
    _ = _MTRDoorLockClusterSetUserParams.userStatus
    _MTRDoorLockClusterSetUserParams.userType = n(1)
    _ = _MTRDoorLockClusterSetUserParams.userType
    _MTRDoorLockClusterSetUserParams.userUniqueID = n(1)
    _ = _MTRDoorLockClusterSetUserParams.userUniqueID
    _MTRDoorLockClusterSetUserParams.userUniqueId = n(1)
    _ = _MTRDoorLockClusterSetUserParams.userUniqueId
    mtrRequire(_MTRDoorLockClusterSetUserParams.description.contains("MTRDoorLockClusterSetUserParams"), "MTRDoorLockClusterSetUserParams desc")
    let _MTRDoorLockClusterSetWeekDayScheduleParams = MTRDoorLockClusterSetWeekDayScheduleParams()
    _MTRDoorLockClusterSetWeekDayScheduleParams.daysMask = n(1)
    _ = _MTRDoorLockClusterSetWeekDayScheduleParams.daysMask
    _MTRDoorLockClusterSetWeekDayScheduleParams.endHour = n(1)
    _ = _MTRDoorLockClusterSetWeekDayScheduleParams.endHour
    _MTRDoorLockClusterSetWeekDayScheduleParams.endMinute = n(1)
    _ = _MTRDoorLockClusterSetWeekDayScheduleParams.endMinute
    _MTRDoorLockClusterSetWeekDayScheduleParams.serverSideProcessingTimeout = n(1)
    _ = _MTRDoorLockClusterSetWeekDayScheduleParams.serverSideProcessingTimeout
    _MTRDoorLockClusterSetWeekDayScheduleParams.startHour = n(1)
    _ = _MTRDoorLockClusterSetWeekDayScheduleParams.startHour
    _MTRDoorLockClusterSetWeekDayScheduleParams.startMinute = n(1)
    _ = _MTRDoorLockClusterSetWeekDayScheduleParams.startMinute
    _MTRDoorLockClusterSetWeekDayScheduleParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRDoorLockClusterSetWeekDayScheduleParams.timedInvokeTimeoutMs
    _MTRDoorLockClusterSetWeekDayScheduleParams.userIndex = n(1)
    _ = _MTRDoorLockClusterSetWeekDayScheduleParams.userIndex
    _MTRDoorLockClusterSetWeekDayScheduleParams.weekDayIndex = n(1)
    _ = _MTRDoorLockClusterSetWeekDayScheduleParams.weekDayIndex
    mtrRequire(_MTRDoorLockClusterSetWeekDayScheduleParams.description.contains("MTRDoorLockClusterSetWeekDayScheduleParams"), "MTRDoorLockClusterSetWeekDayScheduleParams desc")
    let _MTRDoorLockClusterSetYearDayScheduleParams = MTRDoorLockClusterSetYearDayScheduleParams()
    _MTRDoorLockClusterSetYearDayScheduleParams.localEndTime = n(1)
    _ = _MTRDoorLockClusterSetYearDayScheduleParams.localEndTime
    _MTRDoorLockClusterSetYearDayScheduleParams.localStartTime = n(1)
    _ = _MTRDoorLockClusterSetYearDayScheduleParams.localStartTime
    _MTRDoorLockClusterSetYearDayScheduleParams.serverSideProcessingTimeout = n(1)
    _ = _MTRDoorLockClusterSetYearDayScheduleParams.serverSideProcessingTimeout
    _MTRDoorLockClusterSetYearDayScheduleParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRDoorLockClusterSetYearDayScheduleParams.timedInvokeTimeoutMs
    _MTRDoorLockClusterSetYearDayScheduleParams.userIndex = n(1)
    _ = _MTRDoorLockClusterSetYearDayScheduleParams.userIndex
    _MTRDoorLockClusterSetYearDayScheduleParams.yearDayIndex = n(1)
    _ = _MTRDoorLockClusterSetYearDayScheduleParams.yearDayIndex
    mtrRequire(_MTRDoorLockClusterSetYearDayScheduleParams.description.contains("MTRDoorLockClusterSetYearDayScheduleParams"), "MTRDoorLockClusterSetYearDayScheduleParams desc")
    let _MTRDoorLockClusterUnboltDoorParams = MTRDoorLockClusterUnboltDoorParams()
    _MTRDoorLockClusterUnboltDoorParams.pinCode = Data([1])
    _ = _MTRDoorLockClusterUnboltDoorParams.pinCode
    _MTRDoorLockClusterUnboltDoorParams.serverSideProcessingTimeout = n(1)
    _ = _MTRDoorLockClusterUnboltDoorParams.serverSideProcessingTimeout
    _MTRDoorLockClusterUnboltDoorParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRDoorLockClusterUnboltDoorParams.timedInvokeTimeoutMs
    mtrRequire(_MTRDoorLockClusterUnboltDoorParams.description.contains("MTRDoorLockClusterUnboltDoorParams"), "MTRDoorLockClusterUnboltDoorParams desc")
    let _MTRDoorLockClusterUnlockDoorParams = MTRDoorLockClusterUnlockDoorParams()
    _MTRDoorLockClusterUnlockDoorParams.pinCode = Data([1])
    _ = _MTRDoorLockClusterUnlockDoorParams.pinCode
    _MTRDoorLockClusterUnlockDoorParams.serverSideProcessingTimeout = n(1)
    _ = _MTRDoorLockClusterUnlockDoorParams.serverSideProcessingTimeout
    _MTRDoorLockClusterUnlockDoorParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRDoorLockClusterUnlockDoorParams.timedInvokeTimeoutMs
    mtrRequire(_MTRDoorLockClusterUnlockDoorParams.description.contains("MTRDoorLockClusterUnlockDoorParams"), "MTRDoorLockClusterUnlockDoorParams desc")
    let _MTRDoorLockClusterUnlockWithTimeoutParams = MTRDoorLockClusterUnlockWithTimeoutParams()
    _MTRDoorLockClusterUnlockWithTimeoutParams.pinCode = Data([1])
    _ = _MTRDoorLockClusterUnlockWithTimeoutParams.pinCode
    _MTRDoorLockClusterUnlockWithTimeoutParams.serverSideProcessingTimeout = n(1)
    _ = _MTRDoorLockClusterUnlockWithTimeoutParams.serverSideProcessingTimeout
    _MTRDoorLockClusterUnlockWithTimeoutParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRDoorLockClusterUnlockWithTimeoutParams.timedInvokeTimeoutMs
    _MTRDoorLockClusterUnlockWithTimeoutParams.timeout = n(1)
    _ = _MTRDoorLockClusterUnlockWithTimeoutParams.timeout
    mtrRequire(_MTRDoorLockClusterUnlockWithTimeoutParams.description.contains("MTRDoorLockClusterUnlockWithTimeoutParams"), "MTRDoorLockClusterUnlockWithTimeoutParams desc")
}

func testElectricalMeasurementParams() {
    let _MTRElectricalMeasurementClusterGetMeasurementProfileCommandParams = MTRElectricalMeasurementClusterGetMeasurementProfileCommandParams()
    _MTRElectricalMeasurementClusterGetMeasurementProfileCommandParams.attributeId = n(1)
    _ = _MTRElectricalMeasurementClusterGetMeasurementProfileCommandParams.attributeId
    _MTRElectricalMeasurementClusterGetMeasurementProfileCommandParams.numberOfIntervals = n(1)
    _ = _MTRElectricalMeasurementClusterGetMeasurementProfileCommandParams.numberOfIntervals
    _MTRElectricalMeasurementClusterGetMeasurementProfileCommandParams.serverSideProcessingTimeout = n(1)
    _ = _MTRElectricalMeasurementClusterGetMeasurementProfileCommandParams.serverSideProcessingTimeout
    _MTRElectricalMeasurementClusterGetMeasurementProfileCommandParams.startTime = n(1)
    _ = _MTRElectricalMeasurementClusterGetMeasurementProfileCommandParams.startTime
    _MTRElectricalMeasurementClusterGetMeasurementProfileCommandParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRElectricalMeasurementClusterGetMeasurementProfileCommandParams.timedInvokeTimeoutMs
    mtrRequire(_MTRElectricalMeasurementClusterGetMeasurementProfileCommandParams.description.contains("MTRElectricalMeasurementClusterGetMeasurementProfileCommandParams"), "MTRElectricalMeasurementClusterGetMeasurementProfileCommandParams desc")
    let _MTRElectricalMeasurementClusterGetMeasurementProfileResponseCommandParams = (try? MTRElectricalMeasurementClusterGetMeasurementProfileResponseCommandParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRElectricalMeasurementClusterGetMeasurementProfileResponseCommandParams()
    _MTRElectricalMeasurementClusterGetMeasurementProfileResponseCommandParams.attributeId = n(1)
    _ = _MTRElectricalMeasurementClusterGetMeasurementProfileResponseCommandParams.attributeId
    _MTRElectricalMeasurementClusterGetMeasurementProfileResponseCommandParams.intervals = [n(1)] as [Any]
    _ = _MTRElectricalMeasurementClusterGetMeasurementProfileResponseCommandParams.intervals
    _MTRElectricalMeasurementClusterGetMeasurementProfileResponseCommandParams.numberOfIntervalsDelivered = n(1)
    _ = _MTRElectricalMeasurementClusterGetMeasurementProfileResponseCommandParams.numberOfIntervalsDelivered
    _MTRElectricalMeasurementClusterGetMeasurementProfileResponseCommandParams.profileIntervalPeriod = n(1)
    _ = _MTRElectricalMeasurementClusterGetMeasurementProfileResponseCommandParams.profileIntervalPeriod
    _MTRElectricalMeasurementClusterGetMeasurementProfileResponseCommandParams.startTime = n(1)
    _ = _MTRElectricalMeasurementClusterGetMeasurementProfileResponseCommandParams.startTime
    _MTRElectricalMeasurementClusterGetMeasurementProfileResponseCommandParams.status = n(1)
    _ = _MTRElectricalMeasurementClusterGetMeasurementProfileResponseCommandParams.status
    _MTRElectricalMeasurementClusterGetMeasurementProfileResponseCommandParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRElectricalMeasurementClusterGetMeasurementProfileResponseCommandParams.timedInvokeTimeoutMs
    mtrRequire(_MTRElectricalMeasurementClusterGetMeasurementProfileResponseCommandParams.description.contains("MTRElectricalMeasurementClusterGetMeasurementProfileResponseCommandParams"), "MTRElectricalMeasurementClusterGetMeasurementProfileResponseCommandParams desc")
    let _MTRElectricalMeasurementClusterGetProfileInfoCommandParams = MTRElectricalMeasurementClusterGetProfileInfoCommandParams()
    _MTRElectricalMeasurementClusterGetProfileInfoCommandParams.serverSideProcessingTimeout = n(1)
    _ = _MTRElectricalMeasurementClusterGetProfileInfoCommandParams.serverSideProcessingTimeout
    _MTRElectricalMeasurementClusterGetProfileInfoCommandParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRElectricalMeasurementClusterGetProfileInfoCommandParams.timedInvokeTimeoutMs
    mtrRequire(_MTRElectricalMeasurementClusterGetProfileInfoCommandParams.description.contains("MTRElectricalMeasurementClusterGetProfileInfoCommandParams"), "MTRElectricalMeasurementClusterGetProfileInfoCommandParams desc")
    let _MTRElectricalMeasurementClusterGetProfileInfoResponseCommandParams = (try? MTRElectricalMeasurementClusterGetProfileInfoResponseCommandParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRElectricalMeasurementClusterGetProfileInfoResponseCommandParams()
    _MTRElectricalMeasurementClusterGetProfileInfoResponseCommandParams.listOfAttributes = [n(1)] as [Any]
    _ = _MTRElectricalMeasurementClusterGetProfileInfoResponseCommandParams.listOfAttributes
    _MTRElectricalMeasurementClusterGetProfileInfoResponseCommandParams.maxNumberOfIntervals = n(1)
    _ = _MTRElectricalMeasurementClusterGetProfileInfoResponseCommandParams.maxNumberOfIntervals
    _MTRElectricalMeasurementClusterGetProfileInfoResponseCommandParams.profileCount = n(1)
    _ = _MTRElectricalMeasurementClusterGetProfileInfoResponseCommandParams.profileCount
    _MTRElectricalMeasurementClusterGetProfileInfoResponseCommandParams.profileIntervalPeriod = n(1)
    _ = _MTRElectricalMeasurementClusterGetProfileInfoResponseCommandParams.profileIntervalPeriod
    _MTRElectricalMeasurementClusterGetProfileInfoResponseCommandParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRElectricalMeasurementClusterGetProfileInfoResponseCommandParams.timedInvokeTimeoutMs
    mtrRequire(_MTRElectricalMeasurementClusterGetProfileInfoResponseCommandParams.description.contains("MTRElectricalMeasurementClusterGetProfileInfoResponseCommandParams"), "MTRElectricalMeasurementClusterGetProfileInfoResponseCommandParams desc")
}

func testLevelControlParams() {
    let _MTRLevelControlClusterMoveParams = MTRLevelControlClusterMoveParams()
    _MTRLevelControlClusterMoveParams.moveMode = n(1)
    _ = _MTRLevelControlClusterMoveParams.moveMode
    _MTRLevelControlClusterMoveParams.optionsMask = n(1)
    _ = _MTRLevelControlClusterMoveParams.optionsMask
    _MTRLevelControlClusterMoveParams.optionsOverride = n(1)
    _ = _MTRLevelControlClusterMoveParams.optionsOverride
    _MTRLevelControlClusterMoveParams.rate = n(1)
    _ = _MTRLevelControlClusterMoveParams.rate
    _MTRLevelControlClusterMoveParams.serverSideProcessingTimeout = n(1)
    _ = _MTRLevelControlClusterMoveParams.serverSideProcessingTimeout
    _MTRLevelControlClusterMoveParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRLevelControlClusterMoveParams.timedInvokeTimeoutMs
    mtrRequire(_MTRLevelControlClusterMoveParams.description.contains("MTRLevelControlClusterMoveParams"), "MTRLevelControlClusterMoveParams desc")
    let _MTRLevelControlClusterMoveToClosestFrequencyParams = MTRLevelControlClusterMoveToClosestFrequencyParams()
    _MTRLevelControlClusterMoveToClosestFrequencyParams.frequency = n(1)
    _ = _MTRLevelControlClusterMoveToClosestFrequencyParams.frequency
    _MTRLevelControlClusterMoveToClosestFrequencyParams.serverSideProcessingTimeout = n(1)
    _ = _MTRLevelControlClusterMoveToClosestFrequencyParams.serverSideProcessingTimeout
    _MTRLevelControlClusterMoveToClosestFrequencyParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRLevelControlClusterMoveToClosestFrequencyParams.timedInvokeTimeoutMs
    mtrRequire(_MTRLevelControlClusterMoveToClosestFrequencyParams.description.contains("MTRLevelControlClusterMoveToClosestFrequencyParams"), "MTRLevelControlClusterMoveToClosestFrequencyParams desc")
    let _MTRLevelControlClusterMoveToLevelParams = MTRLevelControlClusterMoveToLevelParams()
    _MTRLevelControlClusterMoveToLevelParams.level = n(1)
    _ = _MTRLevelControlClusterMoveToLevelParams.level
    _MTRLevelControlClusterMoveToLevelParams.optionsMask = n(1)
    _ = _MTRLevelControlClusterMoveToLevelParams.optionsMask
    _MTRLevelControlClusterMoveToLevelParams.optionsOverride = n(1)
    _ = _MTRLevelControlClusterMoveToLevelParams.optionsOverride
    _MTRLevelControlClusterMoveToLevelParams.serverSideProcessingTimeout = n(1)
    _ = _MTRLevelControlClusterMoveToLevelParams.serverSideProcessingTimeout
    _MTRLevelControlClusterMoveToLevelParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRLevelControlClusterMoveToLevelParams.timedInvokeTimeoutMs
    _MTRLevelControlClusterMoveToLevelParams.transitionTime = n(1)
    _ = _MTRLevelControlClusterMoveToLevelParams.transitionTime
    mtrRequire(_MTRLevelControlClusterMoveToLevelParams.description.contains("MTRLevelControlClusterMoveToLevelParams"), "MTRLevelControlClusterMoveToLevelParams desc")
    let _MTRLevelControlClusterMoveToLevelWithOnOffParams = MTRLevelControlClusterMoveToLevelWithOnOffParams()
    _MTRLevelControlClusterMoveToLevelWithOnOffParams.level = n(1)
    _ = _MTRLevelControlClusterMoveToLevelWithOnOffParams.level
    _MTRLevelControlClusterMoveToLevelWithOnOffParams.optionsMask = n(1)
    _ = _MTRLevelControlClusterMoveToLevelWithOnOffParams.optionsMask
    _MTRLevelControlClusterMoveToLevelWithOnOffParams.optionsOverride = n(1)
    _ = _MTRLevelControlClusterMoveToLevelWithOnOffParams.optionsOverride
    _MTRLevelControlClusterMoveToLevelWithOnOffParams.serverSideProcessingTimeout = n(1)
    _ = _MTRLevelControlClusterMoveToLevelWithOnOffParams.serverSideProcessingTimeout
    _MTRLevelControlClusterMoveToLevelWithOnOffParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRLevelControlClusterMoveToLevelWithOnOffParams.timedInvokeTimeoutMs
    _MTRLevelControlClusterMoveToLevelWithOnOffParams.transitionTime = n(1)
    _ = _MTRLevelControlClusterMoveToLevelWithOnOffParams.transitionTime
    mtrRequire(_MTRLevelControlClusterMoveToLevelWithOnOffParams.description.contains("MTRLevelControlClusterMoveToLevelWithOnOffParams"), "MTRLevelControlClusterMoveToLevelWithOnOffParams desc")
    let _MTRLevelControlClusterMoveWithOnOffParams = MTRLevelControlClusterMoveWithOnOffParams()
    _MTRLevelControlClusterMoveWithOnOffParams.moveMode = n(1)
    _ = _MTRLevelControlClusterMoveWithOnOffParams.moveMode
    _MTRLevelControlClusterMoveWithOnOffParams.optionsMask = n(1)
    _ = _MTRLevelControlClusterMoveWithOnOffParams.optionsMask
    _MTRLevelControlClusterMoveWithOnOffParams.optionsOverride = n(1)
    _ = _MTRLevelControlClusterMoveWithOnOffParams.optionsOverride
    _MTRLevelControlClusterMoveWithOnOffParams.rate = n(1)
    _ = _MTRLevelControlClusterMoveWithOnOffParams.rate
    _MTRLevelControlClusterMoveWithOnOffParams.serverSideProcessingTimeout = n(1)
    _ = _MTRLevelControlClusterMoveWithOnOffParams.serverSideProcessingTimeout
    _MTRLevelControlClusterMoveWithOnOffParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRLevelControlClusterMoveWithOnOffParams.timedInvokeTimeoutMs
    mtrRequire(_MTRLevelControlClusterMoveWithOnOffParams.description.contains("MTRLevelControlClusterMoveWithOnOffParams"), "MTRLevelControlClusterMoveWithOnOffParams desc")
    let _MTRLevelControlClusterStepParams = MTRLevelControlClusterStepParams()
    _MTRLevelControlClusterStepParams.optionsMask = n(1)
    _ = _MTRLevelControlClusterStepParams.optionsMask
    _MTRLevelControlClusterStepParams.optionsOverride = n(1)
    _ = _MTRLevelControlClusterStepParams.optionsOverride
    _MTRLevelControlClusterStepParams.serverSideProcessingTimeout = n(1)
    _ = _MTRLevelControlClusterStepParams.serverSideProcessingTimeout
    _MTRLevelControlClusterStepParams.stepMode = n(1)
    _ = _MTRLevelControlClusterStepParams.stepMode
    _MTRLevelControlClusterStepParams.stepSize = n(1)
    _ = _MTRLevelControlClusterStepParams.stepSize
    _MTRLevelControlClusterStepParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRLevelControlClusterStepParams.timedInvokeTimeoutMs
    _MTRLevelControlClusterStepParams.transitionTime = n(1)
    _ = _MTRLevelControlClusterStepParams.transitionTime
    mtrRequire(_MTRLevelControlClusterStepParams.description.contains("MTRLevelControlClusterStepParams"), "MTRLevelControlClusterStepParams desc")
    let _MTRLevelControlClusterStepWithOnOffParams = MTRLevelControlClusterStepWithOnOffParams()
    _MTRLevelControlClusterStepWithOnOffParams.optionsMask = n(1)
    _ = _MTRLevelControlClusterStepWithOnOffParams.optionsMask
    _MTRLevelControlClusterStepWithOnOffParams.optionsOverride = n(1)
    _ = _MTRLevelControlClusterStepWithOnOffParams.optionsOverride
    _MTRLevelControlClusterStepWithOnOffParams.serverSideProcessingTimeout = n(1)
    _ = _MTRLevelControlClusterStepWithOnOffParams.serverSideProcessingTimeout
    _MTRLevelControlClusterStepWithOnOffParams.stepMode = n(1)
    _ = _MTRLevelControlClusterStepWithOnOffParams.stepMode
    _MTRLevelControlClusterStepWithOnOffParams.stepSize = n(1)
    _ = _MTRLevelControlClusterStepWithOnOffParams.stepSize
    _MTRLevelControlClusterStepWithOnOffParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRLevelControlClusterStepWithOnOffParams.timedInvokeTimeoutMs
    _MTRLevelControlClusterStepWithOnOffParams.transitionTime = n(1)
    _ = _MTRLevelControlClusterStepWithOnOffParams.transitionTime
    mtrRequire(_MTRLevelControlClusterStepWithOnOffParams.description.contains("MTRLevelControlClusterStepWithOnOffParams"), "MTRLevelControlClusterStepWithOnOffParams desc")
    let _MTRLevelControlClusterStopParams = MTRLevelControlClusterStopParams()
    _MTRLevelControlClusterStopParams.optionsMask = n(1)
    _ = _MTRLevelControlClusterStopParams.optionsMask
    _MTRLevelControlClusterStopParams.optionsOverride = n(1)
    _ = _MTRLevelControlClusterStopParams.optionsOverride
    _MTRLevelControlClusterStopParams.serverSideProcessingTimeout = n(1)
    _ = _MTRLevelControlClusterStopParams.serverSideProcessingTimeout
    _MTRLevelControlClusterStopParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRLevelControlClusterStopParams.timedInvokeTimeoutMs
    mtrRequire(_MTRLevelControlClusterStopParams.description.contains("MTRLevelControlClusterStopParams"), "MTRLevelControlClusterStopParams desc")
    let _MTRLevelControlClusterStopWithOnOffParams = MTRLevelControlClusterStopWithOnOffParams()
    _MTRLevelControlClusterStopWithOnOffParams.optionsMask = n(1)
    _ = _MTRLevelControlClusterStopWithOnOffParams.optionsMask
    _MTRLevelControlClusterStopWithOnOffParams.optionsOverride = n(1)
    _ = _MTRLevelControlClusterStopWithOnOffParams.optionsOverride
    _MTRLevelControlClusterStopWithOnOffParams.serverSideProcessingTimeout = n(1)
    _ = _MTRLevelControlClusterStopWithOnOffParams.serverSideProcessingTimeout
    _MTRLevelControlClusterStopWithOnOffParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRLevelControlClusterStopWithOnOffParams.timedInvokeTimeoutMs
    mtrRequire(_MTRLevelControlClusterStopWithOnOffParams.description.contains("MTRLevelControlClusterStopWithOnOffParams"), "MTRLevelControlClusterStopWithOnOffParams desc")
}

func testPowerSourceParams() {
    let _MTRPowerSourceClusterBatChargeFaultChangeEvent = MTRPowerSourceClusterBatChargeFaultChangeEvent()
    _MTRPowerSourceClusterBatChargeFaultChangeEvent.current = [n(1)] as [Any]
    _ = _MTRPowerSourceClusterBatChargeFaultChangeEvent.current
    _MTRPowerSourceClusterBatChargeFaultChangeEvent.previous = [n(1)] as [Any]
    _ = _MTRPowerSourceClusterBatChargeFaultChangeEvent.previous
    mtrRequire(_MTRPowerSourceClusterBatChargeFaultChangeEvent.description.contains("MTRPowerSourceClusterBatChargeFaultChangeEvent"), "MTRPowerSourceClusterBatChargeFaultChangeEvent desc")
    let _MTRPowerSourceClusterBatChargeFaultChangeType = MTRPowerSourceClusterBatChargeFaultChangeType()
    _MTRPowerSourceClusterBatChargeFaultChangeType.current = [n(1)] as [Any]
    _ = _MTRPowerSourceClusterBatChargeFaultChangeType.current
    _MTRPowerSourceClusterBatChargeFaultChangeType.previous = [n(1)] as [Any]
    _ = _MTRPowerSourceClusterBatChargeFaultChangeType.previous
    mtrRequire(_MTRPowerSourceClusterBatChargeFaultChangeType.description.contains("MTRPowerSourceClusterBatChargeFaultChangeType"), "MTRPowerSourceClusterBatChargeFaultChangeType desc")
    let _MTRPowerSourceClusterBatFaultChangeEvent = MTRPowerSourceClusterBatFaultChangeEvent()
    _MTRPowerSourceClusterBatFaultChangeEvent.current = [n(1)] as [Any]
    _ = _MTRPowerSourceClusterBatFaultChangeEvent.current
    _MTRPowerSourceClusterBatFaultChangeEvent.previous = [n(1)] as [Any]
    _ = _MTRPowerSourceClusterBatFaultChangeEvent.previous
    mtrRequire(_MTRPowerSourceClusterBatFaultChangeEvent.description.contains("MTRPowerSourceClusterBatFaultChangeEvent"), "MTRPowerSourceClusterBatFaultChangeEvent desc")
    let _MTRPowerSourceClusterBatFaultChangeType = MTRPowerSourceClusterBatFaultChangeType()
    _MTRPowerSourceClusterBatFaultChangeType.current = [n(1)] as [Any]
    _ = _MTRPowerSourceClusterBatFaultChangeType.current
    _MTRPowerSourceClusterBatFaultChangeType.previous = [n(1)] as [Any]
    _ = _MTRPowerSourceClusterBatFaultChangeType.previous
    mtrRequire(_MTRPowerSourceClusterBatFaultChangeType.description.contains("MTRPowerSourceClusterBatFaultChangeType"), "MTRPowerSourceClusterBatFaultChangeType desc")
    let _MTRPowerSourceClusterWiredFaultChangeEvent = MTRPowerSourceClusterWiredFaultChangeEvent()
    _MTRPowerSourceClusterWiredFaultChangeEvent.current = [n(1)] as [Any]
    _ = _MTRPowerSourceClusterWiredFaultChangeEvent.current
    _MTRPowerSourceClusterWiredFaultChangeEvent.previous = [n(1)] as [Any]
    _ = _MTRPowerSourceClusterWiredFaultChangeEvent.previous
    mtrRequire(_MTRPowerSourceClusterWiredFaultChangeEvent.description.contains("MTRPowerSourceClusterWiredFaultChangeEvent"), "MTRPowerSourceClusterWiredFaultChangeEvent desc")
    let _MTRPowerSourceClusterWiredFaultChangeType = MTRPowerSourceClusterWiredFaultChangeType()
    _MTRPowerSourceClusterWiredFaultChangeType.current = [n(1)] as [Any]
    _ = _MTRPowerSourceClusterWiredFaultChangeType.current
    _MTRPowerSourceClusterWiredFaultChangeType.previous = [n(1)] as [Any]
    _ = _MTRPowerSourceClusterWiredFaultChangeType.previous
    mtrRequire(_MTRPowerSourceClusterWiredFaultChangeType.description.contains("MTRPowerSourceClusterWiredFaultChangeType"), "MTRPowerSourceClusterWiredFaultChangeType desc")
}

func testPumpConfigurationAndControlParams() {
    let _MTRPumpConfigurationAndControlClusterAirDetectionEvent = MTRPumpConfigurationAndControlClusterAirDetectionEvent()
    mtrRequire(_MTRPumpConfigurationAndControlClusterAirDetectionEvent.description.contains("MTRPumpConfigurationAndControlClusterAirDetectionEvent"), "MTRPumpConfigurationAndControlClusterAirDetectionEvent desc")
    let _MTRPumpConfigurationAndControlClusterDryRunningEvent = MTRPumpConfigurationAndControlClusterDryRunningEvent()
    mtrRequire(_MTRPumpConfigurationAndControlClusterDryRunningEvent.description.contains("MTRPumpConfigurationAndControlClusterDryRunningEvent"), "MTRPumpConfigurationAndControlClusterDryRunningEvent desc")
    let _MTRPumpConfigurationAndControlClusterElectronicFatalFailureEvent = MTRPumpConfigurationAndControlClusterElectronicFatalFailureEvent()
    mtrRequire(_MTRPumpConfigurationAndControlClusterElectronicFatalFailureEvent.description.contains("MTRPumpConfigurationAndControlClusterElectronicFatalFailureEvent"), "MTRPumpConfigurationAndControlClusterElectronicFatalFailureEvent desc")
    let _MTRPumpConfigurationAndControlClusterElectronicNonFatalFailureEvent = MTRPumpConfigurationAndControlClusterElectronicNonFatalFailureEvent()
    mtrRequire(_MTRPumpConfigurationAndControlClusterElectronicNonFatalFailureEvent.description.contains("MTRPumpConfigurationAndControlClusterElectronicNonFatalFailureEvent"), "MTRPumpConfigurationAndControlClusterElectronicNonFatalFailureEvent desc")
    let _MTRPumpConfigurationAndControlClusterElectronicTemperatureHighEvent = MTRPumpConfigurationAndControlClusterElectronicTemperatureHighEvent()
    mtrRequire(_MTRPumpConfigurationAndControlClusterElectronicTemperatureHighEvent.description.contains("MTRPumpConfigurationAndControlClusterElectronicTemperatureHighEvent"), "MTRPumpConfigurationAndControlClusterElectronicTemperatureHighEvent desc")
    let _MTRPumpConfigurationAndControlClusterGeneralFaultEvent = MTRPumpConfigurationAndControlClusterGeneralFaultEvent()
    mtrRequire(_MTRPumpConfigurationAndControlClusterGeneralFaultEvent.description.contains("MTRPumpConfigurationAndControlClusterGeneralFaultEvent"), "MTRPumpConfigurationAndControlClusterGeneralFaultEvent desc")
    let _MTRPumpConfigurationAndControlClusterLeakageEvent = MTRPumpConfigurationAndControlClusterLeakageEvent()
    mtrRequire(_MTRPumpConfigurationAndControlClusterLeakageEvent.description.contains("MTRPumpConfigurationAndControlClusterLeakageEvent"), "MTRPumpConfigurationAndControlClusterLeakageEvent desc")
    let _MTRPumpConfigurationAndControlClusterMotorTemperatureHighEvent = MTRPumpConfigurationAndControlClusterMotorTemperatureHighEvent()
    mtrRequire(_MTRPumpConfigurationAndControlClusterMotorTemperatureHighEvent.description.contains("MTRPumpConfigurationAndControlClusterMotorTemperatureHighEvent"), "MTRPumpConfigurationAndControlClusterMotorTemperatureHighEvent desc")
    let _MTRPumpConfigurationAndControlClusterPowerMissingPhaseEvent = MTRPumpConfigurationAndControlClusterPowerMissingPhaseEvent()
    mtrRequire(_MTRPumpConfigurationAndControlClusterPowerMissingPhaseEvent.description.contains("MTRPumpConfigurationAndControlClusterPowerMissingPhaseEvent"), "MTRPumpConfigurationAndControlClusterPowerMissingPhaseEvent desc")
    let _MTRPumpConfigurationAndControlClusterPumpBlockedEvent = MTRPumpConfigurationAndControlClusterPumpBlockedEvent()
    mtrRequire(_MTRPumpConfigurationAndControlClusterPumpBlockedEvent.description.contains("MTRPumpConfigurationAndControlClusterPumpBlockedEvent"), "MTRPumpConfigurationAndControlClusterPumpBlockedEvent desc")
    let _MTRPumpConfigurationAndControlClusterPumpMotorFatalFailureEvent = MTRPumpConfigurationAndControlClusterPumpMotorFatalFailureEvent()
    mtrRequire(_MTRPumpConfigurationAndControlClusterPumpMotorFatalFailureEvent.description.contains("MTRPumpConfigurationAndControlClusterPumpMotorFatalFailureEvent"), "MTRPumpConfigurationAndControlClusterPumpMotorFatalFailureEvent desc")
    let _MTRPumpConfigurationAndControlClusterSensorFailureEvent = MTRPumpConfigurationAndControlClusterSensorFailureEvent()
    mtrRequire(_MTRPumpConfigurationAndControlClusterSensorFailureEvent.description.contains("MTRPumpConfigurationAndControlClusterSensorFailureEvent"), "MTRPumpConfigurationAndControlClusterSensorFailureEvent desc")
    let _MTRPumpConfigurationAndControlClusterSupplyVoltageHighEvent = MTRPumpConfigurationAndControlClusterSupplyVoltageHighEvent()
    mtrRequire(_MTRPumpConfigurationAndControlClusterSupplyVoltageHighEvent.description.contains("MTRPumpConfigurationAndControlClusterSupplyVoltageHighEvent"), "MTRPumpConfigurationAndControlClusterSupplyVoltageHighEvent desc")
    let _MTRPumpConfigurationAndControlClusterSupplyVoltageLowEvent = MTRPumpConfigurationAndControlClusterSupplyVoltageLowEvent()
    mtrRequire(_MTRPumpConfigurationAndControlClusterSupplyVoltageLowEvent.description.contains("MTRPumpConfigurationAndControlClusterSupplyVoltageLowEvent"), "MTRPumpConfigurationAndControlClusterSupplyVoltageLowEvent desc")
    let _MTRPumpConfigurationAndControlClusterSystemPressureHighEvent = MTRPumpConfigurationAndControlClusterSystemPressureHighEvent()
    mtrRequire(_MTRPumpConfigurationAndControlClusterSystemPressureHighEvent.description.contains("MTRPumpConfigurationAndControlClusterSystemPressureHighEvent"), "MTRPumpConfigurationAndControlClusterSystemPressureHighEvent desc")
    let _MTRPumpConfigurationAndControlClusterSystemPressureLowEvent = MTRPumpConfigurationAndControlClusterSystemPressureLowEvent()
    mtrRequire(_MTRPumpConfigurationAndControlClusterSystemPressureLowEvent.description.contains("MTRPumpConfigurationAndControlClusterSystemPressureLowEvent"), "MTRPumpConfigurationAndControlClusterSystemPressureLowEvent desc")
    let _MTRPumpConfigurationAndControlClusterTurbineOperationEvent = MTRPumpConfigurationAndControlClusterTurbineOperationEvent()
    mtrRequire(_MTRPumpConfigurationAndControlClusterTurbineOperationEvent.description.contains("MTRPumpConfigurationAndControlClusterTurbineOperationEvent"), "MTRPumpConfigurationAndControlClusterTurbineOperationEvent desc")
}

func testThermostatParams() {
    let _MTRThermostatClusterAtomicRequestParams = MTRThermostatClusterAtomicRequestParams()
    _MTRThermostatClusterAtomicRequestParams.attributeRequests = [n(1)] as [Any]
    _ = _MTRThermostatClusterAtomicRequestParams.attributeRequests
    _MTRThermostatClusterAtomicRequestParams.requestType = n(1)
    _ = _MTRThermostatClusterAtomicRequestParams.requestType
    _MTRThermostatClusterAtomicRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRThermostatClusterAtomicRequestParams.serverSideProcessingTimeout
    _MTRThermostatClusterAtomicRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRThermostatClusterAtomicRequestParams.timedInvokeTimeoutMs
    _MTRThermostatClusterAtomicRequestParams.timeout = n(1)
    _ = _MTRThermostatClusterAtomicRequestParams.timeout
    mtrRequire(_MTRThermostatClusterAtomicRequestParams.description.contains("MTRThermostatClusterAtomicRequestParams"), "MTRThermostatClusterAtomicRequestParams desc")
    let _MTRThermostatClusterAtomicResponseParams = (try? MTRThermostatClusterAtomicResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRThermostatClusterAtomicResponseParams()
    _MTRThermostatClusterAtomicResponseParams.attributeStatus = [n(1)] as [Any]
    _ = _MTRThermostatClusterAtomicResponseParams.attributeStatus
    _MTRThermostatClusterAtomicResponseParams.statusCode = n(1)
    _ = _MTRThermostatClusterAtomicResponseParams.statusCode
    _MTRThermostatClusterAtomicResponseParams.timeout = n(1)
    _ = _MTRThermostatClusterAtomicResponseParams.timeout
    mtrRequire(_MTRThermostatClusterAtomicResponseParams.description.contains("MTRThermostatClusterAtomicResponseParams"), "MTRThermostatClusterAtomicResponseParams desc")
    let _MTRThermostatClusterClearWeeklyScheduleParams = MTRThermostatClusterClearWeeklyScheduleParams()
    _MTRThermostatClusterClearWeeklyScheduleParams.serverSideProcessingTimeout = n(1)
    _ = _MTRThermostatClusterClearWeeklyScheduleParams.serverSideProcessingTimeout
    _MTRThermostatClusterClearWeeklyScheduleParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRThermostatClusterClearWeeklyScheduleParams.timedInvokeTimeoutMs
    mtrRequire(_MTRThermostatClusterClearWeeklyScheduleParams.description.contains("MTRThermostatClusterClearWeeklyScheduleParams"), "MTRThermostatClusterClearWeeklyScheduleParams desc")
    let _MTRThermostatClusterGetWeeklyScheduleParams = MTRThermostatClusterGetWeeklyScheduleParams()
    _MTRThermostatClusterGetWeeklyScheduleParams.daysToReturn = n(1)
    _ = _MTRThermostatClusterGetWeeklyScheduleParams.daysToReturn
    _MTRThermostatClusterGetWeeklyScheduleParams.modeToReturn = n(1)
    _ = _MTRThermostatClusterGetWeeklyScheduleParams.modeToReturn
    _MTRThermostatClusterGetWeeklyScheduleParams.serverSideProcessingTimeout = n(1)
    _ = _MTRThermostatClusterGetWeeklyScheduleParams.serverSideProcessingTimeout
    _MTRThermostatClusterGetWeeklyScheduleParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRThermostatClusterGetWeeklyScheduleParams.timedInvokeTimeoutMs
    mtrRequire(_MTRThermostatClusterGetWeeklyScheduleParams.description.contains("MTRThermostatClusterGetWeeklyScheduleParams"), "MTRThermostatClusterGetWeeklyScheduleParams desc")
    let _MTRThermostatClusterGetWeeklyScheduleResponseParams = (try? MTRThermostatClusterGetWeeklyScheduleResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRThermostatClusterGetWeeklyScheduleResponseParams()
    _MTRThermostatClusterGetWeeklyScheduleResponseParams.dayOfWeekForSequence = n(1)
    _ = _MTRThermostatClusterGetWeeklyScheduleResponseParams.dayOfWeekForSequence
    _MTRThermostatClusterGetWeeklyScheduleResponseParams.modeForSequence = n(1)
    _ = _MTRThermostatClusterGetWeeklyScheduleResponseParams.modeForSequence
    _MTRThermostatClusterGetWeeklyScheduleResponseParams.numberOfTransitionsForSequence = n(1)
    _ = _MTRThermostatClusterGetWeeklyScheduleResponseParams.numberOfTransitionsForSequence
    _MTRThermostatClusterGetWeeklyScheduleResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRThermostatClusterGetWeeklyScheduleResponseParams.timedInvokeTimeoutMs
    _MTRThermostatClusterGetWeeklyScheduleResponseParams.transitions = [n(1)] as [Any]
    _ = _MTRThermostatClusterGetWeeklyScheduleResponseParams.transitions
    mtrRequire(_MTRThermostatClusterGetWeeklyScheduleResponseParams.description.contains("MTRThermostatClusterGetWeeklyScheduleResponseParams"), "MTRThermostatClusterGetWeeklyScheduleResponseParams desc")
    let _MTRThermostatClusterPresetStruct = MTRThermostatClusterPresetStruct()
    _MTRThermostatClusterPresetStruct.builtIn = n(1)
    _ = _MTRThermostatClusterPresetStruct.builtIn
    _MTRThermostatClusterPresetStruct.coolingSetpoint = n(1)
    _ = _MTRThermostatClusterPresetStruct.coolingSetpoint
    _MTRThermostatClusterPresetStruct.heatingSetpoint = n(1)
    _ = _MTRThermostatClusterPresetStruct.heatingSetpoint
    _MTRThermostatClusterPresetStruct.name = "x"
    _ = _MTRThermostatClusterPresetStruct.name
    _MTRThermostatClusterPresetStruct.presetHandle = Data([1])
    _ = _MTRThermostatClusterPresetStruct.presetHandle
    _MTRThermostatClusterPresetStruct.presetScenario = n(1)
    _ = _MTRThermostatClusterPresetStruct.presetScenario
    mtrRequire(_MTRThermostatClusterPresetStruct.description.contains("MTRThermostatClusterPresetStruct"), "MTRThermostatClusterPresetStruct desc")
    let _MTRThermostatClusterPresetTypeStruct = MTRThermostatClusterPresetTypeStruct()
    _MTRThermostatClusterPresetTypeStruct.numberOfPresets = n(1)
    _ = _MTRThermostatClusterPresetTypeStruct.numberOfPresets
    _MTRThermostatClusterPresetTypeStruct.presetScenario = n(1)
    _ = _MTRThermostatClusterPresetTypeStruct.presetScenario
    _MTRThermostatClusterPresetTypeStruct.presetTypeFeatures = n(1)
    _ = _MTRThermostatClusterPresetTypeStruct.presetTypeFeatures
    mtrRequire(_MTRThermostatClusterPresetTypeStruct.description.contains("MTRThermostatClusterPresetTypeStruct"), "MTRThermostatClusterPresetTypeStruct desc")
    let _MTRThermostatClusterScheduleStruct = MTRThermostatClusterScheduleStruct()
    _MTRThermostatClusterScheduleStruct.builtIn = n(1)
    _ = _MTRThermostatClusterScheduleStruct.builtIn
    _MTRThermostatClusterScheduleStruct.name = "x"
    _ = _MTRThermostatClusterScheduleStruct.name
    _MTRThermostatClusterScheduleStruct.presetHandle = Data([1])
    _ = _MTRThermostatClusterScheduleStruct.presetHandle
    _MTRThermostatClusterScheduleStruct.scheduleHandle = Data([1])
    _ = _MTRThermostatClusterScheduleStruct.scheduleHandle
    _MTRThermostatClusterScheduleStruct.systemMode = n(1)
    _ = _MTRThermostatClusterScheduleStruct.systemMode
    _MTRThermostatClusterScheduleStruct.transitions = [n(1)] as [Any]
    _ = _MTRThermostatClusterScheduleStruct.transitions
    mtrRequire(_MTRThermostatClusterScheduleStruct.description.contains("MTRThermostatClusterScheduleStruct"), "MTRThermostatClusterScheduleStruct desc")
    let _MTRThermostatClusterScheduleTransitionStruct = MTRThermostatClusterScheduleTransitionStruct()
    _MTRThermostatClusterScheduleTransitionStruct.coolingSetpoint = n(1)
    _ = _MTRThermostatClusterScheduleTransitionStruct.coolingSetpoint
    _MTRThermostatClusterScheduleTransitionStruct.dayOfWeek = n(1)
    _ = _MTRThermostatClusterScheduleTransitionStruct.dayOfWeek
    _MTRThermostatClusterScheduleTransitionStruct.heatingSetpoint = n(1)
    _ = _MTRThermostatClusterScheduleTransitionStruct.heatingSetpoint
    _MTRThermostatClusterScheduleTransitionStruct.presetHandle = Data([1])
    _ = _MTRThermostatClusterScheduleTransitionStruct.presetHandle
    _MTRThermostatClusterScheduleTransitionStruct.systemMode = n(1)
    _ = _MTRThermostatClusterScheduleTransitionStruct.systemMode
    _MTRThermostatClusterScheduleTransitionStruct.transitionTime = n(1)
    _ = _MTRThermostatClusterScheduleTransitionStruct.transitionTime
    mtrRequire(_MTRThermostatClusterScheduleTransitionStruct.description.contains("MTRThermostatClusterScheduleTransitionStruct"), "MTRThermostatClusterScheduleTransitionStruct desc")
    let _MTRThermostatClusterScheduleTypeStruct = MTRThermostatClusterScheduleTypeStruct()
    _MTRThermostatClusterScheduleTypeStruct.numberOfSchedules = n(1)
    _ = _MTRThermostatClusterScheduleTypeStruct.numberOfSchedules
    _MTRThermostatClusterScheduleTypeStruct.scheduleTypeFeatures = n(1)
    _ = _MTRThermostatClusterScheduleTypeStruct.scheduleTypeFeatures
    _MTRThermostatClusterScheduleTypeStruct.systemMode = n(1)
    _ = _MTRThermostatClusterScheduleTypeStruct.systemMode
    mtrRequire(_MTRThermostatClusterScheduleTypeStruct.description.contains("MTRThermostatClusterScheduleTypeStruct"), "MTRThermostatClusterScheduleTypeStruct desc")
    let _MTRThermostatClusterSetActivePresetRequestParams = MTRThermostatClusterSetActivePresetRequestParams()
    _MTRThermostatClusterSetActivePresetRequestParams.presetHandle = Data([1])
    _ = _MTRThermostatClusterSetActivePresetRequestParams.presetHandle
    _MTRThermostatClusterSetActivePresetRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRThermostatClusterSetActivePresetRequestParams.serverSideProcessingTimeout
    _MTRThermostatClusterSetActivePresetRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRThermostatClusterSetActivePresetRequestParams.timedInvokeTimeoutMs
    mtrRequire(_MTRThermostatClusterSetActivePresetRequestParams.description.contains("MTRThermostatClusterSetActivePresetRequestParams"), "MTRThermostatClusterSetActivePresetRequestParams desc")
    let _MTRThermostatClusterSetActiveScheduleRequestParams = MTRThermostatClusterSetActiveScheduleRequestParams()
    _MTRThermostatClusterSetActiveScheduleRequestParams.scheduleHandle = Data([1])
    _ = _MTRThermostatClusterSetActiveScheduleRequestParams.scheduleHandle
    _MTRThermostatClusterSetActiveScheduleRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRThermostatClusterSetActiveScheduleRequestParams.serverSideProcessingTimeout
    _MTRThermostatClusterSetActiveScheduleRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRThermostatClusterSetActiveScheduleRequestParams.timedInvokeTimeoutMs
    mtrRequire(_MTRThermostatClusterSetActiveScheduleRequestParams.description.contains("MTRThermostatClusterSetActiveScheduleRequestParams"), "MTRThermostatClusterSetActiveScheduleRequestParams desc")
    let _MTRThermostatClusterSetWeeklyScheduleParams = MTRThermostatClusterSetWeeklyScheduleParams()
    _MTRThermostatClusterSetWeeklyScheduleParams.dayOfWeekForSequence = n(1)
    _ = _MTRThermostatClusterSetWeeklyScheduleParams.dayOfWeekForSequence
    _MTRThermostatClusterSetWeeklyScheduleParams.modeForSequence = n(1)
    _ = _MTRThermostatClusterSetWeeklyScheduleParams.modeForSequence
    _MTRThermostatClusterSetWeeklyScheduleParams.numberOfTransitionsForSequence = n(1)
    _ = _MTRThermostatClusterSetWeeklyScheduleParams.numberOfTransitionsForSequence
    _MTRThermostatClusterSetWeeklyScheduleParams.serverSideProcessingTimeout = n(1)
    _ = _MTRThermostatClusterSetWeeklyScheduleParams.serverSideProcessingTimeout
    _MTRThermostatClusterSetWeeklyScheduleParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRThermostatClusterSetWeeklyScheduleParams.timedInvokeTimeoutMs
    _MTRThermostatClusterSetWeeklyScheduleParams.transitions = [n(1)] as [Any]
    _ = _MTRThermostatClusterSetWeeklyScheduleParams.transitions
    mtrRequire(_MTRThermostatClusterSetWeeklyScheduleParams.description.contains("MTRThermostatClusterSetWeeklyScheduleParams"), "MTRThermostatClusterSetWeeklyScheduleParams desc")
    let _MTRThermostatClusterSetpointRaiseLowerParams = MTRThermostatClusterSetpointRaiseLowerParams()
    _MTRThermostatClusterSetpointRaiseLowerParams.amount = n(1)
    _ = _MTRThermostatClusterSetpointRaiseLowerParams.amount
    _MTRThermostatClusterSetpointRaiseLowerParams.mode = n(1)
    _ = _MTRThermostatClusterSetpointRaiseLowerParams.mode
    _MTRThermostatClusterSetpointRaiseLowerParams.serverSideProcessingTimeout = n(1)
    _ = _MTRThermostatClusterSetpointRaiseLowerParams.serverSideProcessingTimeout
    _MTRThermostatClusterSetpointRaiseLowerParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRThermostatClusterSetpointRaiseLowerParams.timedInvokeTimeoutMs
    mtrRequire(_MTRThermostatClusterSetpointRaiseLowerParams.description.contains("MTRThermostatClusterSetpointRaiseLowerParams"), "MTRThermostatClusterSetpointRaiseLowerParams desc")
    let _MTRThermostatClusterThermostatScheduleTransition = MTRThermostatClusterThermostatScheduleTransition()
    _MTRThermostatClusterThermostatScheduleTransition.coolSetpoint = n(1)
    _ = _MTRThermostatClusterThermostatScheduleTransition.coolSetpoint
    _MTRThermostatClusterThermostatScheduleTransition.heatSetpoint = n(1)
    _ = _MTRThermostatClusterThermostatScheduleTransition.heatSetpoint
    _MTRThermostatClusterThermostatScheduleTransition.transitionTime = n(1)
    _ = _MTRThermostatClusterThermostatScheduleTransition.transitionTime
    mtrRequire(_MTRThermostatClusterThermostatScheduleTransition.description.contains("MTRThermostatClusterThermostatScheduleTransition"), "MTRThermostatClusterThermostatScheduleTransition desc")
    let _MTRThermostatClusterWeeklyScheduleTransitionStruct = MTRThermostatClusterWeeklyScheduleTransitionStruct()
    _MTRThermostatClusterWeeklyScheduleTransitionStruct.coolSetpoint = n(1)
    _ = _MTRThermostatClusterWeeklyScheduleTransitionStruct.coolSetpoint
    _MTRThermostatClusterWeeklyScheduleTransitionStruct.heatSetpoint = n(1)
    _ = _MTRThermostatClusterWeeklyScheduleTransitionStruct.heatSetpoint
    _MTRThermostatClusterWeeklyScheduleTransitionStruct.transitionTime = n(1)
    _ = _MTRThermostatClusterWeeklyScheduleTransitionStruct.transitionTime
    mtrRequire(_MTRThermostatClusterWeeklyScheduleTransitionStruct.description.contains("MTRThermostatClusterWeeklyScheduleTransitionStruct"), "MTRThermostatClusterWeeklyScheduleTransitionStruct desc")
}

func testThreadNetworkDiagnosticsParams() {
    let _MTRThreadNetworkDiagnosticsClusterConnectionStatusEvent = MTRThreadNetworkDiagnosticsClusterConnectionStatusEvent()
    _MTRThreadNetworkDiagnosticsClusterConnectionStatusEvent.connectionStatus = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterConnectionStatusEvent.connectionStatus
    mtrRequire(_MTRThreadNetworkDiagnosticsClusterConnectionStatusEvent.description.contains("MTRThreadNetworkDiagnosticsClusterConnectionStatusEvent"), "MTRThreadNetworkDiagnosticsClusterConnectionStatusEvent desc")
    let _MTRThreadNetworkDiagnosticsClusterNeighborTable = MTRThreadNetworkDiagnosticsClusterNeighborTable()
    _MTRThreadNetworkDiagnosticsClusterNeighborTable.age = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterNeighborTable.age
    _MTRThreadNetworkDiagnosticsClusterNeighborTable.averageRssi = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterNeighborTable.averageRssi
    _MTRThreadNetworkDiagnosticsClusterNeighborTable.extAddress = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterNeighborTable.extAddress
    _MTRThreadNetworkDiagnosticsClusterNeighborTable.frameErrorRate = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterNeighborTable.frameErrorRate
    _MTRThreadNetworkDiagnosticsClusterNeighborTable.fullNetworkData = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterNeighborTable.fullNetworkData
    _MTRThreadNetworkDiagnosticsClusterNeighborTable.fullThreadDevice = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterNeighborTable.fullThreadDevice
    _MTRThreadNetworkDiagnosticsClusterNeighborTable.isChild = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterNeighborTable.isChild
    _MTRThreadNetworkDiagnosticsClusterNeighborTable.lastRssi = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterNeighborTable.lastRssi
    _MTRThreadNetworkDiagnosticsClusterNeighborTable.linkFrameCounter = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterNeighborTable.linkFrameCounter
    _MTRThreadNetworkDiagnosticsClusterNeighborTable.lqi = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterNeighborTable.lqi
    _MTRThreadNetworkDiagnosticsClusterNeighborTable.messageErrorRate = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterNeighborTable.messageErrorRate
    _MTRThreadNetworkDiagnosticsClusterNeighborTable.mleFrameCounter = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterNeighborTable.mleFrameCounter
    _MTRThreadNetworkDiagnosticsClusterNeighborTable.rloc16 = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterNeighborTable.rloc16
    _MTRThreadNetworkDiagnosticsClusterNeighborTable.rxOnWhenIdle = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterNeighborTable.rxOnWhenIdle
    mtrRequire(_MTRThreadNetworkDiagnosticsClusterNeighborTable.description.contains("MTRThreadNetworkDiagnosticsClusterNeighborTable"), "MTRThreadNetworkDiagnosticsClusterNeighborTable desc")
    let _MTRThreadNetworkDiagnosticsClusterNeighborTableStruct = MTRThreadNetworkDiagnosticsClusterNeighborTableStruct()
    _MTRThreadNetworkDiagnosticsClusterNeighborTableStruct.age = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterNeighborTableStruct.age
    _MTRThreadNetworkDiagnosticsClusterNeighborTableStruct.averageRssi = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterNeighborTableStruct.averageRssi
    _MTRThreadNetworkDiagnosticsClusterNeighborTableStruct.extAddress = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterNeighborTableStruct.extAddress
    _MTRThreadNetworkDiagnosticsClusterNeighborTableStruct.frameErrorRate = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterNeighborTableStruct.frameErrorRate
    _MTRThreadNetworkDiagnosticsClusterNeighborTableStruct.fullNetworkData = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterNeighborTableStruct.fullNetworkData
    _MTRThreadNetworkDiagnosticsClusterNeighborTableStruct.fullThreadDevice = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterNeighborTableStruct.fullThreadDevice
    _MTRThreadNetworkDiagnosticsClusterNeighborTableStruct.isChild = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterNeighborTableStruct.isChild
    _MTRThreadNetworkDiagnosticsClusterNeighborTableStruct.lastRssi = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterNeighborTableStruct.lastRssi
    _MTRThreadNetworkDiagnosticsClusterNeighborTableStruct.linkFrameCounter = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterNeighborTableStruct.linkFrameCounter
    _MTRThreadNetworkDiagnosticsClusterNeighborTableStruct.lqi = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterNeighborTableStruct.lqi
    _MTRThreadNetworkDiagnosticsClusterNeighborTableStruct.messageErrorRate = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterNeighborTableStruct.messageErrorRate
    _MTRThreadNetworkDiagnosticsClusterNeighborTableStruct.mleFrameCounter = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterNeighborTableStruct.mleFrameCounter
    _MTRThreadNetworkDiagnosticsClusterNeighborTableStruct.rloc16 = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterNeighborTableStruct.rloc16
    _MTRThreadNetworkDiagnosticsClusterNeighborTableStruct.rxOnWhenIdle = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterNeighborTableStruct.rxOnWhenIdle
    mtrRequire(_MTRThreadNetworkDiagnosticsClusterNeighborTableStruct.description.contains("MTRThreadNetworkDiagnosticsClusterNeighborTableStruct"), "MTRThreadNetworkDiagnosticsClusterNeighborTableStruct desc")
    let _MTRThreadNetworkDiagnosticsClusterNetworkFaultChangeEvent = MTRThreadNetworkDiagnosticsClusterNetworkFaultChangeEvent()
    _MTRThreadNetworkDiagnosticsClusterNetworkFaultChangeEvent.current = [n(1)] as [Any]
    _ = _MTRThreadNetworkDiagnosticsClusterNetworkFaultChangeEvent.current
    _MTRThreadNetworkDiagnosticsClusterNetworkFaultChangeEvent.previous = [n(1)] as [Any]
    _ = _MTRThreadNetworkDiagnosticsClusterNetworkFaultChangeEvent.previous
    mtrRequire(_MTRThreadNetworkDiagnosticsClusterNetworkFaultChangeEvent.description.contains("MTRThreadNetworkDiagnosticsClusterNetworkFaultChangeEvent"), "MTRThreadNetworkDiagnosticsClusterNetworkFaultChangeEvent desc")
    let _MTRThreadNetworkDiagnosticsClusterOperationalDatasetComponents = MTRThreadNetworkDiagnosticsClusterOperationalDatasetComponents()
    _MTRThreadNetworkDiagnosticsClusterOperationalDatasetComponents.activeTimestampPresent = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterOperationalDatasetComponents.activeTimestampPresent
    _MTRThreadNetworkDiagnosticsClusterOperationalDatasetComponents.channelMaskPresent = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterOperationalDatasetComponents.channelMaskPresent
    _MTRThreadNetworkDiagnosticsClusterOperationalDatasetComponents.channelPresent = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterOperationalDatasetComponents.channelPresent
    _MTRThreadNetworkDiagnosticsClusterOperationalDatasetComponents.delayPresent = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterOperationalDatasetComponents.delayPresent
    _MTRThreadNetworkDiagnosticsClusterOperationalDatasetComponents.extendedPanIdPresent = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterOperationalDatasetComponents.extendedPanIdPresent
    _MTRThreadNetworkDiagnosticsClusterOperationalDatasetComponents.masterKeyPresent = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterOperationalDatasetComponents.masterKeyPresent
    _MTRThreadNetworkDiagnosticsClusterOperationalDatasetComponents.meshLocalPrefixPresent = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterOperationalDatasetComponents.meshLocalPrefixPresent
    _MTRThreadNetworkDiagnosticsClusterOperationalDatasetComponents.networkNamePresent = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterOperationalDatasetComponents.networkNamePresent
    _MTRThreadNetworkDiagnosticsClusterOperationalDatasetComponents.panIdPresent = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterOperationalDatasetComponents.panIdPresent
    _MTRThreadNetworkDiagnosticsClusterOperationalDatasetComponents.pendingTimestampPresent = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterOperationalDatasetComponents.pendingTimestampPresent
    _MTRThreadNetworkDiagnosticsClusterOperationalDatasetComponents.pskcPresent = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterOperationalDatasetComponents.pskcPresent
    _MTRThreadNetworkDiagnosticsClusterOperationalDatasetComponents.securityPolicyPresent = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterOperationalDatasetComponents.securityPolicyPresent
    mtrRequire(_MTRThreadNetworkDiagnosticsClusterOperationalDatasetComponents.description.contains("MTRThreadNetworkDiagnosticsClusterOperationalDatasetComponents"), "MTRThreadNetworkDiagnosticsClusterOperationalDatasetComponents desc")
    let _MTRThreadNetworkDiagnosticsClusterResetCountsParams = MTRThreadNetworkDiagnosticsClusterResetCountsParams()
    _MTRThreadNetworkDiagnosticsClusterResetCountsParams.serverSideProcessingTimeout = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterResetCountsParams.serverSideProcessingTimeout
    _MTRThreadNetworkDiagnosticsClusterResetCountsParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterResetCountsParams.timedInvokeTimeoutMs
    mtrRequire(_MTRThreadNetworkDiagnosticsClusterResetCountsParams.description.contains("MTRThreadNetworkDiagnosticsClusterResetCountsParams"), "MTRThreadNetworkDiagnosticsClusterResetCountsParams desc")
    let _MTRThreadNetworkDiagnosticsClusterRouteTable = MTRThreadNetworkDiagnosticsClusterRouteTable()
    _MTRThreadNetworkDiagnosticsClusterRouteTable.age = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterRouteTable.age
    _MTRThreadNetworkDiagnosticsClusterRouteTable.allocated = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterRouteTable.allocated
    _MTRThreadNetworkDiagnosticsClusterRouteTable.extAddress = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterRouteTable.extAddress
    _MTRThreadNetworkDiagnosticsClusterRouteTable.linkEstablished = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterRouteTable.linkEstablished
    _MTRThreadNetworkDiagnosticsClusterRouteTable.lqiIn = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterRouteTable.lqiIn
    _MTRThreadNetworkDiagnosticsClusterRouteTable.lqiOut = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterRouteTable.lqiOut
    _MTRThreadNetworkDiagnosticsClusterRouteTable.nextHop = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterRouteTable.nextHop
    _MTRThreadNetworkDiagnosticsClusterRouteTable.pathCost = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterRouteTable.pathCost
    _MTRThreadNetworkDiagnosticsClusterRouteTable.rloc16 = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterRouteTable.rloc16
    _MTRThreadNetworkDiagnosticsClusterRouteTable.routerId = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterRouteTable.routerId
    mtrRequire(_MTRThreadNetworkDiagnosticsClusterRouteTable.description.contains("MTRThreadNetworkDiagnosticsClusterRouteTable"), "MTRThreadNetworkDiagnosticsClusterRouteTable desc")
    let _MTRThreadNetworkDiagnosticsClusterRouteTableStruct = MTRThreadNetworkDiagnosticsClusterRouteTableStruct()
    _MTRThreadNetworkDiagnosticsClusterRouteTableStruct.age = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterRouteTableStruct.age
    _MTRThreadNetworkDiagnosticsClusterRouteTableStruct.allocated = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterRouteTableStruct.allocated
    _MTRThreadNetworkDiagnosticsClusterRouteTableStruct.extAddress = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterRouteTableStruct.extAddress
    _MTRThreadNetworkDiagnosticsClusterRouteTableStruct.linkEstablished = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterRouteTableStruct.linkEstablished
    _MTRThreadNetworkDiagnosticsClusterRouteTableStruct.lqiIn = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterRouteTableStruct.lqiIn
    _MTRThreadNetworkDiagnosticsClusterRouteTableStruct.lqiOut = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterRouteTableStruct.lqiOut
    _MTRThreadNetworkDiagnosticsClusterRouteTableStruct.nextHop = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterRouteTableStruct.nextHop
    _MTRThreadNetworkDiagnosticsClusterRouteTableStruct.pathCost = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterRouteTableStruct.pathCost
    _MTRThreadNetworkDiagnosticsClusterRouteTableStruct.rloc16 = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterRouteTableStruct.rloc16
    _MTRThreadNetworkDiagnosticsClusterRouteTableStruct.routerId = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterRouteTableStruct.routerId
    mtrRequire(_MTRThreadNetworkDiagnosticsClusterRouteTableStruct.description.contains("MTRThreadNetworkDiagnosticsClusterRouteTableStruct"), "MTRThreadNetworkDiagnosticsClusterRouteTableStruct desc")
    let _MTRThreadNetworkDiagnosticsClusterSecurityPolicy = MTRThreadNetworkDiagnosticsClusterSecurityPolicy()
    _MTRThreadNetworkDiagnosticsClusterSecurityPolicy.flags = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterSecurityPolicy.flags
    _MTRThreadNetworkDiagnosticsClusterSecurityPolicy.rotationTime = n(1)
    _ = _MTRThreadNetworkDiagnosticsClusterSecurityPolicy.rotationTime
    mtrRequire(_MTRThreadNetworkDiagnosticsClusterSecurityPolicy.description.contains("MTRThreadNetworkDiagnosticsClusterSecurityPolicy"), "MTRThreadNetworkDiagnosticsClusterSecurityPolicy desc")
}

func testUnitTestingParamsGroup1() {
    let _MTRUnitTestingClusterBooleanResponseParams = (try? MTRUnitTestingClusterBooleanResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRUnitTestingClusterBooleanResponseParams()
    _MTRUnitTestingClusterBooleanResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRUnitTestingClusterBooleanResponseParams.timedInvokeTimeoutMs
    _MTRUnitTestingClusterBooleanResponseParams.value = n(1)
    _ = _MTRUnitTestingClusterBooleanResponseParams.value
    mtrRequire(_MTRUnitTestingClusterBooleanResponseParams.description.contains("MTRUnitTestingClusterBooleanResponseParams"), "MTRUnitTestingClusterBooleanResponseParams desc")
    let _MTRUnitTestingClusterDoubleNestedStructList = MTRUnitTestingClusterDoubleNestedStructList()
    _MTRUnitTestingClusterDoubleNestedStructList.a = [n(1)] as [Any]
    _ = _MTRUnitTestingClusterDoubleNestedStructList.a
    mtrRequire(_MTRUnitTestingClusterDoubleNestedStructList.description.contains("MTRUnitTestingClusterDoubleNestedStructList"), "MTRUnitTestingClusterDoubleNestedStructList desc")
    let _MTRUnitTestingClusterNestedStruct = MTRUnitTestingClusterNestedStruct()
    _MTRUnitTestingClusterNestedStruct.a = n(1)
    _ = _MTRUnitTestingClusterNestedStruct.a
    _MTRUnitTestingClusterNestedStruct.b = n(1)
    _ = _MTRUnitTestingClusterNestedStruct.b
    _MTRUnitTestingClusterNestedStruct.c = MTRUnitTestingClusterSimpleStruct()
    _ = _MTRUnitTestingClusterNestedStruct.c
    mtrRequire(_MTRUnitTestingClusterNestedStruct.description.contains("MTRUnitTestingClusterNestedStruct"), "MTRUnitTestingClusterNestedStruct desc")
    let _MTRUnitTestingClusterNestedStructList = MTRUnitTestingClusterNestedStructList()
    _MTRUnitTestingClusterNestedStructList.a = n(1)
    _ = _MTRUnitTestingClusterNestedStructList.a
    _MTRUnitTestingClusterNestedStructList.b = n(1)
    _ = _MTRUnitTestingClusterNestedStructList.b
    _MTRUnitTestingClusterNestedStructList.c = MTRUnitTestingClusterSimpleStruct()
    _ = _MTRUnitTestingClusterNestedStructList.c
    _MTRUnitTestingClusterNestedStructList.d = [n(1)] as [Any]
    _ = _MTRUnitTestingClusterNestedStructList.d
    _MTRUnitTestingClusterNestedStructList.e = [n(1)] as [Any]
    _ = _MTRUnitTestingClusterNestedStructList.e
    _MTRUnitTestingClusterNestedStructList.f = [n(1)] as [Any]
    _ = _MTRUnitTestingClusterNestedStructList.f
    _MTRUnitTestingClusterNestedStructList.g = [n(1)] as [Any]
    _ = _MTRUnitTestingClusterNestedStructList.g
    mtrRequire(_MTRUnitTestingClusterNestedStructList.description.contains("MTRUnitTestingClusterNestedStructList"), "MTRUnitTestingClusterNestedStructList desc")
    let _MTRUnitTestingClusterNullablesAndOptionalsStruct = MTRUnitTestingClusterNullablesAndOptionalsStruct()
    _MTRUnitTestingClusterNullablesAndOptionalsStruct.nullableInt = n(1)
    _ = _MTRUnitTestingClusterNullablesAndOptionalsStruct.nullableInt
    _MTRUnitTestingClusterNullablesAndOptionalsStruct.nullableList = [n(1)] as [Any]
    _ = _MTRUnitTestingClusterNullablesAndOptionalsStruct.nullableList
    _MTRUnitTestingClusterNullablesAndOptionalsStruct.nullableOptionalInt = n(1)
    _ = _MTRUnitTestingClusterNullablesAndOptionalsStruct.nullableOptionalInt
    _MTRUnitTestingClusterNullablesAndOptionalsStruct.nullableOptionalList = [n(1)] as [Any]
    _ = _MTRUnitTestingClusterNullablesAndOptionalsStruct.nullableOptionalList
    _MTRUnitTestingClusterNullablesAndOptionalsStruct.nullableOptionalString = "x"
    _ = _MTRUnitTestingClusterNullablesAndOptionalsStruct.nullableOptionalString
    _MTRUnitTestingClusterNullablesAndOptionalsStruct.nullableOptionalStruct = MTRUnitTestingClusterSimpleStruct()
    _ = _MTRUnitTestingClusterNullablesAndOptionalsStruct.nullableOptionalStruct
    _MTRUnitTestingClusterNullablesAndOptionalsStruct.nullableString = "x"
    _ = _MTRUnitTestingClusterNullablesAndOptionalsStruct.nullableString
    _MTRUnitTestingClusterNullablesAndOptionalsStruct.nullableStruct = MTRUnitTestingClusterSimpleStruct()
    _ = _MTRUnitTestingClusterNullablesAndOptionalsStruct.nullableStruct
    _MTRUnitTestingClusterNullablesAndOptionalsStruct.optionalInt = n(1)
    _ = _MTRUnitTestingClusterNullablesAndOptionalsStruct.optionalInt
    _MTRUnitTestingClusterNullablesAndOptionalsStruct.optionalList = [n(1)] as [Any]
    _ = _MTRUnitTestingClusterNullablesAndOptionalsStruct.optionalList
    _MTRUnitTestingClusterNullablesAndOptionalsStruct.optionalString = "x"
    _ = _MTRUnitTestingClusterNullablesAndOptionalsStruct.optionalString
    _MTRUnitTestingClusterNullablesAndOptionalsStruct.optionalStruct = MTRUnitTestingClusterSimpleStruct()
    _ = _MTRUnitTestingClusterNullablesAndOptionalsStruct.optionalStruct
    mtrRequire(_MTRUnitTestingClusterNullablesAndOptionalsStruct.description.contains("MTRUnitTestingClusterNullablesAndOptionalsStruct"), "MTRUnitTestingClusterNullablesAndOptionalsStruct desc")
    let _MTRUnitTestingClusterSimpleStruct = MTRUnitTestingClusterSimpleStruct()
    _MTRUnitTestingClusterSimpleStruct.a = n(1)
    _ = _MTRUnitTestingClusterSimpleStruct.a
    _MTRUnitTestingClusterSimpleStruct.b = n(1)
    _ = _MTRUnitTestingClusterSimpleStruct.b
    _MTRUnitTestingClusterSimpleStruct.c = n(1)
    _ = _MTRUnitTestingClusterSimpleStruct.c
    _MTRUnitTestingClusterSimpleStruct.d = Data([1])
    _ = _MTRUnitTestingClusterSimpleStruct.d
    _MTRUnitTestingClusterSimpleStruct.e = "x"
    _ = _MTRUnitTestingClusterSimpleStruct.e
    _MTRUnitTestingClusterSimpleStruct.f = n(1)
    _ = _MTRUnitTestingClusterSimpleStruct.f
    _MTRUnitTestingClusterSimpleStruct.g = n(1)
    _ = _MTRUnitTestingClusterSimpleStruct.g
    _MTRUnitTestingClusterSimpleStruct.h = n(1)
    _ = _MTRUnitTestingClusterSimpleStruct.h
    mtrRequire(_MTRUnitTestingClusterSimpleStruct.description.contains("MTRUnitTestingClusterSimpleStruct"), "MTRUnitTestingClusterSimpleStruct desc")
    let _MTRUnitTestingClusterSimpleStructEchoRequestParams = MTRUnitTestingClusterSimpleStructEchoRequestParams()
    _MTRUnitTestingClusterSimpleStructEchoRequestParams.arg1 = MTRUnitTestingClusterSimpleStruct()
    _ = _MTRUnitTestingClusterSimpleStructEchoRequestParams.arg1
    _MTRUnitTestingClusterSimpleStructEchoRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRUnitTestingClusterSimpleStructEchoRequestParams.serverSideProcessingTimeout
    _MTRUnitTestingClusterSimpleStructEchoRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRUnitTestingClusterSimpleStructEchoRequestParams.timedInvokeTimeoutMs
    mtrRequire(_MTRUnitTestingClusterSimpleStructEchoRequestParams.description.contains("MTRUnitTestingClusterSimpleStructEchoRequestParams"), "MTRUnitTestingClusterSimpleStructEchoRequestParams desc")
    let _MTRUnitTestingClusterSimpleStructResponseParams = (try? MTRUnitTestingClusterSimpleStructResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRUnitTestingClusterSimpleStructResponseParams()
    _MTRUnitTestingClusterSimpleStructResponseParams.arg1 = MTRUnitTestingClusterSimpleStruct()
    _ = _MTRUnitTestingClusterSimpleStructResponseParams.arg1
    _MTRUnitTestingClusterSimpleStructResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRUnitTestingClusterSimpleStructResponseParams.timedInvokeTimeoutMs
    mtrRequire(_MTRUnitTestingClusterSimpleStructResponseParams.description.contains("MTRUnitTestingClusterSimpleStructResponseParams"), "MTRUnitTestingClusterSimpleStructResponseParams desc")
    let _MTRUnitTestingClusterTestAddArgumentsParams = MTRUnitTestingClusterTestAddArgumentsParams()
    _MTRUnitTestingClusterTestAddArgumentsParams.arg1 = n(1)
    _ = _MTRUnitTestingClusterTestAddArgumentsParams.arg1
    _MTRUnitTestingClusterTestAddArgumentsParams.arg2 = n(1)
    _ = _MTRUnitTestingClusterTestAddArgumentsParams.arg2
    _MTRUnitTestingClusterTestAddArgumentsParams.serverSideProcessingTimeout = n(1)
    _ = _MTRUnitTestingClusterTestAddArgumentsParams.serverSideProcessingTimeout
    _MTRUnitTestingClusterTestAddArgumentsParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRUnitTestingClusterTestAddArgumentsParams.timedInvokeTimeoutMs
    mtrRequire(_MTRUnitTestingClusterTestAddArgumentsParams.description.contains("MTRUnitTestingClusterTestAddArgumentsParams"), "MTRUnitTestingClusterTestAddArgumentsParams desc")
    let _MTRUnitTestingClusterTestAddArgumentsResponseParams = (try? MTRUnitTestingClusterTestAddArgumentsResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRUnitTestingClusterTestAddArgumentsResponseParams()
    _MTRUnitTestingClusterTestAddArgumentsResponseParams.returnValue = n(1)
    _ = _MTRUnitTestingClusterTestAddArgumentsResponseParams.returnValue
    _MTRUnitTestingClusterTestAddArgumentsResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRUnitTestingClusterTestAddArgumentsResponseParams.timedInvokeTimeoutMs
    mtrRequire(_MTRUnitTestingClusterTestAddArgumentsResponseParams.description.contains("MTRUnitTestingClusterTestAddArgumentsResponseParams"), "MTRUnitTestingClusterTestAddArgumentsResponseParams desc")
    let _MTRUnitTestingClusterTestComplexNullableOptionalRequestParams = MTRUnitTestingClusterTestComplexNullableOptionalRequestParams()
    _MTRUnitTestingClusterTestComplexNullableOptionalRequestParams.nullableInt = n(1)
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalRequestParams.nullableInt
    _MTRUnitTestingClusterTestComplexNullableOptionalRequestParams.nullableList = [n(1)] as [Any]
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalRequestParams.nullableList
    _MTRUnitTestingClusterTestComplexNullableOptionalRequestParams.nullableOptionalInt = n(1)
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalRequestParams.nullableOptionalInt
    _MTRUnitTestingClusterTestComplexNullableOptionalRequestParams.nullableOptionalList = [n(1)] as [Any]
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalRequestParams.nullableOptionalList
    _MTRUnitTestingClusterTestComplexNullableOptionalRequestParams.nullableOptionalString = "x"
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalRequestParams.nullableOptionalString
    _MTRUnitTestingClusterTestComplexNullableOptionalRequestParams.nullableOptionalStruct = MTRUnitTestingClusterSimpleStruct()
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalRequestParams.nullableOptionalStruct
    _MTRUnitTestingClusterTestComplexNullableOptionalRequestParams.nullableString = "x"
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalRequestParams.nullableString
    _MTRUnitTestingClusterTestComplexNullableOptionalRequestParams.nullableStruct = MTRUnitTestingClusterSimpleStruct()
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalRequestParams.nullableStruct
    _MTRUnitTestingClusterTestComplexNullableOptionalRequestParams.optionalInt = n(1)
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalRequestParams.optionalInt
    _MTRUnitTestingClusterTestComplexNullableOptionalRequestParams.optionalList = [n(1)] as [Any]
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalRequestParams.optionalList
    _MTRUnitTestingClusterTestComplexNullableOptionalRequestParams.optionalString = "x"
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalRequestParams.optionalString
    _MTRUnitTestingClusterTestComplexNullableOptionalRequestParams.optionalStruct = MTRUnitTestingClusterSimpleStruct()
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalRequestParams.optionalStruct
    _MTRUnitTestingClusterTestComplexNullableOptionalRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalRequestParams.serverSideProcessingTimeout
    _MTRUnitTestingClusterTestComplexNullableOptionalRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalRequestParams.timedInvokeTimeoutMs
    mtrRequire(_MTRUnitTestingClusterTestComplexNullableOptionalRequestParams.description.contains("MTRUnitTestingClusterTestComplexNullableOptionalRequestParams"), "MTRUnitTestingClusterTestComplexNullableOptionalRequestParams desc")
    let _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams = (try? MTRUnitTestingClusterTestComplexNullableOptionalResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRUnitTestingClusterTestComplexNullableOptionalResponseParams()
    _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.nullableIntValue = n(1)
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.nullableIntValue
    _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.nullableIntWasNull = n(1)
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.nullableIntWasNull
    _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.nullableListValue = [n(1)] as [Any]
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.nullableListValue
    _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.nullableListWasNull = n(1)
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.nullableListWasNull
    _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.nullableOptionalIntValue = n(1)
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.nullableOptionalIntValue
    _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.nullableOptionalIntWasNull = n(1)
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.nullableOptionalIntWasNull
    _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.nullableOptionalIntWasPresent = n(1)
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.nullableOptionalIntWasPresent
    _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.nullableOptionalListValue = [n(1)] as [Any]
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.nullableOptionalListValue
    _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.nullableOptionalListWasNull = n(1)
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.nullableOptionalListWasNull
    _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.nullableOptionalListWasPresent = n(1)
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.nullableOptionalListWasPresent
    _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.nullableOptionalStringValue = "x"
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.nullableOptionalStringValue
    _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.nullableOptionalStringWasNull = n(1)
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.nullableOptionalStringWasNull
    _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.nullableOptionalStringWasPresent = n(1)
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.nullableOptionalStringWasPresent
    _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.nullableOptionalStructValue = MTRUnitTestingClusterSimpleStruct()
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.nullableOptionalStructValue
    _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.nullableOptionalStructWasNull = n(1)
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.nullableOptionalStructWasNull
    _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.nullableOptionalStructWasPresent = n(1)
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.nullableOptionalStructWasPresent
    _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.nullableStringValue = "x"
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.nullableStringValue
    _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.nullableStringWasNull = n(1)
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.nullableStringWasNull
    _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.nullableStructValue = MTRUnitTestingClusterSimpleStruct()
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.nullableStructValue
    _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.nullableStructWasNull = n(1)
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.nullableStructWasNull
    _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.optionalIntValue = n(1)
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.optionalIntValue
    _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.optionalIntWasPresent = n(1)
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.optionalIntWasPresent
    _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.optionalListValue = [n(1)] as [Any]
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.optionalListValue
    _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.optionalListWasPresent = n(1)
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.optionalListWasPresent
    _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.optionalStringValue = "x"
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.optionalStringValue
    _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.optionalStringWasPresent = n(1)
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.optionalStringWasPresent
    _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.optionalStructValue = MTRUnitTestingClusterSimpleStruct()
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.optionalStructValue
    _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.optionalStructWasPresent = n(1)
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.optionalStructWasPresent
    _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.timedInvokeTimeoutMs
    mtrRequire(_MTRUnitTestingClusterTestComplexNullableOptionalResponseParams.description.contains("MTRUnitTestingClusterTestComplexNullableOptionalResponseParams"), "MTRUnitTestingClusterTestComplexNullableOptionalResponseParams desc")
    let _MTRUnitTestingClusterTestEmitTestEventRequestParams = MTRUnitTestingClusterTestEmitTestEventRequestParams()
    _MTRUnitTestingClusterTestEmitTestEventRequestParams.arg1 = n(1)
    _ = _MTRUnitTestingClusterTestEmitTestEventRequestParams.arg1
    _MTRUnitTestingClusterTestEmitTestEventRequestParams.arg2 = n(1)
    _ = _MTRUnitTestingClusterTestEmitTestEventRequestParams.arg2
    _MTRUnitTestingClusterTestEmitTestEventRequestParams.arg3 = n(1)
    _ = _MTRUnitTestingClusterTestEmitTestEventRequestParams.arg3
    _MTRUnitTestingClusterTestEmitTestEventRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRUnitTestingClusterTestEmitTestEventRequestParams.serverSideProcessingTimeout
    _MTRUnitTestingClusterTestEmitTestEventRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRUnitTestingClusterTestEmitTestEventRequestParams.timedInvokeTimeoutMs
    mtrRequire(_MTRUnitTestingClusterTestEmitTestEventRequestParams.description.contains("MTRUnitTestingClusterTestEmitTestEventRequestParams"), "MTRUnitTestingClusterTestEmitTestEventRequestParams desc")
    let _MTRUnitTestingClusterTestEmitTestEventResponseParams = (try? MTRUnitTestingClusterTestEmitTestEventResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRUnitTestingClusterTestEmitTestEventResponseParams()
    _MTRUnitTestingClusterTestEmitTestEventResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRUnitTestingClusterTestEmitTestEventResponseParams.timedInvokeTimeoutMs
    _MTRUnitTestingClusterTestEmitTestEventResponseParams.value = n(1)
    _ = _MTRUnitTestingClusterTestEmitTestEventResponseParams.value
    mtrRequire(_MTRUnitTestingClusterTestEmitTestEventResponseParams.description.contains("MTRUnitTestingClusterTestEmitTestEventResponseParams"), "MTRUnitTestingClusterTestEmitTestEventResponseParams desc")
    let _MTRUnitTestingClusterTestEmitTestFabricScopedEventRequestParams = MTRUnitTestingClusterTestEmitTestFabricScopedEventRequestParams()
    _MTRUnitTestingClusterTestEmitTestFabricScopedEventRequestParams.arg1 = n(1)
    _ = _MTRUnitTestingClusterTestEmitTestFabricScopedEventRequestParams.arg1
    _MTRUnitTestingClusterTestEmitTestFabricScopedEventRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRUnitTestingClusterTestEmitTestFabricScopedEventRequestParams.serverSideProcessingTimeout
    _MTRUnitTestingClusterTestEmitTestFabricScopedEventRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRUnitTestingClusterTestEmitTestFabricScopedEventRequestParams.timedInvokeTimeoutMs
    mtrRequire(_MTRUnitTestingClusterTestEmitTestFabricScopedEventRequestParams.description.contains("MTRUnitTestingClusterTestEmitTestFabricScopedEventRequestParams"), "MTRUnitTestingClusterTestEmitTestFabricScopedEventRequestParams desc")
    let _MTRUnitTestingClusterTestEmitTestFabricScopedEventResponseParams = (try? MTRUnitTestingClusterTestEmitTestFabricScopedEventResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRUnitTestingClusterTestEmitTestFabricScopedEventResponseParams()
    _MTRUnitTestingClusterTestEmitTestFabricScopedEventResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRUnitTestingClusterTestEmitTestFabricScopedEventResponseParams.timedInvokeTimeoutMs
    _MTRUnitTestingClusterTestEmitTestFabricScopedEventResponseParams.value = n(1)
    _ = _MTRUnitTestingClusterTestEmitTestFabricScopedEventResponseParams.value
    mtrRequire(_MTRUnitTestingClusterTestEmitTestFabricScopedEventResponseParams.description.contains("MTRUnitTestingClusterTestEmitTestFabricScopedEventResponseParams"), "MTRUnitTestingClusterTestEmitTestFabricScopedEventResponseParams desc")
    let _MTRUnitTestingClusterTestEnumsRequestParams = MTRUnitTestingClusterTestEnumsRequestParams()
    _MTRUnitTestingClusterTestEnumsRequestParams.arg1 = n(1)
    _ = _MTRUnitTestingClusterTestEnumsRequestParams.arg1
    _MTRUnitTestingClusterTestEnumsRequestParams.arg2 = n(1)
    _ = _MTRUnitTestingClusterTestEnumsRequestParams.arg2
    _MTRUnitTestingClusterTestEnumsRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRUnitTestingClusterTestEnumsRequestParams.serverSideProcessingTimeout
    _MTRUnitTestingClusterTestEnumsRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRUnitTestingClusterTestEnumsRequestParams.timedInvokeTimeoutMs
    mtrRequire(_MTRUnitTestingClusterTestEnumsRequestParams.description.contains("MTRUnitTestingClusterTestEnumsRequestParams"), "MTRUnitTestingClusterTestEnumsRequestParams desc")
    let _MTRUnitTestingClusterTestEnumsResponseParams = (try? MTRUnitTestingClusterTestEnumsResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRUnitTestingClusterTestEnumsResponseParams()
    _MTRUnitTestingClusterTestEnumsResponseParams.arg1 = n(1)
    _ = _MTRUnitTestingClusterTestEnumsResponseParams.arg1
    _MTRUnitTestingClusterTestEnumsResponseParams.arg2 = n(1)
    _ = _MTRUnitTestingClusterTestEnumsResponseParams.arg2
    _MTRUnitTestingClusterTestEnumsResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRUnitTestingClusterTestEnumsResponseParams.timedInvokeTimeoutMs
    mtrRequire(_MTRUnitTestingClusterTestEnumsResponseParams.description.contains("MTRUnitTestingClusterTestEnumsResponseParams"), "MTRUnitTestingClusterTestEnumsResponseParams desc")
    let _MTRUnitTestingClusterTestEventEvent = MTRUnitTestingClusterTestEventEvent()
    _MTRUnitTestingClusterTestEventEvent.arg1 = n(1)
    _ = _MTRUnitTestingClusterTestEventEvent.arg1
    _MTRUnitTestingClusterTestEventEvent.arg2 = n(1)
    _ = _MTRUnitTestingClusterTestEventEvent.arg2
    _MTRUnitTestingClusterTestEventEvent.arg3 = n(1)
    _ = _MTRUnitTestingClusterTestEventEvent.arg3
    _MTRUnitTestingClusterTestEventEvent.arg4 = MTRUnitTestingClusterSimpleStruct()
    _ = _MTRUnitTestingClusterTestEventEvent.arg4
    _MTRUnitTestingClusterTestEventEvent.arg5 = [n(1)] as [Any]
    _ = _MTRUnitTestingClusterTestEventEvent.arg5
    _MTRUnitTestingClusterTestEventEvent.arg6 = [n(1)] as [Any]
    _ = _MTRUnitTestingClusterTestEventEvent.arg6
    mtrRequire(_MTRUnitTestingClusterTestEventEvent.description.contains("MTRUnitTestingClusterTestEventEvent"), "MTRUnitTestingClusterTestEventEvent desc")
    let _MTRUnitTestingClusterTestFabricScoped = MTRUnitTestingClusterTestFabricScoped()
    _MTRUnitTestingClusterTestFabricScoped.fabricIndex = n(1)
    _ = _MTRUnitTestingClusterTestFabricScoped.fabricIndex
    _MTRUnitTestingClusterTestFabricScoped.fabricSensitiveCharString = "x"
    _ = _MTRUnitTestingClusterTestFabricScoped.fabricSensitiveCharString
    _MTRUnitTestingClusterTestFabricScoped.fabricSensitiveInt8u = n(1)
    _ = _MTRUnitTestingClusterTestFabricScoped.fabricSensitiveInt8u
    _MTRUnitTestingClusterTestFabricScoped.fabricSensitiveInt8uList = [n(1)] as [Any]
    _ = _MTRUnitTestingClusterTestFabricScoped.fabricSensitiveInt8uList
    _MTRUnitTestingClusterTestFabricScoped.fabricSensitiveStruct = MTRUnitTestingClusterSimpleStruct()
    _ = _MTRUnitTestingClusterTestFabricScoped.fabricSensitiveStruct
    _MTRUnitTestingClusterTestFabricScoped.nullableFabricSensitiveInt8u = n(1)
    _ = _MTRUnitTestingClusterTestFabricScoped.nullableFabricSensitiveInt8u
    _MTRUnitTestingClusterTestFabricScoped.nullableOptionalFabricSensitiveInt8u = n(1)
    _ = _MTRUnitTestingClusterTestFabricScoped.nullableOptionalFabricSensitiveInt8u
    _MTRUnitTestingClusterTestFabricScoped.optionalFabricSensitiveInt8u = n(1)
    _ = _MTRUnitTestingClusterTestFabricScoped.optionalFabricSensitiveInt8u
    mtrRequire(_MTRUnitTestingClusterTestFabricScoped.description.contains("MTRUnitTestingClusterTestFabricScoped"), "MTRUnitTestingClusterTestFabricScoped desc")
    let _MTRUnitTestingClusterTestFabricScopedEventEvent = MTRUnitTestingClusterTestFabricScopedEventEvent()
    _MTRUnitTestingClusterTestFabricScopedEventEvent.fabricIndex = n(1)
    _ = _MTRUnitTestingClusterTestFabricScopedEventEvent.fabricIndex
    mtrRequire(_MTRUnitTestingClusterTestFabricScopedEventEvent.description.contains("MTRUnitTestingClusterTestFabricScopedEventEvent"), "MTRUnitTestingClusterTestFabricScopedEventEvent desc")
    let _MTRUnitTestingClusterTestListInt8UArgumentRequestParams = MTRUnitTestingClusterTestListInt8UArgumentRequestParams()
    _MTRUnitTestingClusterTestListInt8UArgumentRequestParams.arg1 = [n(1)] as [Any]
    _ = _MTRUnitTestingClusterTestListInt8UArgumentRequestParams.arg1
    _MTRUnitTestingClusterTestListInt8UArgumentRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRUnitTestingClusterTestListInt8UArgumentRequestParams.serverSideProcessingTimeout
    _MTRUnitTestingClusterTestListInt8UArgumentRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRUnitTestingClusterTestListInt8UArgumentRequestParams.timedInvokeTimeoutMs
    mtrRequire(_MTRUnitTestingClusterTestListInt8UArgumentRequestParams.description.contains("MTRUnitTestingClusterTestListInt8UArgumentRequestParams"), "MTRUnitTestingClusterTestListInt8UArgumentRequestParams desc")
    let _MTRUnitTestingClusterTestListInt8UReverseRequestParams = MTRUnitTestingClusterTestListInt8UReverseRequestParams()
    _MTRUnitTestingClusterTestListInt8UReverseRequestParams.arg1 = [n(1)] as [Any]
    _ = _MTRUnitTestingClusterTestListInt8UReverseRequestParams.arg1
    _MTRUnitTestingClusterTestListInt8UReverseRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRUnitTestingClusterTestListInt8UReverseRequestParams.serverSideProcessingTimeout
    _MTRUnitTestingClusterTestListInt8UReverseRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRUnitTestingClusterTestListInt8UReverseRequestParams.timedInvokeTimeoutMs
    mtrRequire(_MTRUnitTestingClusterTestListInt8UReverseRequestParams.description.contains("MTRUnitTestingClusterTestListInt8UReverseRequestParams"), "MTRUnitTestingClusterTestListInt8UReverseRequestParams desc")
}

func testUnitTestingParamsGroup2() {
    let _MTRUnitTestingClusterTestListInt8UReverseResponseParams = (try? MTRUnitTestingClusterTestListInt8UReverseResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRUnitTestingClusterTestListInt8UReverseResponseParams()
    _MTRUnitTestingClusterTestListInt8UReverseResponseParams.arg1 = [n(1)] as [Any]
    _ = _MTRUnitTestingClusterTestListInt8UReverseResponseParams.arg1
    _MTRUnitTestingClusterTestListInt8UReverseResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRUnitTestingClusterTestListInt8UReverseResponseParams.timedInvokeTimeoutMs
    mtrRequire(_MTRUnitTestingClusterTestListInt8UReverseResponseParams.description.contains("MTRUnitTestingClusterTestListInt8UReverseResponseParams"), "MTRUnitTestingClusterTestListInt8UReverseResponseParams desc")
    let _MTRUnitTestingClusterTestListNestedStructListArgumentRequestParams = MTRUnitTestingClusterTestListNestedStructListArgumentRequestParams()
    _MTRUnitTestingClusterTestListNestedStructListArgumentRequestParams.arg1 = [n(1)] as [Any]
    _ = _MTRUnitTestingClusterTestListNestedStructListArgumentRequestParams.arg1
    _MTRUnitTestingClusterTestListNestedStructListArgumentRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRUnitTestingClusterTestListNestedStructListArgumentRequestParams.serverSideProcessingTimeout
    _MTRUnitTestingClusterTestListNestedStructListArgumentRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRUnitTestingClusterTestListNestedStructListArgumentRequestParams.timedInvokeTimeoutMs
    mtrRequire(_MTRUnitTestingClusterTestListNestedStructListArgumentRequestParams.description.contains("MTRUnitTestingClusterTestListNestedStructListArgumentRequestParams"), "MTRUnitTestingClusterTestListNestedStructListArgumentRequestParams desc")
    let _MTRUnitTestingClusterTestListStructArgumentRequestParams = MTRUnitTestingClusterTestListStructArgumentRequestParams()
    _MTRUnitTestingClusterTestListStructArgumentRequestParams.arg1 = [n(1)] as [Any]
    _ = _MTRUnitTestingClusterTestListStructArgumentRequestParams.arg1
    _MTRUnitTestingClusterTestListStructArgumentRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRUnitTestingClusterTestListStructArgumentRequestParams.serverSideProcessingTimeout
    _MTRUnitTestingClusterTestListStructArgumentRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRUnitTestingClusterTestListStructArgumentRequestParams.timedInvokeTimeoutMs
    mtrRequire(_MTRUnitTestingClusterTestListStructArgumentRequestParams.description.contains("MTRUnitTestingClusterTestListStructArgumentRequestParams"), "MTRUnitTestingClusterTestListStructArgumentRequestParams desc")
    let _MTRUnitTestingClusterTestListStructOctet = MTRUnitTestingClusterTestListStructOctet()
    _MTRUnitTestingClusterTestListStructOctet.member1 = n(1)
    _ = _MTRUnitTestingClusterTestListStructOctet.member1
    _MTRUnitTestingClusterTestListStructOctet.member2 = Data([1])
    _ = _MTRUnitTestingClusterTestListStructOctet.member2
    mtrRequire(_MTRUnitTestingClusterTestListStructOctet.description.contains("MTRUnitTestingClusterTestListStructOctet"), "MTRUnitTestingClusterTestListStructOctet desc")
    let _MTRUnitTestingClusterTestNestedStructArgumentRequestParams = MTRUnitTestingClusterTestNestedStructArgumentRequestParams()
    _MTRUnitTestingClusterTestNestedStructArgumentRequestParams.arg1 = MTRUnitTestingClusterNestedStruct()
    _ = _MTRUnitTestingClusterTestNestedStructArgumentRequestParams.arg1
    _MTRUnitTestingClusterTestNestedStructArgumentRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRUnitTestingClusterTestNestedStructArgumentRequestParams.serverSideProcessingTimeout
    _MTRUnitTestingClusterTestNestedStructArgumentRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRUnitTestingClusterTestNestedStructArgumentRequestParams.timedInvokeTimeoutMs
    mtrRequire(_MTRUnitTestingClusterTestNestedStructArgumentRequestParams.description.contains("MTRUnitTestingClusterTestNestedStructArgumentRequestParams"), "MTRUnitTestingClusterTestNestedStructArgumentRequestParams desc")
    let _MTRUnitTestingClusterTestNestedStructListArgumentRequestParams = MTRUnitTestingClusterTestNestedStructListArgumentRequestParams()
    _MTRUnitTestingClusterTestNestedStructListArgumentRequestParams.arg1 = MTRUnitTestingClusterNestedStructList()
    _ = _MTRUnitTestingClusterTestNestedStructListArgumentRequestParams.arg1
    _MTRUnitTestingClusterTestNestedStructListArgumentRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRUnitTestingClusterTestNestedStructListArgumentRequestParams.serverSideProcessingTimeout
    _MTRUnitTestingClusterTestNestedStructListArgumentRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRUnitTestingClusterTestNestedStructListArgumentRequestParams.timedInvokeTimeoutMs
    mtrRequire(_MTRUnitTestingClusterTestNestedStructListArgumentRequestParams.description.contains("MTRUnitTestingClusterTestNestedStructListArgumentRequestParams"), "MTRUnitTestingClusterTestNestedStructListArgumentRequestParams desc")
    let _MTRUnitTestingClusterTestNotHandledParams = MTRUnitTestingClusterTestNotHandledParams()
    _MTRUnitTestingClusterTestNotHandledParams.serverSideProcessingTimeout = n(1)
    _ = _MTRUnitTestingClusterTestNotHandledParams.serverSideProcessingTimeout
    _MTRUnitTestingClusterTestNotHandledParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRUnitTestingClusterTestNotHandledParams.timedInvokeTimeoutMs
    mtrRequire(_MTRUnitTestingClusterTestNotHandledParams.description.contains("MTRUnitTestingClusterTestNotHandledParams"), "MTRUnitTestingClusterTestNotHandledParams desc")
    let _MTRUnitTestingClusterTestNullableOptionalRequestParams = MTRUnitTestingClusterTestNullableOptionalRequestParams()
    _MTRUnitTestingClusterTestNullableOptionalRequestParams.arg1 = n(1)
    _ = _MTRUnitTestingClusterTestNullableOptionalRequestParams.arg1
    _MTRUnitTestingClusterTestNullableOptionalRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRUnitTestingClusterTestNullableOptionalRequestParams.serverSideProcessingTimeout
    _MTRUnitTestingClusterTestNullableOptionalRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRUnitTestingClusterTestNullableOptionalRequestParams.timedInvokeTimeoutMs
    mtrRequire(_MTRUnitTestingClusterTestNullableOptionalRequestParams.description.contains("MTRUnitTestingClusterTestNullableOptionalRequestParams"), "MTRUnitTestingClusterTestNullableOptionalRequestParams desc")
    let _MTRUnitTestingClusterTestNullableOptionalResponseParams = (try? MTRUnitTestingClusterTestNullableOptionalResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRUnitTestingClusterTestNullableOptionalResponseParams()
    _MTRUnitTestingClusterTestNullableOptionalResponseParams.originalValue = n(1)
    _ = _MTRUnitTestingClusterTestNullableOptionalResponseParams.originalValue
    _MTRUnitTestingClusterTestNullableOptionalResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRUnitTestingClusterTestNullableOptionalResponseParams.timedInvokeTimeoutMs
    _MTRUnitTestingClusterTestNullableOptionalResponseParams.value = n(1)
    _ = _MTRUnitTestingClusterTestNullableOptionalResponseParams.value
    _MTRUnitTestingClusterTestNullableOptionalResponseParams.wasNull = n(1)
    _ = _MTRUnitTestingClusterTestNullableOptionalResponseParams.wasNull
    _MTRUnitTestingClusterTestNullableOptionalResponseParams.wasPresent = n(1)
    _ = _MTRUnitTestingClusterTestNullableOptionalResponseParams.wasPresent
    mtrRequire(_MTRUnitTestingClusterTestNullableOptionalResponseParams.description.contains("MTRUnitTestingClusterTestNullableOptionalResponseParams"), "MTRUnitTestingClusterTestNullableOptionalResponseParams desc")
    let _MTRUnitTestingClusterTestParams = MTRUnitTestingClusterTestParams()
    _MTRUnitTestingClusterTestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRUnitTestingClusterTestParams.serverSideProcessingTimeout
    _MTRUnitTestingClusterTestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRUnitTestingClusterTestParams.timedInvokeTimeoutMs
    mtrRequire(_MTRUnitTestingClusterTestParams.description.contains("MTRUnitTestingClusterTestParams"), "MTRUnitTestingClusterTestParams desc")
    let _MTRUnitTestingClusterTestSimpleArgumentRequestParams = MTRUnitTestingClusterTestSimpleArgumentRequestParams()
    _MTRUnitTestingClusterTestSimpleArgumentRequestParams.arg1 = n(1)
    _ = _MTRUnitTestingClusterTestSimpleArgumentRequestParams.arg1
    _MTRUnitTestingClusterTestSimpleArgumentRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRUnitTestingClusterTestSimpleArgumentRequestParams.serverSideProcessingTimeout
    _MTRUnitTestingClusterTestSimpleArgumentRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRUnitTestingClusterTestSimpleArgumentRequestParams.timedInvokeTimeoutMs
    mtrRequire(_MTRUnitTestingClusterTestSimpleArgumentRequestParams.description.contains("MTRUnitTestingClusterTestSimpleArgumentRequestParams"), "MTRUnitTestingClusterTestSimpleArgumentRequestParams desc")
    let _MTRUnitTestingClusterTestSimpleArgumentResponseParams = (try? MTRUnitTestingClusterTestSimpleArgumentResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRUnitTestingClusterTestSimpleArgumentResponseParams()
    _MTRUnitTestingClusterTestSimpleArgumentResponseParams.returnValue = n(1)
    _ = _MTRUnitTestingClusterTestSimpleArgumentResponseParams.returnValue
    _MTRUnitTestingClusterTestSimpleArgumentResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRUnitTestingClusterTestSimpleArgumentResponseParams.timedInvokeTimeoutMs
    mtrRequire(_MTRUnitTestingClusterTestSimpleArgumentResponseParams.description.contains("MTRUnitTestingClusterTestSimpleArgumentResponseParams"), "MTRUnitTestingClusterTestSimpleArgumentResponseParams desc")
    let _MTRUnitTestingClusterTestSimpleOptionalArgumentRequestParams = MTRUnitTestingClusterTestSimpleOptionalArgumentRequestParams()
    _MTRUnitTestingClusterTestSimpleOptionalArgumentRequestParams.arg1 = n(1)
    _ = _MTRUnitTestingClusterTestSimpleOptionalArgumentRequestParams.arg1
    _MTRUnitTestingClusterTestSimpleOptionalArgumentRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRUnitTestingClusterTestSimpleOptionalArgumentRequestParams.serverSideProcessingTimeout
    _MTRUnitTestingClusterTestSimpleOptionalArgumentRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRUnitTestingClusterTestSimpleOptionalArgumentRequestParams.timedInvokeTimeoutMs
    mtrRequire(_MTRUnitTestingClusterTestSimpleOptionalArgumentRequestParams.description.contains("MTRUnitTestingClusterTestSimpleOptionalArgumentRequestParams"), "MTRUnitTestingClusterTestSimpleOptionalArgumentRequestParams desc")
    let _MTRUnitTestingClusterTestSpecificParams = MTRUnitTestingClusterTestSpecificParams()
    _MTRUnitTestingClusterTestSpecificParams.serverSideProcessingTimeout = n(1)
    _ = _MTRUnitTestingClusterTestSpecificParams.serverSideProcessingTimeout
    _MTRUnitTestingClusterTestSpecificParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRUnitTestingClusterTestSpecificParams.timedInvokeTimeoutMs
    mtrRequire(_MTRUnitTestingClusterTestSpecificParams.description.contains("MTRUnitTestingClusterTestSpecificParams"), "MTRUnitTestingClusterTestSpecificParams desc")
    let _MTRUnitTestingClusterTestSpecificResponseParams = (try? MTRUnitTestingClusterTestSpecificResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRUnitTestingClusterTestSpecificResponseParams()
    _MTRUnitTestingClusterTestSpecificResponseParams.returnValue = n(1)
    _ = _MTRUnitTestingClusterTestSpecificResponseParams.returnValue
    _MTRUnitTestingClusterTestSpecificResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRUnitTestingClusterTestSpecificResponseParams.timedInvokeTimeoutMs
    mtrRequire(_MTRUnitTestingClusterTestSpecificResponseParams.description.contains("MTRUnitTestingClusterTestSpecificResponseParams"), "MTRUnitTestingClusterTestSpecificResponseParams desc")
    let _MTRUnitTestingClusterTestStructArgumentRequestParams = MTRUnitTestingClusterTestStructArgumentRequestParams()
    _MTRUnitTestingClusterTestStructArgumentRequestParams.arg1 = MTRUnitTestingClusterSimpleStruct()
    _ = _MTRUnitTestingClusterTestStructArgumentRequestParams.arg1
    _MTRUnitTestingClusterTestStructArgumentRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRUnitTestingClusterTestStructArgumentRequestParams.serverSideProcessingTimeout
    _MTRUnitTestingClusterTestStructArgumentRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRUnitTestingClusterTestStructArgumentRequestParams.timedInvokeTimeoutMs
    mtrRequire(_MTRUnitTestingClusterTestStructArgumentRequestParams.description.contains("MTRUnitTestingClusterTestStructArgumentRequestParams"), "MTRUnitTestingClusterTestStructArgumentRequestParams desc")
    let _MTRUnitTestingClusterTestStructArrayArgumentRequestParams = MTRUnitTestingClusterTestStructArrayArgumentRequestParams()
    _MTRUnitTestingClusterTestStructArrayArgumentRequestParams.arg1 = [n(1)] as [Any]
    _ = _MTRUnitTestingClusterTestStructArrayArgumentRequestParams.arg1
    _MTRUnitTestingClusterTestStructArrayArgumentRequestParams.arg2 = [n(1)] as [Any]
    _ = _MTRUnitTestingClusterTestStructArrayArgumentRequestParams.arg2
    _MTRUnitTestingClusterTestStructArrayArgumentRequestParams.arg3 = [n(1)] as [Any]
    _ = _MTRUnitTestingClusterTestStructArrayArgumentRequestParams.arg3
    _MTRUnitTestingClusterTestStructArrayArgumentRequestParams.arg4 = [n(1)] as [Any]
    _ = _MTRUnitTestingClusterTestStructArrayArgumentRequestParams.arg4
    _MTRUnitTestingClusterTestStructArrayArgumentRequestParams.arg5 = n(1)
    _ = _MTRUnitTestingClusterTestStructArrayArgumentRequestParams.arg5
    _MTRUnitTestingClusterTestStructArrayArgumentRequestParams.arg6 = n(1)
    _ = _MTRUnitTestingClusterTestStructArrayArgumentRequestParams.arg6
    _MTRUnitTestingClusterTestStructArrayArgumentRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRUnitTestingClusterTestStructArrayArgumentRequestParams.serverSideProcessingTimeout
    _MTRUnitTestingClusterTestStructArrayArgumentRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRUnitTestingClusterTestStructArrayArgumentRequestParams.timedInvokeTimeoutMs
    mtrRequire(_MTRUnitTestingClusterTestStructArrayArgumentRequestParams.description.contains("MTRUnitTestingClusterTestStructArrayArgumentRequestParams"), "MTRUnitTestingClusterTestStructArrayArgumentRequestParams desc")
    let _MTRUnitTestingClusterTestStructArrayArgumentResponseParams = (try? MTRUnitTestingClusterTestStructArrayArgumentResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRUnitTestingClusterTestStructArrayArgumentResponseParams()
    _MTRUnitTestingClusterTestStructArrayArgumentResponseParams.arg1 = [n(1)] as [Any]
    _ = _MTRUnitTestingClusterTestStructArrayArgumentResponseParams.arg1
    _MTRUnitTestingClusterTestStructArrayArgumentResponseParams.arg2 = [n(1)] as [Any]
    _ = _MTRUnitTestingClusterTestStructArrayArgumentResponseParams.arg2
    _MTRUnitTestingClusterTestStructArrayArgumentResponseParams.arg3 = [n(1)] as [Any]
    _ = _MTRUnitTestingClusterTestStructArrayArgumentResponseParams.arg3
    _MTRUnitTestingClusterTestStructArrayArgumentResponseParams.arg4 = [n(1)] as [Any]
    _ = _MTRUnitTestingClusterTestStructArrayArgumentResponseParams.arg4
    _MTRUnitTestingClusterTestStructArrayArgumentResponseParams.arg5 = n(1)
    _ = _MTRUnitTestingClusterTestStructArrayArgumentResponseParams.arg5
    _MTRUnitTestingClusterTestStructArrayArgumentResponseParams.arg6 = n(1)
    _ = _MTRUnitTestingClusterTestStructArrayArgumentResponseParams.arg6
    _MTRUnitTestingClusterTestStructArrayArgumentResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRUnitTestingClusterTestStructArrayArgumentResponseParams.timedInvokeTimeoutMs
    mtrRequire(_MTRUnitTestingClusterTestStructArrayArgumentResponseParams.description.contains("MTRUnitTestingClusterTestStructArrayArgumentResponseParams"), "MTRUnitTestingClusterTestStructArrayArgumentResponseParams desc")
    let _MTRUnitTestingClusterTestUnknownCommandParams = MTRUnitTestingClusterTestUnknownCommandParams()
    _MTRUnitTestingClusterTestUnknownCommandParams.serverSideProcessingTimeout = n(1)
    _ = _MTRUnitTestingClusterTestUnknownCommandParams.serverSideProcessingTimeout
    _MTRUnitTestingClusterTestUnknownCommandParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRUnitTestingClusterTestUnknownCommandParams.timedInvokeTimeoutMs
    mtrRequire(_MTRUnitTestingClusterTestUnknownCommandParams.description.contains("MTRUnitTestingClusterTestUnknownCommandParams"), "MTRUnitTestingClusterTestUnknownCommandParams desc")
    let _MTRUnitTestingClusterTimedInvokeRequestParams = MTRUnitTestingClusterTimedInvokeRequestParams()
    _MTRUnitTestingClusterTimedInvokeRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRUnitTestingClusterTimedInvokeRequestParams.serverSideProcessingTimeout
    _MTRUnitTestingClusterTimedInvokeRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRUnitTestingClusterTimedInvokeRequestParams.timedInvokeTimeoutMs
    mtrRequire(_MTRUnitTestingClusterTimedInvokeRequestParams.description.contains("MTRUnitTestingClusterTimedInvokeRequestParams"), "MTRUnitTestingClusterTimedInvokeRequestParams desc")
}

func testWindowCoveringParams() {
    let _MTRWindowCoveringClusterDownOrCloseParams = MTRWindowCoveringClusterDownOrCloseParams()
    _MTRWindowCoveringClusterDownOrCloseParams.serverSideProcessingTimeout = n(1)
    _ = _MTRWindowCoveringClusterDownOrCloseParams.serverSideProcessingTimeout
    _MTRWindowCoveringClusterDownOrCloseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRWindowCoveringClusterDownOrCloseParams.timedInvokeTimeoutMs
    mtrRequire(_MTRWindowCoveringClusterDownOrCloseParams.description.contains("MTRWindowCoveringClusterDownOrCloseParams"), "MTRWindowCoveringClusterDownOrCloseParams desc")
    let _MTRWindowCoveringClusterGoToLiftPercentageParams = MTRWindowCoveringClusterGoToLiftPercentageParams()
    _MTRWindowCoveringClusterGoToLiftPercentageParams.liftPercent100thsValue = n(1)
    _ = _MTRWindowCoveringClusterGoToLiftPercentageParams.liftPercent100thsValue
    _MTRWindowCoveringClusterGoToLiftPercentageParams.serverSideProcessingTimeout = n(1)
    _ = _MTRWindowCoveringClusterGoToLiftPercentageParams.serverSideProcessingTimeout
    _MTRWindowCoveringClusterGoToLiftPercentageParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRWindowCoveringClusterGoToLiftPercentageParams.timedInvokeTimeoutMs
    mtrRequire(_MTRWindowCoveringClusterGoToLiftPercentageParams.description.contains("MTRWindowCoveringClusterGoToLiftPercentageParams"), "MTRWindowCoveringClusterGoToLiftPercentageParams desc")
    let _MTRWindowCoveringClusterGoToLiftValueParams = MTRWindowCoveringClusterGoToLiftValueParams()
    _MTRWindowCoveringClusterGoToLiftValueParams.liftValue = n(1)
    _ = _MTRWindowCoveringClusterGoToLiftValueParams.liftValue
    _MTRWindowCoveringClusterGoToLiftValueParams.serverSideProcessingTimeout = n(1)
    _ = _MTRWindowCoveringClusterGoToLiftValueParams.serverSideProcessingTimeout
    _MTRWindowCoveringClusterGoToLiftValueParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRWindowCoveringClusterGoToLiftValueParams.timedInvokeTimeoutMs
    mtrRequire(_MTRWindowCoveringClusterGoToLiftValueParams.description.contains("MTRWindowCoveringClusterGoToLiftValueParams"), "MTRWindowCoveringClusterGoToLiftValueParams desc")
    let _MTRWindowCoveringClusterGoToTiltPercentageParams = MTRWindowCoveringClusterGoToTiltPercentageParams()
    _MTRWindowCoveringClusterGoToTiltPercentageParams.serverSideProcessingTimeout = n(1)
    _ = _MTRWindowCoveringClusterGoToTiltPercentageParams.serverSideProcessingTimeout
    _MTRWindowCoveringClusterGoToTiltPercentageParams.tiltPercent100thsValue = n(1)
    _ = _MTRWindowCoveringClusterGoToTiltPercentageParams.tiltPercent100thsValue
    _MTRWindowCoveringClusterGoToTiltPercentageParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRWindowCoveringClusterGoToTiltPercentageParams.timedInvokeTimeoutMs
    mtrRequire(_MTRWindowCoveringClusterGoToTiltPercentageParams.description.contains("MTRWindowCoveringClusterGoToTiltPercentageParams"), "MTRWindowCoveringClusterGoToTiltPercentageParams desc")
    let _MTRWindowCoveringClusterGoToTiltValueParams = MTRWindowCoveringClusterGoToTiltValueParams()
    _MTRWindowCoveringClusterGoToTiltValueParams.serverSideProcessingTimeout = n(1)
    _ = _MTRWindowCoveringClusterGoToTiltValueParams.serverSideProcessingTimeout
    _MTRWindowCoveringClusterGoToTiltValueParams.tiltValue = n(1)
    _ = _MTRWindowCoveringClusterGoToTiltValueParams.tiltValue
    _MTRWindowCoveringClusterGoToTiltValueParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRWindowCoveringClusterGoToTiltValueParams.timedInvokeTimeoutMs
    mtrRequire(_MTRWindowCoveringClusterGoToTiltValueParams.description.contains("MTRWindowCoveringClusterGoToTiltValueParams"), "MTRWindowCoveringClusterGoToTiltValueParams desc")
    let _MTRWindowCoveringClusterStopMotionParams = MTRWindowCoveringClusterStopMotionParams()
    _MTRWindowCoveringClusterStopMotionParams.serverSideProcessingTimeout = n(1)
    _ = _MTRWindowCoveringClusterStopMotionParams.serverSideProcessingTimeout
    _MTRWindowCoveringClusterStopMotionParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRWindowCoveringClusterStopMotionParams.timedInvokeTimeoutMs
    mtrRequire(_MTRWindowCoveringClusterStopMotionParams.description.contains("MTRWindowCoveringClusterStopMotionParams"), "MTRWindowCoveringClusterStopMotionParams desc")
    let _MTRWindowCoveringClusterUpOrOpenParams = MTRWindowCoveringClusterUpOrOpenParams()
    _MTRWindowCoveringClusterUpOrOpenParams.serverSideProcessingTimeout = n(1)
    _ = _MTRWindowCoveringClusterUpOrOpenParams.serverSideProcessingTimeout
    _MTRWindowCoveringClusterUpOrOpenParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRWindowCoveringClusterUpOrOpenParams.timedInvokeTimeoutMs
    mtrRequire(_MTRWindowCoveringClusterUpOrOpenParams.description.contains("MTRWindowCoveringClusterUpOrOpenParams"), "MTRWindowCoveringClusterUpOrOpenParams desc")
}

