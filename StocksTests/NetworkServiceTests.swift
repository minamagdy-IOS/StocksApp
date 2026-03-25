//
//  NetworkServiceTests.swift
//  StocksTests
//

import Combine
import Foundation
import Testing
@testable import Stocks

/// Serialized: `MockURLProtocol.requestHandler` is global and not safe for parallel tests.
@Suite(.serialized)
struct NetworkServiceTests {

    // MARK: - Mock URLProtocol

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
        config.protocolClasses = [MockURLProtocol.self] + (config.protocolClasses ?? [])
        return URLSession(configuration: config)
    }

    /// Waits for a single value then `.finished`, or the first failure.
    private func awaitValue<T: Decodable>(_ publisher: AnyPublisher<T, NetworkError>) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            var received: T?
            cancellable = publisher.sink(
                receiveCompletion: { completion in
                    defer { cancellable?.cancel() }
                    switch completion {
                    case .finished:
                        if let received = received {
                            continuation.resume(returning: received)
                        } else {
                            continuation.resume(throwing: NetworkError.noData)
                        }
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                },
                receiveValue: { value in
                    received = value
                }
            )
        }
    }

    /// Waits for the first failure (or `nil` if the stream completes successfully).
    private func awaitFailure<T: Decodable>(_ publisher: AnyPublisher<T, NetworkError>) async -> NetworkError? {
        await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = publisher.sink(
                receiveCompletion: { completion in
                    defer { cancellable?.cancel() }
                    switch completion {
                    case .finished:
                        continuation.resume(returning: nil)
                    case .failure(let error):
                        continuation.resume(returning: error)
                    }
                },
                receiveValue: { _ in }
            )
        }
    }

    // MARK: - Success

    @Test func testSuccessfulRequest() async throws {
        defer { MockURLProtocol.requestHandler = nil }

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

        let service = NetworkServiceImpl(session: makeTestSession())
        let result = try await awaitValue(
            service.fetchPublisher(MarketSummaryResponse.self, endpoint: .marketSummary)
        )

        #expect(result.marketSummaryAndSparkResponse.result.count == 1)
        #expect(result.marketSummaryAndSparkResponse.result.first?.symbol == "AAPL")
    }

    // MARK: - HTTP errors

    @Test func testHTTPError404() async throws {
        defer { MockURLProtocol.requestHandler = nil }

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 404,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, nil)
        }

        let service = NetworkServiceImpl(session: makeTestSession())
        let error = await awaitFailure(
            service.fetchPublisher(MarketSummaryResponse.self, endpoint: .marketSummary)
        )

        #expect(error != nil)
        if case .requestFailed(let statusCode, _) = error {
            #expect(statusCode == 404)
        } else {
            Issue.record("Expected requestFailed error")
        }
    }

    @Test func testHTTPError500() async throws {
        defer { MockURLProtocol.requestHandler = nil }

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let service = NetworkServiceImpl(session: makeTestSession())
        let error = await awaitFailure(
            service.fetchPublisher(MarketSummaryResponse.self, endpoint: .marketSummary)
        )

        if case .requestFailed(let statusCode, _) = error {
            #expect(statusCode == 500)
        } else {
            Issue.record("Expected requestFailed with 500")
        }
    }

    // MARK: - Decoding

    @Test func testDecodingFailure() async throws {
        defer { MockURLProtocol.requestHandler = nil }

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

        let service = NetworkServiceImpl(session: makeTestSession())
        let error = await awaitFailure(
            service.fetchPublisher(MarketSummaryResponse.self, endpoint: .marketSummary)
        )

        if case .decodingFailed(_, let data) = error {
            #expect(data != nil)
        } else {
            Issue.record("Expected decodingFailed error")
        }
    }

    @Test func testEmptyDataError() async throws {
        defer { MockURLProtocol.requestHandler = nil }

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let service = NetworkServiceImpl(session: makeTestSession())
        let error = await awaitFailure(
            service.fetchPublisher(MarketSummaryResponse.self, endpoint: .marketSummary)
        )

        if case .noData = error {
            // ok
        } else {
            Issue.record("Expected noData error")
        }
    }

    // MARK: - URLError mapping

    @Test func testTimeoutError() async throws {
        defer { MockURLProtocol.requestHandler = nil }

        MockURLProtocol.requestHandler = { _ in
            throw URLError(.timedOut)
        }

        let service = NetworkServiceImpl(session: makeTestSession())
        let error = await awaitFailure(
            service.fetchPublisher(MarketSummaryResponse.self, endpoint: .marketSummary)
        )

        if case .timeout = error {
            // ok
        } else {
            Issue.record("Expected timeout error")
        }
    }

    @Test func testNoConnectionError() async throws {
        defer { MockURLProtocol.requestHandler = nil }

        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let service = NetworkServiceImpl(session: makeTestSession())
        let error = await awaitFailure(
            service.fetchPublisher(MarketSummaryResponse.self, endpoint: .marketSummary)
        )

        if case .noConnection = error {
            // ok
        } else {
            Issue.record("Expected noConnection error")
        }
    }

    @Test func testCancelledError() async throws {
        defer { MockURLProtocol.requestHandler = nil }

        MockURLProtocol.requestHandler = { _ in
            throw URLError(.cancelled)
        }

        let service = NetworkServiceImpl(session: makeTestSession())
        let error = await awaitFailure(
            service.fetchPublisher(MarketSummaryResponse.self, endpoint: .marketSummary)
        )

        if case .cancelled = error {
            // ok
        } else {
            Issue.record("Expected cancelled error")
        }
    }
}
