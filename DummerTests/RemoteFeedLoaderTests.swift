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
        
        var caputuredErrors = [RemoteFeedLoader.Error]()
        sut.load {
            caputuredErrors.append($0)
        }
        let clientError = RemoteFeedLoader.Error.connectivity
        client.complete(with: clientError)
        
        XCTAssertEqual(caputuredErrors, [.connectivity])
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        let samples = [199, 201, 300, 400, 500]
        
        samples.enumerated().forEach { index, code in
            var capturedErrors = [RemoteFeedLoader.Error]()
            sut.load {
                capturedErrors.append($0)
            }
            
            client.complete(withStatusCode: code, at: index)
            
            XCTAssertEqual(capturedErrors, [.invalidData])
        }
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
        // var requestedURL: URL?
        // Why use an array?
        // Assert value, quantity and quality at the same time
        var requestedURLs: [URL] {
            messages.map { $0.url }
        }
        
        private var messages = [
            (url: URL, completion: (Result<HTTPURLResponse, RemoteFeedLoader.Error>) -> Void)
        ]()
        
        func get(
            from url: URL,
            completion: @escaping (Result<HTTPURLResponse, RemoteFeedLoader.Error>) -> Void
        ) {
            messages.append((url: url, completion: completion))
        }
        
        func complete(with error: RemoteFeedLoader.Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode code: Int, at index: Int = 0) {
            let response = HTTPURLResponse(
                url: requestedURLs[index],
                statusCode: code,
                httpVersion: nil,
                headerFields: nil
            )!
            messages[index].completion(.success(response))
        }
    }
}

// Notes:
// 1. Spies has to just capture values, do not STUB!!
// 2. don't repeat yourself, use samples, keep it simple
