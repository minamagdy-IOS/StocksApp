//
//  StockListViewModel.swift
//  Stocks
//

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
    private var refreshTask: Task<Void, Never>?

    init(networkService: NetworkService) {
        self.networkService = networkService
    }

    func startAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.fetchStocks()
                try? await Task.sleep(for: .seconds(APIConstants.autoRefreshInterval))
            }
        }
    }

    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    private func fetchStocks() async {
        isLoading = stocks.isEmpty
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response = try await networkService.fetch(
                MarketSummaryResponse.self,
                endpoint: .marketSummary
            )
            stocks = response.marketSummaryAndSparkResponse.result
        } catch NetworkError.cancelled {
            // Cancellation is expected during refresh/task teardown.
            return
        } catch {
            errorMessage = (error as? NetworkError)?.errorDescription ?? error.localizedDescription
        }
    }
}
