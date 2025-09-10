import Foundation

public enum LoadFeedResult {
    case success([DummerFeedItem])
    case failure(Error)
}

protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
