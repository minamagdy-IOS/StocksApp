//
//  APIEndpoint.swift
//  Stocks
//

import Foundation

enum APIEndpoint: Sendable {
    case marketSummary
    case stockDetail(symbol: String)

    var urlRequest: URLRequest? {
        guard let url = buildURL() else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = APIConstants.requestTimeout
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue(APIConstants.rapidAPIKey, forHTTPHeaderField: "x-rapidapi-key")
        request.setValue(APIConstants.rapidAPIHost, forHTTPHeaderField: "x-rapidapi-host")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private func buildURL() -> URL? {
        var components = URLComponents(string: APIConstants.baseURL)
        switch self {
        case .marketSummary:
            components?.path = "/market/v2/get-summary"
            components?.queryItems = [
                URLQueryItem(name: "region", value: APIConstants.defaultRegion)
            ]
        case .stockDetail(let symbol):
            components?.path = "/stock/v2/get-summary"
            components?.percentEncodedQuery = APIEndpoint.buildPercentEncodedQuery(items: [
                ("symbol", symbol),
                ("region", APIConstants.defaultRegion),
                ("lang", APIConstants.defaultLanguage)
            ])
        }
        return components?.url
    }

    /// Encodes query values so symbols like `^GSPC`, `BRK.B`, `BTC-USD` survive proxies and gateways.
    private static func buildPercentEncodedQuery(items: [(String, String)]) -> String {
        items.compactMap { name, value -> String? in
            guard let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryParamAllowed),
                  let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryParamAllowed) else {
                return nil
            }
            return "\(encodedName)=\(encodedValue)"
        }.joined(separator: "&")
    }
}

private extension CharacterSet {
    static let urlQueryParamAllowed: CharacterSet = {
        let general = CharacterSet.alphanumerics
        let extra = CharacterSet(charactersIn: "-._~")
        return general.union(extra)
    }()
}
