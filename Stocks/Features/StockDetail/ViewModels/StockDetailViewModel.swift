//
//  StockDetailViewModel.swift
//  Stocks
//

import Foundation
import Observation

@MainActor
@Observable
final class StockDetailViewModel {
    private(set) var detail: StockDetailResponse?
    private(set) var isLoading: Bool
    private(set) var errorMessage: String?

    private let symbol: String
    private let networkService: NetworkService

    init(symbol: String, networkService: NetworkService) {
        self.symbol = symbol
        self.networkService = networkService
        self.isLoading = true
    }

    func fetchDetail() async {
        isLoading = true
        errorMessage = nil
        detail = nil
        defer { isLoading = false }
        var stockSummaryError: String?
        do {
            let envelope = try await networkService.fetch(
                StockDetailAPIResponse.self,
                endpoint: .stockDetail(symbol: symbol)
            )
            if let apiError = envelope.quoteSummary.error,
               apiError.code != nil || !(apiError.description ?? "").isEmpty {
                stockSummaryError = apiError.description ?? apiError.code
            } else if let first = envelope.quoteSummary.result?.first {
                detail = first
            }
        } catch NetworkError.cancelled {
            // Cancellation is expected when leaving the screen.
            return
        } catch {
            stockSummaryError = (error as? NetworkError)?.errorDescription ?? error.localizedDescription
        }
        if detail == nil {
            await applyMarketSummaryFallback(previousError: stockSummaryError)
        }
    }

    private func applyMarketSummaryFallback(previousError: String?) async {
        do {
            let market = try await networkService.fetch(
                MarketSummaryResponse.self,
                endpoint: .marketSummary
            )
            guard let row = market.marketSummaryAndSparkResponse.result.first(where: { $0.symbol == symbol }) else {
                errorMessage = previousError ?? "No data for this symbol."
                return
            }
            detail = StockDetailResponse.fromMarketListStock(row)
            errorMessage = nil
        } catch {
            errorMessage = previousError
                ?? (error as? NetworkError)?.errorDescription
                ?? error.localizedDescription
        }
    }
}
