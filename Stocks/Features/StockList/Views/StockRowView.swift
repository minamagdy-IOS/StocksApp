//
//  StockRowView.swift
//  Stocks
//

import SwiftUI

struct StockRowView: View {
    let stock: Stock

    var body: some View {
        HStack {
            symbolInfo
            Spacer()
            priceInfo
        }
        .padding(.vertical, 4)
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
        Text(formattedChangePercent)
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

    private var formattedChangePercent: String {
        let sign = stock.isPositive ? "+" : ""
        return "\(sign)\(String(format: "%.2f", stock.changePercent))%"
    }
}
