# Stocks

iOS app built with **SwiftUI** that shows a **market summary** list (with intraday **sparklines**) and a **stock detail** screen. Market and quote data come from **[RapidAPI](https://rapidapi.com/)** Yahoo Finance–compatible APIs (`yh-finance.p.rapidapi.com`).

## Features

| Area | What you get |
|------|----------------|
| **List** | Market summary rows: symbol, name, price, day change (derived from price vs previous close when the API omits change fields), and a sparkline from `spark.close`. |
| **Search** | Filter the list by symbol or company name. |
| **Refresh** | Auto-refresh on a timer (`APIConstants.autoRefreshInterval`, default **8s**). |
| **Detail** | Quote summary (`/stock/v2/get-summary`): price, change, ranges, volume, key stats, profile, etc. Falls back to the list row’s data if the detail endpoint errors. |

## Stack

- **UI:** SwiftUI  
- **Concurrency / state:** `@Observable` view models on the main actor  
- **Networking:** Combine + `URLSession`, `NetworkService` protocol (mockable in tests)  
- **JSON:** `Codable` models in `Stocks/Core/Models`

## API

| Endpoint | Use |
|----------|-----|
| `GET /market/v2/get-summary?region=US` | List + spark data |
| `GET /stock/v2/get-summary` (symbol, region, lang) | Detail screen |

Headers: `x-rapidapi-key`, `x-rapidapi-host` (see `APIEndpoint.swift`).

## Setup

1. Open **`Stocks.xcodeproj`** in Xcode.
2. Run the **Stocks** scheme on a simulator or device.
3. Set **`RAPIDAPI_KEY`** in **Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables** for your own key.  
   The app can read a fallback key from `APIConstants` for development—**do not ship that key** in production.

## Project layout

```
Stocks/
  App/           App entry, shared NetworkService
  Features/      StockList (list, row, sparkline), StockDetail
  Core/          Network (endpoints, errors, service), Models (Stock, StockDetail, …)
StocksTests/     Unit tests (models, network, view models)
StocksUITests/   UI tests
```

## Tests

Run unit tests in Xcode (**⌘U**) or see `RUN_TESTS.md` / `TESTING_GUIDE.md` if present in the repo.
