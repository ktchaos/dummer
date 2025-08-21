import Foundation

struct DummerFeedItem {
    let id: UUID
    let description: String?
    let location: String?
    let url: URL
    
    // create a public init so other modules can have access to this object
}
