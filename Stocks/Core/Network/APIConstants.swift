//
//  APIConstants.swift
//  Stocks
//

import Foundation

enum APIConstants {
    static let baseURL = "https://yh-finance.p.rapidapi.com"
    static let rapidAPIHost = "yh-finance.p.rapidapi.com"
    static let autoRefreshInterval: TimeInterval = 8
    static let defaultRegion = "US"
    static let defaultLanguage = "en"
    static let requestTimeout: TimeInterval = 30
    
    static var rapidAPIKey: String {
        guard let key = ProcessInfo.processInfo.environment["RAPIDAPI_KEY"] else {
            return "0c4fce0d32mshe17157162d6097dp1b5756jsn0958cc190c0c"
        }
        return key
    }
}


