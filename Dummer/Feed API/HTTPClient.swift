import Foundation

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
        completion: @escaping (Result<ClientResponse, Error>) -> Void
    )
}
