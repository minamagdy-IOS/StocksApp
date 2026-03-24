//
//  StocksApp.swift
//  Stocks
//

import SwiftUI

@main
struct StocksApp: App {
    private let networkService: NetworkService = NetworkServiceImpl()

    var body: some Scene {
        WindowGroup {
            StockListView(networkService: networkService)
        }
    }
}
