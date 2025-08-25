import Foundation

protocol FeedLoader {
    func load(completion: @escaping (Result<[DummerFeedItem], Error>) -> Void)
}

public protocol HTTPClient {
    func get(
        from url: URL,
        completion: @escaping (Result<HTTPURLResponse, RemoteFeedLoader.Error>) -> Void
    )
}

public final class RemoteFeedLoader {
    private let url: URL
    private let client: HTTPClient
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public init(url: URL, client: HTTPClient) {
        self.client = client
        self.url = url
    }
    
    public func load(completion: @escaping (Error) -> Void) {
        client.get(from: url) { result in
            switch result {
            case .success:
                completion(.invalidData)
            case .failure:
                completion(.connectivity)
            }
        }
    }
}
