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
    let spark: SparkData?
    var id: String { symbol }
    var sparkClosePrices: [Double] {
        spark?.close ?? []
    }

    var displayName: String {
        shortName ?? symbol
    }

    var price: Double {
        regularMarketPrice?.raw ?? 0
    }

    var changePercent: Double {
        if let pct = regularMarketChangePercent?.raw {
            return pct
        }
        guard let prev = regularMarketPreviousClose?.raw, prev != 0 else { return 0 }
        return ((price - prev) / prev) * 100
    }

    var change: Double {
        if let delta = regularMarketChange?.raw {
            return delta
        }
        guard let prev = regularMarketPreviousClose?.raw else { return 0 }
        return price - prev
    }

    var isPositive: Bool {
        changePercent >= 0
    }
}

// MARK: - Spark (market summary)

struct SparkData: Decodable, Equatable {
    let close: [Double]?
    let previousClose: Double?
}

// MARK: - Market Value

struct MarketValue: Decodable {
    let raw: Double?
    let fmt: String?
}
