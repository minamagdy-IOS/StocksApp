//
//  NetworkService.swift
//  Stocks
//

import Foundation

protocol NetworkService: Sendable {
    func fetch<T: Decodable>(_ type: T.Type, endpoint: APIEndpoint) async throws -> T
}

actor NetworkServiceImpl: NetworkService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetch<T: Decodable>(_ type: T.Type, endpoint: APIEndpoint) async throws -> T {
        guard let request = endpoint.urlRequest else {
            throw NetworkError.invalidURL
        }
        let (data, response) = try await performRequest(request)
        try validateResponse(response)
        return try decode(type, from: data)
    }

    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch is CancellationError {
            throw NetworkError.cancelled
        } catch let error as URLError where error.code == .cancelled {
            throw NetworkError.cancelled
        } catch {
            throw NetworkError.unknown(underlying: error)
        }
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown(underlying: URLError(.badServerResponse))
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.requestFailed(statusCode: httpResponse.statusCode)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        guard !data.isEmpty else {
            throw NetworkError.noData
        }
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw NetworkError.decodingFailed(underlying: error)
        }
    }
}
