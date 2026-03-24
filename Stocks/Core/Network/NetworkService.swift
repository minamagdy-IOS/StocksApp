//
//  NetworkService.swift
//  Stocks
//

import Combine
import Foundation
import OSLog

protocol NetworkService: AnyObject, Sendable {
    func fetchPublisher<T: Decodable>(
        _ type: T.Type,
        endpoint: APIEndpoint
    ) -> AnyPublisher<T, NetworkError>
}

/// Thread-safe network service using Combine.
/// @unchecked Sendable: Safe because URLSession is thread-safe and decoder/logger are immutable after init.
final class NetworkServiceImpl: NetworkService, @unchecked Sendable {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let logger = Logger(subsystem: "com.stocks.app", category: "network")

    init(session: URLSession = .shared, decoder: JSONDecoder? = nil) {
        self.session = session
        self.decoder = decoder ?? Self.defaultDecoder()
    }

    private static func defaultDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }

    func fetchPublisher<T: Decodable>(
        _ type: T.Type,
        endpoint: APIEndpoint
    ) -> AnyPublisher<T, NetworkError> {
        guard let request = endpoint.urlRequest else {
            logger.error("Failed to build URL request for endpoint")
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }

        let urlString = request.url?.absoluteString ?? "unknown"
        logger.debug("Requesting: \(urlString, privacy: .public)")

        return session.dataTaskPublisher(for: request)
            .mapError(mapURLError)
            .tryMap { [unowned self] data, response -> Data in
                try self.validateResponse(response, data: data)
                return data
            }
            .tryMap { [unowned self] data -> T in
                try self.decode(type, from: data)
            }
            .mapError(mapPublisherError)
            .eraseToAnyPublisher()
    }

    private func mapPublisherError(_ error: Error) -> NetworkError {
        error as? NetworkError ?? .unknown(underlying: error)
    }

    private func mapURLError(_ error: URLError) -> NetworkError {
        switch error.code {
        case .cancelled:
            return .cancelled
        case .timedOut:
            return .timeout
        case .notConnectedToInternet, .networkConnectionLost:
            return .noConnection
        default:
            return .unknown(underlying: error)
        }
    }

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("Response is not HTTPURLResponse")
            throw NetworkError.unknown(underlying: URLError(.badServerResponse))
        }

        logger.debug("Response status: \(httpResponse.statusCode)")

        guard (200...299).contains(httpResponse.statusCode) else {
            logger.error("Request failed with status \(httpResponse.statusCode)")
            throw NetworkError.requestFailed(statusCode: httpResponse.statusCode, data: data)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        guard !data.isEmpty else {
            logger.error("Received empty data")
            throw NetworkError.noData
        }

        do {
            let decoded = try decoder.decode(type, from: data)
            let typeName = String(describing: T.self)
            logger.debug("Successfully decoded \(typeName, privacy: .public)")
            return decoded
        } catch {
            let message = error.localizedDescription
            logger.error("Decoding failed: \(message, privacy: .public)")
            throw NetworkError.decodingFailed(underlying: error, data: data)
        }
    }
}
