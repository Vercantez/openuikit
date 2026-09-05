import Foundation

/// Linear PCM FourCC `'lpcm'` observed from CoreAudioTypes (`kAudioFormatLinearPCM`).
let avfaudioLinearPCMFormatID: UInt32 = 1_819_304_813

func avfaudioClampUnit(_ value: Double) -> Double {
    if value > 1 { return 1 }
    if value < -1 { return -1 }
    if value.isNaN { return 0 }
    return value
}

func avfaudioPCMBytesPerSample(_ format: AVAudioFormat) -> Int {
    format.bytesPerSample
}

func avfaudioReadPCMSample(_ buffer: AVAudioPCMBuffer, channel: Int, frame: Int) -> Double {
    guard frame >= 0, channel >= 0, frame < Int(buffer.frameLength) else { return 0 }
    let channels = Int(buffer.format.channelCount)
    guard channel < channels else { return 0 }
    switch buffer.format.commonFormat {
    case .pcmFormatFloat32:
        guard let planes = buffer.floatChannelData else { return 0 }
        return Double(planes[channel][frame * buffer.stride])
    case .pcmFormatInt16:
        guard let planes = buffer.int16ChannelData else { return 0 }
        return Double(planes[channel][frame * buffer.stride]) / 32768.0
    case .pcmFormatInt32:
        guard let planes = buffer.int32ChannelData else { return 0 }
        return Double(planes[channel][frame * buffer.stride]) / 2_147_483_648.0
    case .pcmFormatFloat64, .otherFormat:
        return 0
    }
}

func avfaudioWritePCMSample(_ buffer: AVAudioPCMBuffer, channel: Int, frame: Int, value: Double) {
    guard frame >= 0, channel >= 0, frame < Int(buffer.frameCapacity) else { return }
    let channels = Int(buffer.format.channelCount)
    guard channel < channels else { return }
    let clipped = avfaudioClampUnit(value)
    switch buffer.format.commonFormat {
    case .pcmFormatFloat32:
        guard let planes = buffer.floatChannelData else { return }
        planes[channel][frame * buffer.stride] = Float(clipped)
    case .pcmFormatInt16:
        guard let planes = buffer.int16ChannelData else { return }
        planes[channel][frame * buffer.stride] = Int16(
            clamping: Int((clipped * 32767.0).rounded())
        )
    case .pcmFormatInt32:
        guard let planes = buffer.int32ChannelData else { return }
        planes[channel][frame * buffer.stride] = Int32(
            clamping: Int((clipped * 2_147_483_647.0).rounded())
        )
    case .pcmFormatFloat64, .otherFormat:
        break
    }
}

func avfaudioZeroPCMBuffer(_ buffer: AVAudioPCMBuffer, frames: AVAudioFrameCount) {
    buffer.frameLength = min(frames, buffer.frameCapacity)
    let channels = Int(buffer.format.channelCount)
    for channel in 0..<channels {
        for frame in 0..<Int(buffer.frameLength) {
            avfaudioWritePCMSample(buffer, channel: channel, frame: frame, value: 0)
        }
    }
}

func avfaudioEqualPowerGains(pan: Float) -> (Float, Float) {
    let clamped = min(max(pan, -1), 1)
    return (min(1, 1 - clamped), min(1, 1 + clamped))
}

func avfaudioApplyGainPan(
    _ sample: Double,
    channel: Int,
    channelCount: Int,
    volume: Float,
    pan: Float
) -> Double {
    var value = sample * Double(volume)
    if channelCount == 2 {
        let gains = avfaudioEqualPowerGains(pan: pan)
        value *= Double(channel == 0 ? gains.0 : gains.1)
    }
    return value
}

/// Linear interpolation resampler. Apple's converter uses a higher-quality SRC;
/// this is an explicit documented gap.
func avfaudioResampleIndex(outputFrame: Int, inRate: Double, outRate: Double, inFrames: Int) -> (Int, Double) {
    guard outRate > 0, inRate > 0, inFrames > 0 else { return (0, 0) }
    let source = Double(outputFrame) * inRate / outRate
    let index = Int(source.rounded(.down))
    let frac = source - Double(index)
    if index >= inFrames - 1 {
        return (inFrames - 1, 0)
    }
    if index < 0 {
        return (0, 0)
    }
    return (index, frac)
}

func avfaudioConvertPCM(
    from input: AVAudioPCMBuffer,
    to output: AVAudioPCMBuffer,
    channelMap: [Int],
    downmix: Bool
) -> AVAudioFrameCount {
    let inFrames = Int(input.frameLength)
    guard inFrames > 0 else {
        output.frameLength = 0
        return 0
    }
    let inRate = input.format.sampleRate
    let outRate = output.format.sampleRate
    let outChannels = Int(output.format.channelCount)
    let inChannels = Int(input.format.channelCount)
    let ratio = (inRate > 0 && outRate > 0) ? outRate / inRate : 1
    let estimated = Int((Double(inFrames) * ratio).rounded(.down))
    let outFrames = min(Int(output.frameCapacity), max(estimated, 1))
    output.frameLength = AVAudioFrameCount(outFrames)

    var map = channelMap
    if map.isEmpty {
        if downmix && inChannels > 0 {
            map = Array(repeating: -1, count: outChannels)
        } else {
            map = (0..<outChannels).map { $0 < inChannels ? $0 : -1 }
        }
    }
    while map.count < outChannels {
        map.append(-1)
    }

    for outFrame in 0..<outFrames {
        let (src, frac) = avfaudioResampleIndex(
            outputFrame: outFrame,
            inRate: inRate,
            outRate: outRate,
            inFrames: inFrames
        )
        let next = min(src + 1, inFrames - 1)
        for outChannel in 0..<outChannels {
            let mapped = map[outChannel]
            let value: Double
            if mapped < 0 {
                if downmix {
                    var mix = 0.0
                    for inChannel in 0..<inChannels {
                        let a = avfaudioReadPCMSample(input, channel: inChannel, frame: src)
                        let b = avfaudioReadPCMSample(input, channel: inChannel, frame: next)
                        mix += a + (b - a) * frac
                    }
                    value = mix / Double(max(inChannels, 1))
                } else {
                    value = 0
                }
            } else if mapped < inChannels {
                let a = avfaudioReadPCMSample(input, channel: mapped, frame: src)
                let b = avfaudioReadPCMSample(input, channel: mapped, frame: next)
                value = a + (b - a) * frac
            } else {
                value = 0
            }
            avfaudioWritePCMSample(output, channel: outChannel, frame: outFrame, value: value)
        }
    }
    return AVAudioFrameCount(outFrames)
}

func avfaudioMixPCM(
    source: AVAudioPCMBuffer,
    into destination: AVAudioPCMBuffer,
    volume: Float,
    pan: Float,
    extraGain: Float,
    frames: Int,
    destOffset: Int = 0
) {
    let channels = min(Int(source.format.channelCount), Int(destination.format.channelCount))
    let count = min(frames, Int(source.frameLength), Int(destination.frameCapacity) - destOffset)
    guard count > 0, channels > 0 else { return }
    let gain = Double(volume) * Double(extraGain)
    for frame in 0..<count {
        for channel in 0..<channels {
            let incoming = avfaudioReadPCMSample(source, channel: channel, frame: frame)
            let mixed = avfaudioApplyGainPan(
                incoming * gain,
                channel: channel,
                channelCount: Int(destination.format.channelCount),
                volume: 1,
                pan: pan
            )
            let existing = avfaudioReadPCMSample(
                destination,
                channel: channel,
                frame: destOffset + frame
            )
            avfaudioWritePCMSample(
                destination,
                channel: channel,
                frame: destOffset + frame,
                value: existing + mixed
            )
        }
    }
    destination.frameLength = max(
        destination.frameLength,
        AVAudioFrameCount(destOffset + count)
    )
}

func avfaudioDecibelToLinear(_ decibels: Float) -> Float {
    pow(10, decibels / 20)
}
