import Foundation
@_spi(OpenUIKitHost) import MediaPlayer

func testMoviePlayerFailClosed() {
    let movie = MPMoviePlayerController(contentURL: URL(string: "file://tmp.m4v")!)
    precondition(movie != nil)
    movie?.play()
    precondition(movie?.playbackState == .stopped)
    movie?.controlStyle = .none
    movie?.repeatMode = .one
    movie?.scalingMode = .fill
    movie?.setFullscreen(true, animated: false)
    precondition(movie?.isFullscreen == true)
    movie?.pause()
    movie?.stop()
    movie?.beginSeekingForward()
    movie?.beginSeekingBackward()
    movie?.endSeeking()
    movie?.prepareToPlay()
    precondition(movie?.isPreparedToPlay == false)
    movie?.cancelAllThumbnailImageRequests()
    movie?.requestThumbnailImages(atTimes: [0], timeOption: .exact)
    movie?.allowsAirPlay = true
    precondition(movie?.isAirPlayVideoActive == false)
    movie?.shouldAutoplay = true
    movie?.useApplicationAudioSession = false
    movie?.movieSourceType = .file
    movie?.endPlaybackTime = 10
    movie?.initialPlaybackTime = 1
    movie?.currentPlaybackRate = 1
    movie?.currentPlaybackTime = 0
    _ = movie?.duration
    _ = movie?.playableDuration
    _ = movie?.loadState
    _ = movie?.movieMediaTypes
    _ = movie?.readyForDisplay
    _ = movie?.timedMetadata
    _ = movie?.accessLog.events
    _ = movie?.accessLog.extendedLogData
    _ = movie?.accessLog.extendedLogDataStringEncoding
    _ = movie?.errorLog.events
    _ = movie?.errorLog.extendedLogData
    _ = movie?.errorLog.extendedLogDataStringEncoding
    let timed = MPTimedMetadata()
    _ = timed.key
    _ = timed.keyspace
    _ = timed.timestamp
    _ = timed.value
    _ = timed.allMetadata
    let accessEvent = MPMovieAccessLogEvent()
    _ = accessEvent.URI
    _ = accessEvent.durationWatched
    _ = accessEvent.indicatedBitrate
    _ = accessEvent.observedBitrate
    _ = accessEvent.numberOfBytesTransferred
    _ = accessEvent.numberOfDroppedVideoFrames
    _ = accessEvent.numberOfSegmentsDownloaded
    _ = accessEvent.numberOfServerAddressChanges
    _ = accessEvent.numberOfStalls
    _ = accessEvent.playbackSessionID
    _ = accessEvent.playbackStartDate
    _ = accessEvent.playbackStartOffset
    _ = accessEvent.segmentsDownloadedDuration
    _ = accessEvent.serverAddress
    let errEvent = MPMovieErrorLogEvent()
    _ = errEvent.URI
    _ = errEvent.date
    _ = errEvent.errorComment
    _ = errEvent.errorDomain
    _ = errEvent.errorStatusCode
    _ = errEvent.playbackSessionID
    _ = errEvent.serverAddress
}
