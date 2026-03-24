//
//  MockNetworkService.swift
//  StocksTests
//

import Combine
import Foundation
@testable import Stocks

final class MockNetworkService: NetworkService, @unchecked Sendable {
    var stubbedResult: Result<Any, NetworkError>?
    var fetchCallCount = 0
    var lastEndpoint: APIEndpoint?
    
    func fetchPublisher<T: Decodable>(
        _ type: T.Type,
        endpoint: APIEndpoint
    ) -> AnyPublisher<T, NetworkError> {
        fetchCallCount += 1
        lastEndpoint = endpoint
        
        guard let result = stubbedResult else {
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
        stubbedResult = nil
        fetchCallCount = 0
        lastEndpoint = nil
    }
}
