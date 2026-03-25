//
//  StockListViewModelTests.swift
//  StocksTests
//

import Combine
import Foundation
import Testing
@testable import Stocks

@Suite(.serialized)
@MainActor
struct StockListViewModelTests {
    
    // MARK: - Test Data
    
    private func makeTestStock(symbol: String = "AAPL") -> Stock {
        Stock(
            symbol: symbol,
            shortName: "Apple Inc.",
            fullExchangeName: "NASDAQ",
            regularMarketPrice: MarketValue(raw: 150.0, fmt: "150.00"),
            regularMarketChange: MarketValue(raw: 2.5, fmt: "2.50"),
            regularMarketChangePercent: MarketValue(raw: 1.69, fmt: "1.69%"),
            regularMarketPreviousClose: MarketValue(raw: 147.5, fmt: "147.50"),
            marketState: "REGULAR"
        )
    }
    
    private func makeTestResponse() -> MarketSummaryResponse {
        MarketSummaryResponse(
            marketSummaryAndSparkResponse: MarketSummaryAndSparkResponse(
                result: [
                    makeTestStock(symbol: "AAPL"),
                    makeTestStock(symbol: "GOOGL"),
                    makeTestStock(symbol: "MSFT")
                ]
            )
        )
    }
    
    // MARK: - Success Tests
    
    @Test func testFetchStocksSuccess() async throws {
        let mockService = MockNetworkService()
        mockService.stubbedResult = .success(makeTestResponse())
        
        let viewModel = StockListViewModel(networkService: mockService)
        
        #expect(viewModel.stocks.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
        
        viewModel.startAutoRefresh()
        
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(viewModel.stocks.count == 3)
        #expect(viewModel.stocks.first?.symbol == "AAPL")
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
        #expect(mockService.fetchCallCount >= 1)
        
        viewModel.stopAutoRefresh()
    }
    
    @Test func testFetchStocksFailure() async throws {
        let mockService = MockNetworkService()
        mockService.stubbedResult = .failure(.timeout)
        
        let viewModel = StockListViewModel(networkService: mockService)
        
        viewModel.startAutoRefresh()
        
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(viewModel.stocks.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.errorMessage?.contains("timed out") == true)
        
        viewModel.stopAutoRefresh()
    }
    
    @Test func testCancellationDoesNotShowError() async throws {
        let mockService = MockNetworkService()
        mockService.stubbedResult = .failure(.cancelled)
        
        let viewModel = StockListViewModel(networkService: mockService)
        
        viewModel.startAutoRefresh()
        
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(viewModel.errorMessage == nil)
        
        viewModel.stopAutoRefresh()
    }
        
    // MARK: - Auto Refresh Tests
    
    @Test func testAutoRefreshCallsMultipleTimes() async throws {
        let mockService = MockNetworkService()
        mockService.stubbedResult = .success(makeTestResponse())
        
        let viewModel = StockListViewModel(networkService: mockService)
        
        viewModel.startAutoRefresh()
        
        try await Task.sleep(for: .milliseconds(100))
        let firstCallCount = mockService.fetchCallCount
        #expect(firstCallCount >= 1)
        
        viewModel.stopAutoRefresh()
    }
    
    @Test func testStopAutoRefreshCancelsRequests() async throws {
        let mockService = MockNetworkService()
        mockService.stubbedResult = .success(makeTestResponse())
        
        let viewModel = StockListViewModel(networkService: mockService)
        
        viewModel.startAutoRefresh()
        try await Task.sleep(for: .milliseconds(50))
        
        let callCountBeforeStop = mockService.fetchCallCount
        
        viewModel.stopAutoRefresh()
        
        try await Task.sleep(for: .milliseconds(100))
        
        let callCountAfterStop = mockService.fetchCallCount
        
        #expect(callCountAfterStop == callCountBeforeStop)
    }
    
    // MARK: - Loading State Tests
    
    @Test func testLoadingStateOnFirstFetch() async throws {
        let mockService = MockNetworkService()
        mockService.stubbedResult = .success(makeTestResponse())
        
        let viewModel = StockListViewModel(networkService: mockService)
        
        #expect(viewModel.isLoading == false)
        
        viewModel.startAutoRefresh()
        
        #expect(viewModel.isLoading == true)
        
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(viewModel.isLoading == false)
        
        viewModel.stopAutoRefresh()
    }
    
    @Test func testLoadingStateNotSetAfterFirstLoad() async throws {
        let mockService = MockNetworkService()
        mockService.stubbedResult = .success(makeTestResponse())
        
        let viewModel = StockListViewModel(networkService: mockService)
        
        viewModel.startAutoRefresh()
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(viewModel.stocks.count == 3)
        #expect(viewModel.isLoading == false)
        
        viewModel.stopAutoRefresh()
    }
}
