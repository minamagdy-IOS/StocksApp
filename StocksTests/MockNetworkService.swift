//
//  MockNetworkService.swift
//  StocksTests
//

import Combine
import Foundation
@testable import Stocks


final class MockNetworkService: NetworkService, @unchecked Sendable {
    var responseQueue: [Result<Any, NetworkError>] = []
    var stubbedResult: Result<Any, NetworkError>?
    private(set) var fetchCallCount = 0
    private(set) var lastEndpoint: APIEndpoint?

    func fetchPublisher<T: Decodable>(
        _ type: T.Type,
        endpoint: APIEndpoint
    ) -> AnyPublisher<T, NetworkError> {
        fetchCallCount += 1
        lastEndpoint = endpoint

        let result: Result<Any, NetworkError>
        if !responseQueue.isEmpty {
            result = responseQueue.removeFirst()
        } else if let stubbed = stubbedResult {
            result = stubbed
        } else {
            return Fail(error: NetworkError.unknown(underlying: URLError(.unknown)))
                .eraseToAnyPublisher()
        }

        switch result {
        case .success(let value):
            guard let typedValue = value as? T else {
                return Fail(error: NetworkError.unknown(underlying: URLError(.unknown)))
                    .eraseToAnyPublisher()
            }
            return Just(typedValue)
                .setFailureType(to: NetworkError.self)
                .eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }

    func reset() {
        responseQueue.removeAll()
        stubbedResult = nil
        fetchCallCount = 0
        lastEndpoint = nil
    }
}
