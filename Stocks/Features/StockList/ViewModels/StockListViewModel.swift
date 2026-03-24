//
//  StockListViewModel.swift
//  Stocks
//

import Combine
import Foundation
import Observation

@MainActor
@Observable
final class StockListViewModel {
    private(set) var stocks: [Stock] = []
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?
    var searchQuery: String = ""

    var filteredStocks: [Stock] {
        guard !searchQuery.isEmpty else { return stocks }
        let query = searchQuery.lowercased()
        return stocks.filter { stock in
            stock.displayName.lowercased().contains(query) ||
            stock.symbol.lowercased().contains(query)
        }
    }

    private let networkService: NetworkService
    private var fetchCancellable: AnyCancellable?
    private var refreshTimerCancellable: AnyCancellable?

    init(networkService: NetworkService) {
        self.networkService = networkService
    }

    func startAutoRefresh() {
        stopAutoRefresh()
        fetchStocks()
        refreshTimerCancellable = Timer.publish(every: APIConstants.autoRefreshInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.fetchStocks()
            }
    }

    func stopAutoRefresh() {
        refreshTimerCancellable?.cancel()
        refreshTimerCancellable = nil
        fetchCancellable?.cancel()
        fetchCancellable = nil
    }

    private func fetchStocks() {
        isLoading = stocks.isEmpty
        errorMessage = nil
        fetchCancellable?.cancel()
        
        fetchCancellable = networkService.fetchPublisher(
            MarketSummaryResponse.self,
            endpoint: .marketSummary
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                guard let self else { return }
                defer { self.isLoading = false }
                
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    guard case .cancelled = error else {
                        self.errorMessage = error.errorDescription ?? error.localizedDescription
                        return
                    }
                }
            },
            receiveValue: { [weak self] response in
                self?.stocks = response.marketSummaryAndSparkResponse.result
            }
        )
    }
}
