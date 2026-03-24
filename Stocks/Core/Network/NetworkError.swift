//
//  NetworkError.swift
//  Stocks
//

import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case requestFailed(statusCode: Int, data: Data?)
    case decodingFailed(underlying: Error, data: Data?)
    case noData
    case cancelled
    case timeout
    case noConnection
    case unknown(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL is invalid."
        case .requestFailed(let statusCode, _):
            return "Request failed with status code \(statusCode)."
        case .decodingFailed(let error, let data):
            var message = "Failed to decode response: \(error.localizedDescription)"
            if let data = data, let raw = String(data: data, encoding: .utf8) {
                message += "\nRaw response: \(raw.prefix(200))"
            }
            return message
        case .noData:
            return "No data received from server."
        case .cancelled:
            return "The request was cancelled."
        case .timeout:
            return "The request timed out."
        case .noConnection:
            return "No internet connection available."
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
}
