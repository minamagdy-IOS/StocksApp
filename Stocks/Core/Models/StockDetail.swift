//
//  StockDetail.swift
//  Stocks
//

import Foundation

// MARK: - Top-level API envelope (Yahoo / RapidAPI wraps modules in quoteSummary)

struct StockDetailAPIResponse: Decodable {
    let quoteSummary: QuoteSummaryPayload

    enum CodingKeys: String, CodingKey {
        case quoteSummary
        case finance
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let payload = try container.decodeIfPresent(QuoteSummaryPayload.self, forKey: .quoteSummary) {
            quoteSummary = payload
        } else if let payload = try container.decodeIfPresent(QuoteSummaryPayload.self, forKey: .finance) {
            quoteSummary = payload
        } else {
            let modules = try StockDetailResponse(from: decoder)
            quoteSummary = QuoteSummaryPayload(result: [modules], error: nil)
        }
    }
}

struct QuoteSummaryPayload: Decodable {
    let result: [StockDetailResponse]?
    let error: QuoteSummaryAPIError?
}

struct QuoteSummaryAPIError: Decodable {
    let code: String?
    let description: String?
}

// MARK: - Stock modules (one element inside quoteSummary.result)

struct StockDetailResponse: Decodable {
    let price: PriceData?
    let summaryDetail: SummaryDetail?
    let defaultKeyStatistics: KeyStatistics?
    let assetProfile: AssetProfile?

    init(
        price: PriceData?,
        summaryDetail: SummaryDetail?,
        defaultKeyStatistics: KeyStatistics?,
        assetProfile: AssetProfile?
    ) {
        self.price = price
        self.summaryDetail = summaryDetail
        self.defaultKeyStatistics = defaultKeyStatistics
        self.assetProfile = assetProfile
    }
}

// MARK: - Price Data

struct PriceData: Decodable {
    let symbol: String?
    let shortName: String?
    let longName: String?
    let regularMarketPrice: DetailValue?
    let regularMarketChange: DetailValue?
    let regularMarketChangePercent: DetailValue?
    let regularMarketOpen: DetailValue?
    let regularMarketDayHigh: DetailValue?
    let regularMarketDayLow: DetailValue?
    let regularMarketVolume: DetailValue?
    let regularMarketPreviousClose: DetailValue?
    let marketCap: DetailValue?
    let exchangeName: String?
    let currencySymbol: String?

    init(
        symbol: String?,
        shortName: String?,
        longName: String?,
        regularMarketPrice: DetailValue?,
        regularMarketChange: DetailValue?,
        regularMarketChangePercent: DetailValue?,
        regularMarketOpen: DetailValue?,
        regularMarketDayHigh: DetailValue?,
        regularMarketDayLow: DetailValue?,
        regularMarketVolume: DetailValue?,
        regularMarketPreviousClose: DetailValue?,
        marketCap: DetailValue?,
        exchangeName: String?,
        currencySymbol: String?
    ) {
        self.symbol = symbol
        self.shortName = shortName
        self.longName = longName
        self.regularMarketPrice = regularMarketPrice
        self.regularMarketChange = regularMarketChange
        self.regularMarketChangePercent = regularMarketChangePercent
        self.regularMarketOpen = regularMarketOpen
        self.regularMarketDayHigh = regularMarketDayHigh
        self.regularMarketDayLow = regularMarketDayLow
        self.regularMarketVolume = regularMarketVolume
        self.regularMarketPreviousClose = regularMarketPreviousClose
        self.marketCap = marketCap
        self.exchangeName = exchangeName
        self.currencySymbol = currencySymbol
    }
}

// MARK: - Summary Detail

struct SummaryDetail: Decodable {
    let fiftyTwoWeekHigh: DetailValue?
    let fiftyTwoWeekLow: DetailValue?
    let averageVolume: DetailValue?
    let dividendYield: DetailValue?
    let trailingPE: DetailValue?
    let forwardPE: DetailValue?
    let beta: DetailValue?
}

// MARK: - Key Statistics

struct KeyStatistics: Decodable {
    let enterpriseValue: DetailValue?
    let profitMargins: DetailValue?
    let earningsQuarterlyGrowth: DetailValue?
    let revenueQuarterlyGrowth: DetailValue?
    let trailingEps: DetailValue?
    let forwardEps: DetailValue?
}

// MARK: - Asset Profile

struct AssetProfile: Decodable {
    let longBusinessSummary: String?
    let sector: String?
    let industry: String?
    let fullTimeEmployees: Int?
    let website: String?

    enum CodingKeys: String, CodingKey {
        case longBusinessSummary
        case sector
        case industry
        case fullTimeEmployees
        case website
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        longBusinessSummary = try container.decodeIfPresent(String.self, forKey: .longBusinessSummary)
        sector = try container.decodeIfPresent(String.self, forKey: .sector)
        industry = try container.decodeIfPresent(String.self, forKey: .industry)
        website = try container.decodeIfPresent(String.self, forKey: .website)
        fullTimeEmployees = AssetProfile.decodeEmployees(from: container, forKey: .fullTimeEmployees)
    }

    private static func decodeEmployees(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) -> Int? {
        if let value = try? container.decode(Int.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(Double.self, forKey: key) {
            return Int(value)
        }
        if let nested = try? container.decode(DetailValue.self, forKey: key), let raw = nested.raw {
            return Int(raw)
        }
        return nil
    }
}

// MARK: - Detail Value (Yahoo often uses { raw, fmt }; sometimes raw is Int or a plain number)

struct DetailValue: Decodable {
    let raw: Double?
    let fmt: String?
    let longFmt: String?

    enum CodingKeys: String, CodingKey {
        case raw
        case fmt
        case longFmt
    }

    init(from decoder: Decoder) throws {
        if var single = try? decoder.singleValueContainer() {
            if single.decodeNil() {
                raw = nil
                fmt = nil
                longFmt = nil
                return
            }
            if let doubleValue = try? single.decode(Double.self) {
                raw = doubleValue
                fmt = nil
                longFmt = nil
                return
            }
            if let intValue = try? single.decode(Int.self) {
                raw = Double(intValue)
                fmt = nil
                longFmt = nil
                return
            }
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let doubleValue = try? container.decode(Double.self, forKey: .raw) {
            raw = doubleValue
        } else if let intValue = try? container.decode(Int.self, forKey: .raw) {
            raw = Double(intValue)
        } else if let stringValue = try? container.decode(String.self, forKey: .raw) {
            raw = Double(stringValue.replacingOccurrences(of: ",", with: ""))
        } else {
            raw = nil
        }
        fmt = try container.decodeIfPresent(String.self, forKey: .fmt)
        longFmt = try container.decodeIfPresent(String.self, forKey: .longFmt)
    }

    init(raw: Double?, fmt: String?, longFmt: String? = nil) {
        self.raw = raw
        self.fmt = fmt
        self.longFmt = longFmt
    }
}

// MARK: - Build detail from market list row (same fields as `market/v2/get-summary`)

extension StockDetailResponse {
    static func fromMarketListStock(_ stock: Stock) -> StockDetailResponse {
        let previous = stock.regularMarketPreviousClose
        let current = stock.regularMarketPrice
        let change: DetailValue?
        let changePercent: DetailValue?
        if let changeFromApi = stock.regularMarketChange, changeFromApi.raw != nil {
            change = changeFromApi.asDetailValue
        } else if let c = current?.raw, let p = previous?.raw {
            let delta = c - p
            change = DetailValue(raw: delta, fmt: String(format: "%.2f", delta))
        } else {
            change = nil
        }
        if let pctFromApi = stock.regularMarketChangePercent, pctFromApi.raw != nil {
            changePercent = pctFromApi.asDetailValue
        } else if let c = current?.raw, let p = previous?.raw, p != 0 {
            let pct = ((c - p) / p) * 100
            changePercent = DetailValue(raw: pct, fmt: String(format: "%.2f%%", pct))
        } else {
            changePercent = nil
        }
        let price = PriceData(
            symbol: stock.symbol,
            shortName: stock.shortName,
            longName: stock.shortName,
            regularMarketPrice: stock.regularMarketPrice?.asDetailValue,
            regularMarketChange: change,
            regularMarketChangePercent: changePercent,
            regularMarketOpen: nil,
            regularMarketDayHigh: nil,
            regularMarketDayLow: nil,
            regularMarketVolume: nil,
            regularMarketPreviousClose: stock.regularMarketPreviousClose?.asDetailValue,
            marketCap: nil,
            exchangeName: stock.fullExchangeName,
            currencySymbol: nil
        )
        return StockDetailResponse(
            price: price,
            summaryDetail: nil,
            defaultKeyStatistics: nil,
            assetProfile: nil
        )
    }
}

private extension MarketValue {
    var asDetailValue: DetailValue {
        DetailValue(raw: raw, fmt: fmt, longFmt: nil)
    }
}
