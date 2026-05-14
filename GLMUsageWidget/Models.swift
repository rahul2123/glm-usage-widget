import Foundation

// MARK: - Token Configuration
struct TokenConfig: Codable, Identifiable {
    var id: UUID
    var name: String
    var token: String

    init(id: UUID = UUID(), name: String, token: String) {
        self.id = id
        self.name = name
        self.token = token
    }
}

// MARK: - Per-Token Usage
struct TokenUsage: Identifiable {
    var id: UUID { config.id }
    let config: TokenConfig
    let stats: UsageStats?
    let errorMessage: String?
    let isLoading: Bool
}

// MARK: - Quota Limit Response
struct QuotaLimitResponse: Codable {
    let code: Int
    let msg: String
    let data: QuotaLimitData
    let success: Bool
}

struct QuotaLimitData: Codable {
    let limits: [QuotaLimit]
    let level: String
}

struct QuotaLimit: Codable {
    let type: String
    let unit: Int
    let number: Int?
    let usage: Int?
    let currentValue: Int?
    let remaining: Int?
    let percentage: Double
    let nextResetTime: Int64?
}

// MARK: - Usage Stats
struct UsageStats {
    let tokenPercentage: Double
    let resetTime: Date
    let weeklyPercentage: Double
    let weeklyResetTime: Date
    let lastUpdated: Date
}
