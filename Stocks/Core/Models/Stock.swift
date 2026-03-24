//
//  Stock.swift
//  Stocks
//

import Foundation

// MARK: - Market Summary Response

struct MarketSummaryResponse: Decodable {
    let marketSummaryAndSparkResponse: MarketSummaryAndSparkResponse
}

struct MarketSummaryAndSparkResponse: Decodable {
    let result: [Stock]
}

// MARK: - Stock

struct Stock: Decodable, Identifiable {
    let symbol: String
    let shortName: String?
    let fullExchangeName: String?
    let regularMarketPrice: MarketValue?
    let regularMarketChange: MarketValue?
    let regularMarketChangePercent: MarketValue?
    let regularMarketPreviousClose: MarketValue?
    let marketState: String?

    var id: String { symbol }

    var displayName: String {
        shortName ?? symbol
    }

    var price: Double {
        regularMarketPrice?.raw ?? 0
    }

    var changePercent: Double {
        regularMarketChangePercent?.raw ?? 0
    }

    var change: Double {
        regularMarketChange?.raw ?? 0
    }

    var isPositive: Bool {
        changePercent >= 0
    }
}

// MARK: - Market Value

struct MarketValue: Decodable {
    let raw: Double?
    let fmt: String?
}
