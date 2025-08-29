import Foundation

protocol FeedLoader {
    func load(completion: @escaping (Result<[DummerFeedItem], Error>) -> Void)
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
    
    public func load(completion: @escaping (Result<[DummerFeedItem], Error>) -> Void) {
        client.get(from: url) { [weak self] result in
            guard self != nil else { return }
            
            switch result {
            case .success(let response):
                completion(FeedItemsMapper.map(response.data, from: response.response))
            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
}

