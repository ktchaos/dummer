import Foundation

protocol FeedLoader {
    func load(completion: @escaping (Result<[DummerFeedItem], Error>) -> Void)
}

public struct ClientResponse {
    let response: HTTPURLResponse
    let data: Data
    
    public init(response: HTTPURLResponse, data: Data) {
        self.response = response
        self.data = data
    }
}

public protocol HTTPClient {
    func get(
        from url: URL,
        completion: @escaping (Result<ClientResponse, RemoteFeedLoader.Error>) -> Void
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
    
    public func load(completion: @escaping (Result<[DummerFeedItem], Error>) -> Void) {
        client.get(from: url) { result in
            switch result {
            case .success(let response):
                do {
                    let items = try FeedItemsMapper.map(response.data, response.response)
                    completion(.success(items))
                } catch {
                    completion(.failure(.invalidData))
                }
            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
}

private class FeedItemsMapper {
    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [DummerFeedItem] {
        guard response.statusCode == 200 else {
            throw RemoteFeedLoader.Error.invalidData
        }
        
        return try JSONDecoder().decode(Root.self, from: data).items.map { $0.item }
    }
}

private struct Root: Decodable {
    let items: [Item]
}

// JSON representation
private struct Item: Codable {
    let id: UUID
    let description: String?
    let location: String?
    let image: URL
    
    var item: DummerFeedItem {
        DummerFeedItem(id: id, description: description, location: location, imageUrl: image)
    }
}
