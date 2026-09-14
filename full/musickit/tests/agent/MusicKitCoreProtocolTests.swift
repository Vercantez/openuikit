import Foundation
import MusicKit

func testMusicItemCoreProtocols() {
    let song = Song(id: "1", title: "Helplessness Blues", artistName: "Fleet Foxes")
    inspectMusicItem(song)
    inspectPlayableMusicItem(song)
    inspectMusicLibraryAddable(song)
    inspectMusicPlaylistAddable(song)
    inspectMusicCatalogSearchable(song)
    inspectMusicLibrarySearchable(song)
    inspectRecentlyPlayedRequestable(song)
    inspectCatalogTopLevelRequesting(song)
    inspectPropertyContainer(PropertyContainerProbe())
    let tokenProvider: any MusicTokenProvider = DefaultMusicTokenProvider()
    _ = tokenProvider
    let developerProvider: any MusicDeveloperTokenProvider = DefaultMusicTokenProvider()
    _ = developerProvider
    let containerRequest = MusicRecentlyPlayedContainerRequest()
    precondition(containerRequest.limit == nil)
    precondition(containerRequest.offset == nil)
    let containerResponse = MusicRecentlyPlayedContainerResponse()
    precondition(containerResponse.items.count == 0)
}

func testRecentlyPlayedRequestAndResponses() {
    var request = MusicRecentlyPlayedRequest<Song>()
    precondition(request.limit == nil)
    precondition(request.offset == nil)
    request.limit = 10
    request.offset = 5
    precondition(request.limit == 10)
    precondition(request.offset == 5)
    let recent = MusicRecentlyPlayedResponse(
        items: MusicItemCollection([Song(id: "1", title: "T", artistName: "A")]))
    precondition(recent.items.count == 1)
    let encodedRecent = try! JSONEncoder().encode(recent)
    let decodedRecent = try! JSONDecoder().decode(
        MusicRecentlyPlayedResponse<Song>.self, from: encodedRecent)
    precondition(decodedRecent.items.count == 1)
    precondition(decodedRecent.items.first?.title == "T")
    precondition(decodedRecent.items.first?.id.rawValue == "1")
    let resource = MusicCatalogResourceResponse(
        items: MusicItemCollection([Album(id: "2", title: "HB", artistName: "FF")]))
    precondition(resource.items.count == 1)
    let encodedResource = try! JSONEncoder().encode(resource)
    let decodedResource = try! JSONDecoder().decode(
        MusicCatalogResourceResponse<Album>.self, from: encodedResource)
    precondition(decodedResource.items.count == 1)
    precondition(decodedResource.items.first?.title == "HB")
    precondition(decodedResource.items.first?.id.rawValue == "2")
}

private struct PropertyContainerProbe: MusicPropertyContainer {}

private func inspectMusicItem(_ item: some MusicItem) {
    precondition(item.id.rawValue == "1")
}

private func inspectPlayableMusicItem(_ item: some PlayableMusicItem) {
    precondition(item.id.rawValue == "1")
    precondition(item.playParameters != nil)
}

private func inspectMusicLibraryAddable(_ item: some MusicLibraryAddable) {
    precondition(item.id.rawValue == "1")
}

private func inspectMusicPlaylistAddable(_ item: some MusicPlaylistAddable) {
    precondition(item.id.rawValue == "1")
}

private func inspectMusicCatalogSearchable(_ item: some MusicCatalogSearchable) {
    precondition(item.id.rawValue == "1")
}

private func inspectMusicLibrarySearchable(_ item: some MusicLibrarySearchable) {
    precondition(item.id.rawValue == "1")
}

private func inspectRecentlyPlayedRequestable(_ item: some MusicRecentlyPlayedRequestable) {
    precondition(item.id.rawValue == "1")
}

private func inspectCatalogTopLevelRequesting(_ item: some MusicCatalogTopLevelResourceRequesting) {
    precondition(item.id.rawValue == "1")
}

private func inspectPropertyContainer(_ item: some MusicPropertyContainer) {
    let erased = item as any MusicPropertyContainer
    _ = erased
}
