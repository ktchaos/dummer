import Foundation

public struct DummerFeedItem: Equatable {
    public let id: UUID
    public let description: String?
    public let location: String?
    public let imageUrl: URL
    
    // create a public init so other modules can have access to this object
    public init(id: UUID, description: String?, location: String?, imageUrl: URL) {
        self.id = id
        self.description = description
        self.location = location
        self.imageUrl = imageUrl
    }
}

public struct DummerFeed {
    let items: [DummerFeedItem]
}
