//
//  StockDetailView.swift
//  Stocks
//

import SwiftUI

struct StockDetailView: View {
    @State private var viewModel: StockDetailViewModel
    private let symbol: String

    init(symbol: String, networkService: NetworkService) {
        self.symbol = symbol
        _viewModel = State(
            initialValue: StockDetailViewModel(symbol: symbol, networkService: networkService)
        )
    }

    var body: some View {
        Group {
            if let errorMessage = viewModel.errorMessage, !viewModel.isLoading {
                errorView(message: errorMessage)
            } else if let detail = viewModel.detail, !viewModel.isLoading {
                detailContent(detail: detail)
            } else {
                loadingView
            }
        }
        .navigationTitle(symbol)
        .navigationBarTitleDisplayMode(.large)
        .task { viewModel.fetchDetail() }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading details...")
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

    private func detailContent(detail: StockDetailResponse) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                priceHeader(price: detail.price)
                Divider()
                if let summaryDetail = detail.summaryDetail {
                    statsSection(title: "Trading Info", items: tradingItems(from: summaryDetail, price: detail.price))
                }
                if let stats = detail.defaultKeyStatistics {
                    statsSection(title: "Key Statistics", items: keyStatItems(from: stats))
                }
                if let profile = detail.assetProfile {
                    profileSection(profile: profile)
                }
            }
            .padding()
        }
    }

    private func priceHeader(price: PriceData?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(price?.longName ?? price?.shortName ?? symbol)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(price?.regularMarketPrice?.fmt ?? "--")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                changeLabel(price: price)
            }
            if let exchange = price?.exchangeName {
                Text(exchange)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func changeLabel(price: PriceData?) -> some View {
        let change = price?.regularMarketChange?.fmt ?? "--"
        let percent = price?.regularMarketChangePercent?.fmt ?? "--"
        let isPositive = (price?.regularMarketChange?.raw ?? 0) >= 0
        return Text("\(change) (\(percent))")
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(isPositive ? Color.green : Color.red)
    }

    private func statsSection(title: String, items: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(items, id: \.0) { item in
                    statCell(label: item.0, value: item.1)
                }
            }
        }
    }

    private func statCell(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func tradingItems(from detail: SummaryDetail, price: PriceData?) -> [(String, String)] {
        [
            ("Open", price?.regularMarketOpen?.fmt ?? "--"),
            ("Prev Close", price?.regularMarketPreviousClose?.fmt ?? "--"),
            ("Day High", price?.regularMarketDayHigh?.fmt ?? "--"),
            ("Day Low", price?.regularMarketDayLow?.fmt ?? "--"),
            ("Volume", price?.regularMarketVolume?.fmt ?? "--"),
            ("Avg Volume", detail.averageVolume?.fmt ?? "--"),
            ("52W High", detail.fiftyTwoWeekHigh?.fmt ?? "--"),
            ("52W Low", detail.fiftyTwoWeekLow?.fmt ?? "--"),
            ("P/E (TTM)", detail.trailingPE?.fmt ?? "--"),
            ("Beta", detail.beta?.fmt ?? "--"),
            ("Div Yield", detail.dividendYield?.fmt ?? "--"),
            ("Market Cap", price?.marketCap?.fmt ?? "--")
        ]
    }

    private func keyStatItems(from stats: KeyStatistics) -> [(String, String)] {
        [
            ("EPS (TTM)", stats.trailingEps?.fmt ?? "--"),
            ("Forward EPS", stats.forwardEps?.fmt ?? "--"),
            ("Profit Margin", stats.profitMargins?.fmt ?? "--"),
            ("Enterprise Val", stats.enterpriseValue?.fmt ?? "--")
        ]
    }

    private func profileSection(profile: AssetProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Company Info")
                .font(.headline)
            VStack(alignment: .leading, spacing: 8) {
                if let sector = profile.sector {
                    labeledRow(label: "Sector", value: sector)
                }
                if let industry = profile.industry {
                    labeledRow(label: "Industry", value: industry)
                }
                if let employees = profile.fullTimeEmployees {
                    labeledRow(label: "Employees", value: employees.formatted())
                }
            }
            if let summary = profile.longBusinessSummary {
                Text(summary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(5)
            }
        }
    }

    private func labeledRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}
