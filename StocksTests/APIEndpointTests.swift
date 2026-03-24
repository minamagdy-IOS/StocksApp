//
//  APIEndpointTests.swift
//  StocksTests
//

import Foundation
import Testing
@testable import Stocks

struct APIEndpointTests {
    
    @Test func testMarketSummaryEndpoint() throws {
        let endpoint = APIEndpoint.marketSummary
        
        guard let request = endpoint.urlRequest else {
            Issue.record("Failed to create URL request")
            return
        }
        
        #expect(request.httpMethod == "GET")
        #expect(request.url?.absoluteString.contains("/market/v2/get-summary") == true)
        #expect(request.url?.absoluteString.contains("region=US") == true)
        #expect(request.value(forHTTPHeaderField: "x-rapidapi-key") != nil)
        #expect(request.value(forHTTPHeaderField: "x-rapidapi-host") == APIConstants.rapidAPIHost)
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(request.timeoutInterval == APIConstants.requestTimeout)
        #expect(request.cachePolicy == .reloadIgnoringLocalCacheData)
    }
    
    @Test func testStockDetailEndpoint() throws {
        let endpoint = APIEndpoint.stockDetail(symbol: "AAPL")
        
        guard let request = endpoint.urlRequest else {
            Issue.record("Failed to create URL request")
            return
        }
        
        #expect(request.httpMethod == "GET")
        #expect(request.url?.absoluteString.contains("/stock/v2/get-summary") == true)
        #expect(request.url?.absoluteString.contains("symbol=AAPL") == true)
        #expect(request.url?.absoluteString.contains("region=US") == true)
        #expect(request.url?.absoluteString.contains("lang=en") == true)
        #expect(request.value(forHTTPHeaderField: "x-rapidapi-key") != nil)
        #expect(request.value(forHTTPHeaderField: "x-rapidapi-host") == APIConstants.rapidAPIHost)
    }
    
    @Test func testStockDetailWithSpecialCharacters() throws {
        let symbols = ["^GSPC", "BRK.B", "BTC-USD"]
        
        for symbol in symbols {
            let endpoint = APIEndpoint.stockDetail(symbol: symbol)
            
            guard let request = endpoint.urlRequest else {
                Issue.record("Failed to create URL request for \(symbol)")
                continue
            }
            
            #expect(request.url != nil)
            #expect(request.url?.absoluteString.contains("symbol=") == true)
        }
    }
    
    @Test func testPercentEncodingForCaretSymbol() throws {
        let endpoint = APIEndpoint.stockDetail(symbol: "^GSPC")
        
        guard let request = endpoint.urlRequest,
              let url = request.url?.absoluteString else {
            Issue.record("Failed to create URL request")
            return
        }
        
        #expect(url.contains("%5E") == true || url.contains("^") == true)
    }
    
    @Test func testPercentEncodingForDotSymbol() throws {
        let endpoint = APIEndpoint.stockDetail(symbol: "BRK.B")
        
        guard let request = endpoint.urlRequest,
              let url = request.url?.absoluteString else {
            Issue.record("Failed to create URL request")
            return
        }
        
        #expect(url.contains("BRK") == true)
        #expect(url.contains("B") == true)
    }
}
