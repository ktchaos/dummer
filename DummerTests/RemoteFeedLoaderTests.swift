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
        
        sut.load()
        
        // Needs to assert how MANY times we are calling this
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestDataFromURLTwice() {
        let url = URL(filePath: "https://blablabla123.com")
        let (sut, client) = makeSUT(url: url)
        
        sut.load()
        sut.load()
        
        // Needs to assert how MANY times we are calling this
        XCTAssertEqual(client.requestedURLs, [url, url])
        XCTAssertEqual(client.requestedURL, url)
    }
    
    // MARK: - Helpers
    private func makeSUT(
        url: URL = URL(filePath: "https://blablabla.com")
    ) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }
    
    private class HTTPClientSpy: HTTPClient {
        var requestedURL: URL?
        // Why use an array?
        // Assert value, quantity and quality at the same time
        var requestedURLs = [URL]()
        
        func get(from url: URL) {
            requestedURL = url
            requestedURLs.append(url)
        }
    }
}
