import Foundation
@_spi(OpenUIKitHost) import CarPlay

func testNowPlayingTemplateButtonsAndObservers() {
    carPlayOnMain {
        let image = UIImage()
        let now = CPNowPlayingTemplate.shared
        precondition(now === CPNowPlayingTemplate.shared)
        precondition(now.mpNowPlayingBridgeDeclared)
        let observer = RecordingNowPlayingObserver()
        now.add(observer)
        now.isAlbumArtistButtonEnabled = true
        now.isUpNextButtonEnabled = true
        now.upNextTitle = "Up Next"
        let npMore = CPNowPlayingMoreButton()
        let npRate = CPNowPlayingPlaybackRateButton()
        let npRepeat = CPNowPlayingRepeatButton()
        let npShuffle = CPNowPlayingShuffleButton()
        let npAdd = CPNowPlayingAddToLibraryButton()
        var imageTapped = false
        let npImage = CPNowPlayingImageButton(image: image) { _ in imageTapped = true }
        npImage.isEnabled = true
        npImage.isSelected = false
        npImage.openuikit_invokeHandler()
        precondition(imageTapped)
        now.updateNowPlayingButtons([npMore, npRate, npRepeat, npShuffle, npAdd, npImage])
        precondition(now.nowPlayingButtons.count == 6)
        now.openuikit_notifyUpNext()
        now.openuikit_notifyAlbumArtist()
        precondition(observer.upNext == 1)
        precondition(observer.album == 1)
        now.remove(observer)
        _ = CPNowPlayingButton()
        _ = CPNowPlayingButton { _ in }
        _ = CPNowPlayingImageButton()
        _ = CPNowPlayingMode.default
        _ = CPNowPlayingMode()
        _ = CPNowPlayingButtonMaximumImageSize
    }
}

func testNowPlayingSportsMode() {
    carPlayOnMain {
        let image = UIImage()
        let clockUp = CPNowPlayingSportsClock(elapsedTime: 12, paused: false)
        precondition(clockUp.countsUp)
        precondition(clockUp.timeValue == 12)
        precondition(!clockUp.isPaused)
        let clockDown = CPNowPlayingSportsClock(timeRemaining: 5, paused: true)
        precondition(!clockDown.countsUp)
        precondition(clockDown.timeValue == 5)
        precondition(clockDown.isPaused)
        let status = CPNowPlayingSportsEventStatus(
            eventStatusText: ["Q2"],
            eventStatusImage: image,
            eventClock: clockDown
        )
        precondition(status.eventStatusText == ["Q2"])
        precondition(status.eventStatusImage != nil)
        precondition(status.eventClock === clockDown)
        let logo = CPNowPlayingSportsTeamLogo(teamLogo: image)
        precondition(logo.logo != nil)
        let initials = CPNowPlayingSportsTeamLogo(teamInitials: "AA")
        precondition(initials.initials == "AA")
        let team = CPNowPlayingSportsTeam(
            name: "Aces",
            logo: logo,
            teamStandings: "1st",
            eventScore: "21",
            possessionIndicator: image,
            favorite: true
        )
        precondition(team.name == "Aces")
        precondition(team.logo === logo)
        precondition(team.teamStandings == "1st")
        precondition(team.eventScore == "21")
        precondition(team.isFavorite)
        let sports = CPNowPlayingModeSports(
            leftTeam: team,
            rightTeam: team,
            eventStatus: status,
            backgroundArtwork: image
        )
        precondition(sports.leftTeam === team)
        precondition(sports.rightTeam === team)
        precondition(sports.eventStatus === status)
        CPNowPlayingTemplate.shared.nowPlayingMode = sports
        _ = CPNowPlayingSportsClock()
        _ = CPNowPlayingSportsEventStatus()
        _ = CPNowPlayingSportsTeam()
        _ = CPNowPlayingSportsTeamLogo()
        _ = CPNowPlayingModeSports()
    }
}
