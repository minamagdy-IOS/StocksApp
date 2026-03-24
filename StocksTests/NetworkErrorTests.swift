//
//  NetworkErrorTests.swift
//  StocksTests
//

import Foundation
import Testing
@testable import Stocks

struct NetworkErrorTests {
    
    @Test func testInvalidURLError() {
        let error = NetworkError.invalidURL
        
        #expect(error.errorDescription == "The request URL is invalid.")
    }
    
    @Test func testRequestFailedError() {
        let error = NetworkError.requestFailed(statusCode: 404, data: nil)
        
        #expect(error.errorDescription == "Request failed with status code 404.")
    }
    
    @Test func testDecodingFailedError() {
        let underlyingError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let error = NetworkError.decodingFailed(underlying: underlyingError, data: nil)
        
        #expect(error.errorDescription?.contains("Failed to decode response") == true)
        #expect(error.errorDescription?.contains("Test error") == true)
    }
    
    @Test func testDecodingFailedErrorWithData() {
        let underlyingError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let rawData = "Invalid JSON".data(using: .utf8)
        let error = NetworkError.decodingFailed(underlying: underlyingError, data: rawData)
        
        #expect(error.errorDescription?.contains("Failed to decode response") == true)
        #expect(error.errorDescription?.contains("Raw response") == true)
        #expect(error.errorDescription?.contains("Invalid JSON") == true)
    }
    
    @Test func testNoDataError() {
        let error = NetworkError.noData
        
        #expect(error.errorDescription == "No data received from server.")
    }
    
    @Test func testCancelledError() {
        let error = NetworkError.cancelled
        
        #expect(error.errorDescription == "The request was cancelled.")
    }
    
    @Test func testTimeoutError() {
        let error = NetworkError.timeout
        
        #expect(error.errorDescription == "The request timed out.")
    }
    
    @Test func testNoConnectionError() {
        let error = NetworkError.noConnection
        
        #expect(error.errorDescription == "No internet connection available.")
    }
    
    @Test func testUnknownError() {
        let underlyingError = NSError(domain: "test", code: 999, userInfo: [NSLocalizedDescriptionKey: "Unknown error"])
        let error = NetworkError.unknown(underlying: underlyingError)
        
        #expect(error.errorDescription?.contains("An unexpected error occurred") == true)
        #expect(error.errorDescription?.contains("Unknown error") == true)
    }
}
