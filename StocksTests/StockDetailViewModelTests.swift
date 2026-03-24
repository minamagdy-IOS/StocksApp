//
//  StockDetailViewModelTests.swift
//  StocksTests
//

import Combine
import Foundation
import Testing
@testable import Stocks

@MainActor
struct StockDetailViewModelTests {
    
    // MARK: - Test Data
    
    private func makeTestDetailResponse() -> StockDetailAPIResponse {
        let price = PriceData(
            symbol: "AAPL",
            shortName: "Apple Inc.",
            longName: "Apple Inc.",
            regularMarketPrice: DetailValue(raw: 150.0, fmt: "150.00"),
            regularMarketChange: DetailValue(raw: 2.5, fmt: "2.50"),
            regularMarketChangePercent: DetailValue(raw: 1.69, fmt: "1.69%"),
            regularMarketOpen: DetailValue(raw: 148.0, fmt: "148.00"),
            regularMarketDayHigh: DetailValue(raw: 151.0, fmt: "151.00"),
            regularMarketDayLow: DetailValue(raw: 147.0, fmt: "147.00"),
            regularMarketVolume: DetailValue(raw: 50000000, fmt: "50M"),
            regularMarketPreviousClose: DetailValue(raw: 147.5, fmt: "147.50"),
            marketCap: DetailValue(raw: 2500000000000, fmt: "2.5T"),
            exchangeName: "NASDAQ",
            currencySymbol: "$"
        )
        
        let detail = StockDetailResponse(
            price: price,
            summaryDetail: nil,
            defaultKeyStatistics: nil,
            assetProfile: nil
        )
        
        return StockDetailAPIResponse(
            quoteSummary: QuoteSummaryPayload(
                result: [detail],
                error: nil
            )
        )
    }
    
    private func makeTestMarketResponse() -> MarketSummaryResponse {
        MarketSummaryResponse(
            marketSummaryAndSparkResponse: MarketSummaryAndSparkResponse(
                result: [
                    Stock(
                        symbol: "AAPL",
                        shortName: "Apple Inc.",
                        fullExchangeName: "NASDAQ",
                        regularMarketPrice: MarketValue(raw: 150.0, fmt: "150.00"),
                        regularMarketChange: MarketValue(raw: 2.5, fmt: "2.50"),
                        regularMarketChangePercent: MarketValue(raw: 1.69, fmt: "1.69%"),
                        regularMarketPreviousClose: MarketValue(raw: 147.5, fmt: "147.50"),
                        marketState: "REGULAR"
                    )
                ]
            )
        )
    }
    
    private func makeErrorResponse() -> StockDetailAPIResponse {
        StockDetailAPIResponse(
            quoteSummary: QuoteSummaryPayload(
                result: nil,
                error: QuoteSummaryAPIError(
                    code: "NOT_FOUND",
                    description: "Symbol not found"
                )
            )
        )
    }
    
    // MARK: - Success Tests
    
    @Test func testFetchDetailSuccess() async throws {
        let mockService = MockNetworkService()
        mockService.stubbedResult = .success(makeTestDetailResponse())
        
        let viewModel = StockDetailViewModel(symbol: "AAPL", networkService: mockService)
        
        #expect(viewModel.isLoading == true)
        #expect(viewModel.detail == nil)
        
        viewModel.fetchDetail()
        
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(viewModel.detail != nil)
        #expect(viewModel.detail?.price?.symbol == "AAPL")
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
        #expect(mockService.fetchCallCount == 1)
    }
    
    @Test func testFetchDetailWithAPIError() async throws {
        let mockService = MockNetworkService()
        var callCount = 0
        
        let viewModel = StockDetailViewModel(symbol: "AAPL", networkService: mockService)
        
        mockService.stubbedResult = .success(makeErrorResponse())
        
        viewModel.fetchDetail()
        
        try await Task.sleep(for: .milliseconds(50))
        
        callCount = mockService.fetchCallCount
        #expect(callCount >= 1)
        
        mockService.stubbedResult = .success(makeTestMarketResponse())
        
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(mockService.fetchCallCount > callCount)
        #expect(viewModel.detail != nil)
        #expect(viewModel.isLoading == false)
    }
    
    @Test func testFetchDetailWithFallback() async throws {
        let mockService = MockNetworkService()
        
        let viewModel = StockDetailViewModel(symbol: "AAPL", networkService: mockService)
        
        mockService.stubbedResult = .failure(.timeout)
        
        viewModel.fetchDetail()
        
        try await Task.sleep(for: .milliseconds(50))
        
        let firstCallCount = mockService.fetchCallCount
        
        mockService.stubbedResult = .success(makeTestMarketResponse())
        
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(mockService.fetchCallCount > firstCallCount)
        #expect(viewModel.detail != nil)
        #expect(viewModel.isLoading == false)
    }
    
    @Test func testFetchDetailNetworkFailure() async throws {
        let mockService = MockNetworkService()
        mockService.stubbedResult = .failure(.noConnection)
        
        let viewModel = StockDetailViewModel(symbol: "AAPL", networkService: mockService)
        
        viewModel.fetchDetail()
        
        try await Task.sleep(for: .milliseconds(50))
        
        mockService.stubbedResult = .failure(.noConnection)
        
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(viewModel.detail == nil)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage != nil)
    }
    
    // MARK: - Cancellation Tests
    
    @Test func testCancellationClearsLoading() async throws {
        let mockService = MockNetworkService()
        mockService.stubbedResult = .failure(.cancelled)
        
        let viewModel = StockDetailViewModel(symbol: "AAPL", networkService: mockService)
        
        viewModel.fetchDetail()
        
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test func testFallbackCancellationClearsLoading() async throws {
        let mockService = MockNetworkService()
        
        let viewModel = StockDetailViewModel(symbol: "AAPL", networkService: mockService)
        
        mockService.stubbedResult = .failure(.timeout)
        viewModel.fetchDetail()
        
        try await Task.sleep(for: .milliseconds(50))
        
        mockService.stubbedResult = .failure(.cancelled)
        
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(viewModel.isLoading == false)
    }
    
    // MARK: - Loading State Tests
    
    @Test func testLoadingStateTransitions() async throws {
        let mockService = MockNetworkService()
        mockService.stubbedResult = .success(makeTestDetailResponse())
        
        let viewModel = StockDetailViewModel(symbol: "AAPL", networkService: mockService)
        
        #expect(viewModel.isLoading == true)
        
        viewModel.fetchDetail()
        
        #expect(viewModel.isLoading == true)
        
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(viewModel.isLoading == false)
    }
    
    @Test func testLoadingStateOnError() async throws {
        let mockService = MockNetworkService()
        mockService.stubbedResult = .failure(.timeout)
        
        let viewModel = StockDetailViewModel(symbol: "AAPL", networkService: mockService)
        
        viewModel.fetchDetail()
        
        try await Task.sleep(for: .milliseconds(50))
        
        mockService.stubbedResult = .failure(.timeout)
        
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(viewModel.isLoading == false)
    }
    
    // MARK: - Error Message Tests
    
    @Test func testErrorMessageSetOnFailure() async throws {
        let mockService = MockNetworkService()
        mockService.stubbedResult = .failure(.noConnection)
        
        let viewModel = StockDetailViewModel(symbol: "AAPL", networkService: mockService)
        
        viewModel.fetchDetail()
        
        try await Task.sleep(for: .milliseconds(50))
        
        mockService.stubbedResult = .failure(.noConnection)
        
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.errorMessage?.contains("internet") == true)
    }
    
    @Test func testErrorMessageClearedOnSuccess() async throws {
        let mockService = MockNetworkService()
        mockService.stubbedResult = .failure(.timeout)
        
        let viewModel = StockDetailViewModel(symbol: "AAPL", networkService: mockService)
        
        viewModel.fetchDetail()
        
        try await Task.sleep(for: .milliseconds(50))
        
        mockService.stubbedResult = .success(makeTestDetailResponse())
        
        viewModel.fetchDetail()
        
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(viewModel.errorMessage == nil)
    }
}
