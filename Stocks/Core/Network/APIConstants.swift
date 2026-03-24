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
            return "647d2802a9msh97fe2ab26f3ecbcp1a165cjsnb227259c30f0"
        }
        return key
    }
}


