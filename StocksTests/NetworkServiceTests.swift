//
//  NetworkServiceTests.swift
//  StocksTests
//

import Combine
import Foundation
import Testing
@testable import Stocks

struct NetworkServiceTests {
    
    // MARK: - Mock URLSession
    
    final class MockURLProtocol: URLProtocol {
        static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?
        
        override class func canInit(with request: URLRequest) -> Bool {
            true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            request
        }
        
        override func startLoading() {
            guard let handler = MockURLProtocol.requestHandler else {
                fatalError("Handler is unavailable.")
            }
            
            do {
                let (response, data) = try handler(request)
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                if let data = data {
                    client?.urlProtocol(self, didLoad: data)
                }
                client?.urlProtocolDidFinishLoading(self)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
        }
        
        override func stopLoading() {}
    }
    
    private func makeTestSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }
    
    // MARK: - Success Tests
    
    @Test func testSuccessfulRequest() async throws {
        let testJSON = """
        {
            "marketSummaryAndSparkResponse": {
                "result": [
                    {
                        "symbol": "AAPL",
                        "shortName": "Apple Inc.",
                        "fullExchangeName": "NASDAQ",
                        "regularMarketPrice": { "raw": 150.0, "fmt": "150.00" },
                        "regularMarketChange": { "raw": 2.5, "fmt": "2.50" },
                        "regularMarketChangePercent": { "raw": 1.69, "fmt": "1.69%" },
                        "regularMarketPreviousClose": { "raw": 147.5, "fmt": "147.50" },
                        "marketState": "REGULAR"
                    }
                ]
            }
        }
        """
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, testJSON.data(using: .utf8))
        }
        
        let session = makeTestSession()
        let service = NetworkServiceImpl(session: session)
        
        var receivedResult: MarketSummaryResponse?
        var receivedError: NetworkError?
        
        let expectation = XCTestExpectation(description: "Publisher completes")
        
        let cancellable = service.fetchPublisher(
            MarketSummaryResponse.self,
            endpoint: .marketSummary
        )
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    receivedError = error
                }
                expectation.fulfill()
            },
            receiveValue: { response in
                receivedResult = response
            }
        )
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        #expect(receivedError == nil)
        #expect(receivedResult != nil)
        #expect(receivedResult?.marketSummaryAndSparkResponse.result.count == 1)
        #expect(receivedResult?.marketSummaryAndSparkResponse.result.first?.symbol == "AAPL")
        
        cancellable.cancel()
    }
    
    // MARK: - HTTP Error Tests
    
    @Test func testHTTPError404() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 404,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, nil)
        }
        
        let session = makeTestSession()
        let service = NetworkServiceImpl(session: session)
        
        var receivedError: NetworkError?
        let expectation = XCTestExpectation(description: "Publisher fails")
        
        let cancellable = service.fetchPublisher(
            MarketSummaryResponse.self,
            endpoint: .marketSummary
        )
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    receivedError = error
                }
                expectation.fulfill()
            },
            receiveValue: { _ in }
        )
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        #expect(receivedError != nil)
        if case .requestFailed(let statusCode, _) = receivedError {
            #expect(statusCode == 404)
        } else {
            Issue.record("Expected requestFailed error")
        }
        
        cancellable.cancel()
    }
    
    @Test func testHTTPError500() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }
        
        let session = makeTestSession()
        let service = NetworkServiceImpl(session: session)
        
        var receivedError: NetworkError?
        let expectation = XCTestExpectation(description: "Publisher fails")
        
        let cancellable = service.fetchPublisher(
            MarketSummaryResponse.self,
            endpoint: .marketSummary
        )
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    receivedError = error
                }
                expectation.fulfill()
            },
            receiveValue: { _ in }
        )
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        if case .requestFailed(let statusCode, _) = receivedError {
            #expect(statusCode == 500)
        } else {
            Issue.record("Expected requestFailed with 500")
        }
        
        cancellable.cancel()
    }
    
    // MARK: - Decoding Error Tests
    
    @Test func testDecodingFailure() async throws {
        let invalidJSON = """
        {
            "invalid": "structure"
        }
        """
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, invalidJSON.data(using: .utf8))
        }
        
        let session = makeTestSession()
        let service = NetworkServiceImpl(session: session)
        
        var receivedError: NetworkError?
        let expectation = XCTestExpectation(description: "Publisher fails")
        
        let cancellable = service.fetchPublisher(
            MarketSummaryResponse.self,
            endpoint: .marketSummary
        )
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    receivedError = error
                }
                expectation.fulfill()
            },
            receiveValue: { _ in }
        )
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        if case .decodingFailed(_, let data) = receivedError {
            #expect(data != nil)
        } else {
            Issue.record("Expected decodingFailed error")
        }
        
        cancellable.cancel()
    }
    
    @Test func testEmptyDataError() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }
        
        let session = makeTestSession()
        let service = NetworkServiceImpl(session: session)
        
        var receivedError: NetworkError?
        let expectation = XCTestExpectation(description: "Publisher fails")
        
        let cancellable = service.fetchPublisher(
            MarketSummaryResponse.self,
            endpoint: .marketSummary
        )
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    receivedError = error
                }
                expectation.fulfill()
            },
            receiveValue: { _ in }
        )
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        if case .noData = receivedError {
            // Success
        } else {
            Issue.record("Expected noData error")
        }
        
        cancellable.cancel()
    }
    
    // MARK: - Network Error Tests
    
    @Test func testTimeoutError() async throws {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.timedOut)
        }
        
        let session = makeTestSession()
        let service = NetworkServiceImpl(session: session)
        
        var receivedError: NetworkError?
        let expectation = XCTestExpectation(description: "Publisher fails")
        
        let cancellable = service.fetchPublisher(
            MarketSummaryResponse.self,
            endpoint: .marketSummary
        )
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    receivedError = error
                }
                expectation.fulfill()
            },
            receiveValue: { _ in }
        )
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        if case .timeout = receivedError {
            // Success
        } else {
            Issue.record("Expected timeout error")
        }
        
        cancellable.cancel()
    }
    
    @Test func testNoConnectionError() async throws {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }
        
        let session = makeTestSession()
        let service = NetworkServiceImpl(session: session)
        
        var receivedError: NetworkError?
        let expectation = XCTestExpectation(description: "Publisher fails")
        
        let cancellable = service.fetchPublisher(
            MarketSummaryResponse.self,
            endpoint: .marketSummary
        )
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    receivedError = error
                }
                expectation.fulfill()
            },
            receiveValue: { _ in }
        )
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        if case .noConnection = receivedError {
            // Success
        } else {
            Issue.record("Expected noConnection error")
        }
        
        cancellable.cancel()
    }
    
    @Test func testCancelledError() async throws {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.cancelled)
        }
        
        let session = makeTestSession()
        let service = NetworkServiceImpl(session: session)
        
        var receivedError: NetworkError?
        let expectation = XCTestExpectation(description: "Publisher fails")
        
        let cancellable = service.fetchPublisher(
            MarketSummaryResponse.self,
            endpoint: .marketSummary
        )
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    receivedError = error
                }
                expectation.fulfill()
            },
            receiveValue: { _ in }
        )
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        if case .cancelled = receivedError {
            // Success
        } else {
            Issue.record("Expected cancelled error")
        }
        
        cancellable.cancel()
    }
}

// MARK: - XCTestExpectation for Swift Testing

final class XCTestExpectation: @unchecked Sendable {
    private let description: String
    private var isFulfilled = false
    private let lock = NSLock()
    
    init(description: String) {
        self.description = description
    }
    
    func fulfill() {
        lock.lock()
        isFulfilled = true
        lock.unlock()
    }
    
    var fulfilled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return isFulfilled
    }
}

func fulfillment(of expectations: [XCTestExpectation], timeout: TimeInterval) async {
    let deadline = Date().addingTimeInterval(timeout)
    
    while Date() < deadline {
        if expectations.allSatisfy({ $0.fulfilled }) {
            return
        }
        try? await Task.sleep(for: .milliseconds(10))
    }
}
