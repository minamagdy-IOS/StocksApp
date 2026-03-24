//
//  StockDetailViewModel.swift
//  Stocks
//

import Combine
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
    private var detailCancellable: AnyCancellable?
    private var fallbackCancellable: AnyCancellable?

    init(symbol: String, networkService: NetworkService) {
        self.symbol = symbol
        self.networkService = networkService
        self.isLoading = true
    }

    func fetchDetail() {
        isLoading = true
        errorMessage = nil
        detail = nil

        detailCancellable?.cancel()
        fallbackCancellable?.cancel()

        detailCancellable = networkService.fetchPublisher(
            StockDetailAPIResponse.self,
            endpoint: .stockDetail(symbol: symbol)
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                guard let self else { return }
                self.handlePrimaryCompletion(completion)
            },
            receiveValue: { [weak self] envelope in
                guard let self else { return }
                self.handlePrimaryResponse(envelope)
            }
        )
    }
    
    private func handlePrimaryCompletion(_ completion: Subscribers.Completion<NetworkError>) {
        switch completion {
        case .finished:
            if detail != nil {
                isLoading = false
                errorMessage = nil
            }
        case .failure(let error):
            if case .cancelled = error {
                isLoading = false
                return
            }
            if detail == nil {
                applyMarketSummaryFallback(
                    previousError: error.errorDescription ?? error.localizedDescription
                )
            } else {
                isLoading = false
            }
        }
    }
    
    private func handlePrimaryResponse(_ envelope: StockDetailAPIResponse) {
        if let apiError = envelope.quoteSummary.error,
           apiError.code != nil || !(apiError.description ?? "").isEmpty {
            let stockSummaryError = apiError.description ?? apiError.code
            applyMarketSummaryFallback(previousError: stockSummaryError)
        } else if let first = envelope.quoteSummary.result?.first {
            detail = first
            isLoading = false
            errorMessage = nil
        } else {
            applyMarketSummaryFallback(previousError: nil)
        }
    }

    private func applyMarketSummaryFallback(previousError: String?) {
        fallbackCancellable?.cancel()
        fallbackCancellable = networkService.fetchPublisher(
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
                    if self.detail == nil {
                        self.errorMessage = previousError ?? "No data for this symbol."
                    }
                case .failure(let error):
                    guard case .cancelled = error else {
                        self.errorMessage = previousError
                            ?? error.errorDescription
                            ?? error.localizedDescription
                        return
                    }
                }
            },
            receiveValue: { [weak self] market in
                guard let self else { return }
                guard let row = market.marketSummaryAndSparkResponse.result.first(where: { $0.symbol == self.symbol }) else {
                    return
                }
                self.detail = StockDetailResponse.fromMarketListStock(row)
                self.errorMessage = nil
            }
        )
    }
}

