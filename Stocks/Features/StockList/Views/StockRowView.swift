//
//  StockRowView.swift
//  Stocks
//

import SwiftUI

struct StockRowView: View {
    let stock: Stock

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            SparklineView(
                values: stock.sparkClosePrices,
                baseline: stock.spark?.previousClose,
                isPositive: stock.isPositive
            )
            .frame(width: 64, height: 36)

            symbolInfo
            Spacer(minLength: 8)
            priceInfo
        }
        .padding(.vertical, 6)
    }

    private var symbolInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(stock.symbol)
                .font(.headline)
                .foregroundStyle(.primary)
            Text(stock.displayName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var priceInfo: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(formattedPrice)
                .font(.headline)
                .foregroundStyle(.primary)
            changeBadge
        }
    }

    private var changeBadge: some View {
        Text(formattedChangeAmount)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(stock.isPositive ? Color.green : Color.red)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var formattedPrice: String {
        String(format: "%.2f", stock.price)
    }

    /// Absolute day change (matches typical watchlist spark rows).
    private var formattedChangeAmount: String {
        String(format: "%+.2f", stock.change)
    }
}
