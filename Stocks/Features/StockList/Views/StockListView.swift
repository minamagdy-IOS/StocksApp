//
//  StockListView.swift
//  Stocks
//

import SwiftUI

struct StockListView: View {
    @State private var viewModel: StockListViewModel
    private let networkService: NetworkService

    init(networkService: NetworkService) {
        self.networkService = networkService
        _viewModel = State(initialValue: StockListViewModel(networkService: networkService))
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Markets")
                .searchable(
                    text: $viewModel.searchQuery,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Search stocks"
                )
        }
        .onAppear { viewModel.startAutoRefresh() }
        .onDisappear { viewModel.stopAutoRefresh() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            loadingView
        } else if let errorMessage = viewModel.errorMessage, viewModel.stocks.isEmpty {
            errorView(message: errorMessage)
        } else {
            stockList
        }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading markets...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var stockList: some View {
        List(viewModel.filteredStocks) { stock in
            NavigationLink {
                StockDetailView(symbol: stock.symbol, networkService: networkService)
            } label: {
                StockRowView(stock: stock)
            }
        }
        .listStyle(.insetGrouped)
        .overlay(emptySearchOverlay)
    }

    @ViewBuilder
    private var emptySearchOverlay: some View {
        if viewModel.filteredStocks.isEmpty && !viewModel.stocks.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("No results for \"\(viewModel.searchQuery)\"")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
