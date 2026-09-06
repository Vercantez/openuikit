import Foundation
@_spi(OpenUIKitHost)
import JournalingSuggestions

func testSuggestionIdentity() {
    let start = Date(timeIntervalSince1970: 1_700_000_000)
    let interval = DateInterval(start: start, duration: 3600)
    let item = JournalingSuggestion.ItemContent(id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!)
    let suggestion = JournalingSuggestion(title: "Walk", date: interval, items: [item])
    precondition(suggestion.title == "Walk")
    precondition(suggestion.date == interval)
    precondition(suggestion.items.count == 1)
    precondition(suggestion.items[0].id == item.id)
}

func testSuggestionEqualityAndHashing() {
    let start = Date(timeIntervalSince1970: 1_700_000_000)
    let interval = DateInterval(start: start, duration: 60)
    let id = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    let first = JournalingSuggestion(
        title: "A",
        date: interval,
        items: [JournalingSuggestion.ItemContent(id: id)]
    )
    let same = JournalingSuggestion(
        title: "A",
        date: interval,
        items: [JournalingSuggestion.ItemContent(id: id)]
    )
    let other = JournalingSuggestion(title: "B", date: interval, items: [])
    precondition(first == same)
    precondition(first != other)
    precondition((first != same) == false)
    var hasher = Hasher()
    first.hash(into: &hasher)
    let hashed = hasher.finalize()
    _ = hashed
    precondition(first.hashValue == same.hashValue)
}

func testReflectionPromptAndColor() {
    let reflection = JournalingSuggestion.Reflection(prompt: "How did today feel?", color: Color("red"))
    precondition(reflection.prompt == "How did today feel?")
    precondition(reflection.color == Color("red"))
    precondition(JournalingSuggestion.Reflection.JournalingSuggestionContent.self == JournalingSuggestion.Reflection.self)
}

func testEventPosterFields() {
    let start = Date(timeIntervalSince1970: 1_720_000_000)
    let end = start.addingTimeInterval(7200)
    let image = URL(fileURLWithPath: "/tmp/poster.png")
    let poster = JournalingSuggestion.EventPoster(
        title: AttributedString("Birthday"),
        eventStart: start,
        eventEnd: end,
        image: image,
        isHost: true,
        placeName: "Park"
    )
    precondition(poster.title == AttributedString("Birthday"))
    precondition(poster.eventStart == start)
    precondition(poster.eventEnd == end)
    precondition(poster.image == image)
    precondition(poster.isHost == true)
    precondition(poster.placeName == "Park")
    precondition(JournalingSuggestion.EventPoster.JournalingSuggestionContent.self == JournalingSuggestion.EventPoster.self)
}

func testGenericMediaFields() {
    let date = Date(timeIntervalSince1970: 1_500_000_000)
    let icon = URL(fileURLWithPath: "/tmp/app.png")
    let media = JournalingSuggestion.GenericMedia(
        title: "Track",
        artist: "Artist",
        album: "Album",
        date: date,
        appIcon: icon
    )
    precondition(media.title == "Track")
    precondition(media.artist == "Artist")
    precondition(media.album == "Album")
    precondition(media.date == date)
    precondition(media.appIcon == icon)
    precondition(JournalingSuggestion.GenericMedia.JournalingSuggestionContent.self == JournalingSuggestion.GenericMedia.self)
}

func testSongFields() {
    let date = Date(timeIntervalSince1970: 1_600_000_000)
    let artwork = URL(fileURLWithPath: "/tmp/art.jpg")
    let song = JournalingSuggestion.Song(
        song: "Helplessness Blues",
        artist: "Fleet Foxes",
        album: "Helplessness Blues",
        date: date,
        artwork: artwork
    )
    precondition(song.song == "Helplessness Blues")
    precondition(song.artist == "Fleet Foxes")
    precondition(song.album == "Helplessness Blues")
    precondition(song.date == date)
    precondition(song.artwork == artwork)
    precondition(JournalingSuggestion.Song.JournalingSuggestionContent.self == JournalingSuggestion.Song.self)
}

func testPhotoFields() {
    let url = URL(fileURLWithPath: "/tmp/photo.jpg")
    let date = Date(timeIntervalSince1970: 1_610_000_000)
    let photo = JournalingSuggestion.Photo(photo: url, date: date)
    precondition(photo.photo == url)
    precondition(photo.date == date)
    precondition(JournalingSuggestion.Photo.JournalingSuggestionContent.self == JournalingSuggestion.Photo.self)
}

func testVideoFields() {
    let url = URL(fileURLWithPath: "/tmp/clip.mov")
    let date = Date(timeIntervalSince1970: 1_620_000_000)
    let video = JournalingSuggestion.Video(url: url, date: date)
    precondition(video.url == url)
    precondition(video.date == date)
    precondition(JournalingSuggestion.Video.JournalingSuggestionContent.self == JournalingSuggestion.Video.self)
}

func testContactFields() {
    let photo = URL(fileURLWithPath: "/tmp/face.png")
    let contact = JournalingSuggestion.Contact(name: "Ada", photo: photo)
    precondition(contact.name == "Ada")
    precondition(contact.photo == photo)
    precondition(JournalingSuggestion.Contact.JournalingSuggestionContent.self == JournalingSuggestion.Contact.self)
}

func testPodcastFields() {
    let date = Date(timeIntervalSince1970: 1_630_000_000)
    let artwork = URL(fileURLWithPath: "/tmp/pod.png")
    let podcast = JournalingSuggestion.Podcast(
        show: "ATP",
        episode: "600",
        date: date,
        artwork: artwork
    )
    precondition(podcast.show == "ATP")
    precondition(podcast.episode == "600")
    precondition(podcast.date == date)
    precondition(podcast.artwork == artwork)
    precondition(JournalingSuggestion.Podcast.JournalingSuggestionContent.self == JournalingSuggestion.Podcast.self)
}

func testLivePhotoFields() {
    let image = URL(fileURLWithPath: "/tmp/live.jpg")
    let video = URL(fileURLWithPath: "/tmp/live.mov")
    let date = Date(timeIntervalSince1970: 1_640_000_000)
    let live = JournalingSuggestion.LivePhoto(image: image, video: video, date: date)
    precondition(live.image == image)
    precondition(live.video == video)
    precondition(live.date == date)
    precondition(JournalingSuggestion.LivePhoto.JournalingSuggestionContent.self == JournalingSuggestion.LivePhoto.self)
}
