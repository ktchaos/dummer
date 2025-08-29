import Foundation

internal final class FeedItemsMapper {
    private static var OK_200: Int { 200 }

    private struct Root: Decodable {
        let items: [Item]
        
        var feed: [DummerFeedItem] {
            items.map { $0.item }
        }
    }
    
    internal static func map(_ data: Data, from response: HTTPURLResponse) -> Result<[DummerFeedItem], RemoteFeedLoader.Error> {
        guard response.statusCode == FeedItemsMapper.OK_200,
              let root = try? JSONDecoder().decode(Root.self, from: data)
        else {
            return .failure(.invalidData)
        }
        
        return .success(root.feed)
    }
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
