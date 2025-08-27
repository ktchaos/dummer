import XCTest
import Dummer

// MARK: Tests
final class RemoteFeedLoaderTests: XCTestCase {
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()

        XCTAssert(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestDataFromURL() {
        let url = URL(filePath: "https://blablabla123.com")
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
        
        // Needs to assert how MANY times we are calling this
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestDataFromURLTwice() {
        let url = URL(filePath: "https://blablabla123.com")
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
        sut.load { _ in }
        
        // Needs to assert how MANY times we are calling this
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWithResult: .failure(.connectivity), when: {
            client.complete(with: .connectivity)
        })
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        let samples = [199, 201, 300, 400, 500]
        
        samples.enumerated().forEach { index, code in
            expect(sut, toCompleteWithResult: .failure(.invalidData), when: {
                let json = makeItemsJSON([])
                client.complete(withStatusCode: code, data: json, at: index)
            })
        }
    }
    
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWithResult: .failure(.invalidData), when: {
            let invalidJSON = Data("invalid json".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        })
    }
    
    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWithResult: .success([])) {
            let emptyListJSON = makeItemsJSON([])
            client.complete(withStatusCode: 200, data: emptyListJSON)
        }
    }
    
    func test_load_deliversItemsOn200HTTPResponseWithJSONItems() {
        let (sut, client) = makeSUT()
        
        let (item1, item1JSON) = makeItem(
            id: UUID(),
            imageUrl: URL(string: "https://akjsdkjas1.com")!
        )
                
        let (item2, item2JSON) = makeItem(
            id: UUID(),
            description: "a description",
            location: "a location",
            imageUrl: URL(string: "https://akjsdkjas2.com")!
        )

        let items = [item1, item2]
        
        expect(sut, toCompleteWithResult: .success(items), when: {
            let json = makeItemsJSON([item1JSON, item2JSON])
            client.complete(withStatusCode: 200, data: json)
        })
    }
    
    
    // MARK: - Helpers
    private func expect(
        _ sut: RemoteFeedLoader,
        toCompleteWithResult result: Result<[DummerFeedItem], RemoteFeedLoader.Error>,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        var capturedResults = [Result<[DummerFeedItem], RemoteFeedLoader.Error>]()
        sut.load { capturedResults.append($0) }
        
        action()
        
        XCTAssertEqual(capturedResults, [result], file: file, line: line)
    }
    
    // MARK: - SUT
    private func makeSUT(
        url: URL = URL(filePath: "https://blablabla.com")
    ) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }
    
    private func makeItem(id: UUID, description: String? = nil, location: String? = nil, imageUrl: URL) -> (model: DummerFeedItem, json: [String: Any]) {
        let item = DummerFeedItem(id: id, description: description, location: location, imageUrl: imageUrl)
        let json = [
            "id": id.uuidString,
            "description": description,
            "location": location,
            "image": imageUrl.absoluteString
        ].reduce(into: [String: Any]()) { (acc, e) in
            if let value = e.value {
                acc[e.key] = value
            }
        }
        
        return (item, json)
    }
    
    private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
        let json = ["items": items]
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    // MARK: - Spies
    private class HTTPClientSpy: HTTPClient {
        // var requestedURL: URL?
        // Why use an array?
        // Assert value, quantity and quality at the same time
        var requestedURLs: [URL] {
            messages.map { $0.url }
        }
        
        private var messages = [
            (url: URL, completion: (Result<ClientResponse, RemoteFeedLoader.Error>) -> Void)
        ]()
        
        func get(
            from url: URL,
            completion: @escaping (Result<ClientResponse, RemoteFeedLoader.Error>) -> Void
        ) {
            messages.append((url: url, completion: completion))
        }
        
        func complete(with error: RemoteFeedLoader.Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(
            withStatusCode code: Int,
            data: Data,
            at index: Int = 0
        ) {
            let response = HTTPURLResponse(
                url: requestedURLs[index],
                statusCode: code,
                httpVersion: nil,
                headerFields: nil
            )!
            messages[index].completion(.success(.init(response: response, data: data)))
        }
    }
}


// MARK: - Networking Module
// Notes on Lesson #2 and #3:
// 1. Spies has to just capture values, do not STUB!!
// 2. don't repeat yourself, use samples, keep it simple


// Notes on Lesson #4
// 1. expected functions can be powerful
// 2. optionals -> exponential results
// 3. CodingKeys should be part of the FeedLoader, it's part of the RemoteFeedLoader module
