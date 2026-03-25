//
//  StockModelTests.swift
//  StocksTests
//

import Foundation
import Testing
@testable import Stocks

struct StockModelTests {
    
    @Test func testStockDecoding() throws {
        let json = """
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
        """
        
        let data = json.data(using: .utf8)!
        let stock = try JSONDecoder().decode(Stock.self, from: data)
        
        #expect(stock.symbol == "AAPL")
        #expect(stock.shortName == "Apple Inc.")
        #expect(stock.displayName == "Apple Inc.")
        #expect(stock.price == 150.0)
        #expect(stock.change == 2.5)
        #expect(stock.changePercent == 1.69)
        #expect(stock.isPositive == true)
    }
    
    @Test func testStockWithNegativeChange() throws {
        let json = """
        {
            "symbol": "AAPL",
            "shortName": "Apple Inc.",
            "regularMarketPrice": { "raw": 145.0, "fmt": "145.00" },
            "regularMarketChange": { "raw": -2.5, "fmt": "-2.50" },
            "regularMarketChangePercent": { "raw": -1.69, "fmt": "-1.69%" }
        }
        """
        
        let data = json.data(using: .utf8)!
        let stock = try JSONDecoder().decode(Stock.self, from: data)
        
        #expect(stock.change == -2.5)
        #expect(stock.changePercent == -1.69)
        #expect(stock.isPositive == false)
    }
    
    @Test func testStockDisplayNameFallback() throws {
        let json = """
        {
            "symbol": "AAPL"
        }
        """
        
        let data = json.data(using: .utf8)!
        let stock = try JSONDecoder().decode(Stock.self, from: data)
        
        #expect(stock.displayName == "AAPL")
    }
    
    @Test func testStockWithMissingValues() throws {
        let json = """
        {
            "symbol": "AAPL"
        }
        """
        
        let data = json.data(using: .utf8)!
        let stock = try JSONDecoder().decode(Stock.self, from: data)
        
        #expect(stock.price == 0)
        #expect(stock.change == 0)
        #expect(stock.changePercent == 0)
        #expect(stock.isPositive == true)
    }
    
    @Test func testStockDecodesSparkForSparkline() throws {
        let json = """
        {
            "symbol": "^GSPC",
            "shortName": "S&P 500",
            "regularMarketPrice": { "raw": 6591.9, "fmt": "6,591.90" },
            "regularMarketPreviousClose": { "raw": 6556.37, "fmt": "6,556.37" },
            "spark": {
                "previousClose": 6556.37,
                "close": [6600.0, 6595.0, 6591.9]
            }
        }
        """
        let data = json.data(using: .utf8)!
        let stock = try JSONDecoder().decode(Stock.self, from: data)

        #expect(stock.spark?.previousClose == 6556.37)
        #expect(stock.sparkClosePrices.count == 3)
        #expect(stock.sparkClosePrices.last == 6591.9)
    }

    @Test func testStockDerivesChangeFromPriceAndPreviousClose() throws {
        // Matches live `market/v2/get-summary` shape: no regularMarketChange* fields, only price + previous close.
        let json = """
        {
            "symbol": "^GSPC",
            "shortName": "S&P 500",
            "regularMarketPrice": { "raw": 6591.9, "fmt": "6,591.90" },
            "regularMarketPreviousClose": { "raw": 6556.37, "fmt": "6,556.37" }
        }
        """
        let data = json.data(using: .utf8)!
        let stock = try JSONDecoder().decode(Stock.self, from: data)

        #expect(abs(stock.change - 35.53) < 0.01)
        #expect(abs(stock.changePercent - (35.53 / 6556.37 * 100)) < 0.01)
        #expect(stock.isPositive == true)
    }

    @Test func testMarketSummaryResponseDecoding() throws {
        let json = """
        {
            "marketSummaryAndSparkResponse": {
                "result": [
                    {
                        "symbol": "AAPL",
                        "shortName": "Apple Inc."
                    },
                    {
                        "symbol": "GOOGL",
                        "shortName": "Alphabet Inc."
                    }
                ]
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(MarketSummaryResponse.self, from: data)
        
        #expect(response.marketSummaryAndSparkResponse.result.count == 2)
        #expect(response.marketSummaryAndSparkResponse.result[0].symbol == "AAPL")
        #expect(response.marketSummaryAndSparkResponse.result[1].symbol == "GOOGL")
    }
}
