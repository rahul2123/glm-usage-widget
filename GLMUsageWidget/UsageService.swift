import Foundation
import Combine

class UsageService: ObservableObject {
    @Published var tokenUsages: [TokenUsage] = []
    @Published var isLoading = false
    @Published var pinnedTokenId: UUID? = SettingsManager.shared.pinnedTokenId

    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?

    init() {
        log("🔧 UsageService init")
        startFetching()
    }

    private func startFetching() {
        fetchUsage()
        timer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.log("⏰ Timer fired - refreshing...")
            self?.fetchUsage()
        }
    }

    func fetchUsage() {
        let configs = SettingsManager.shared.configs
        guard !configs.isEmpty else {
            tokenUsages = []
            isLoading = false
            return
        }

        isLoading = true

        // Set all tokens to loading state
        tokenUsages = configs.map { TokenUsage(config: $0, stats: nil, errorMessage: nil, isLoading: true) }

        let publishers = configs.map { config in
            fetchQuota(for: config)
                .map { response -> TokenUsage in
                    guard response.code == 200 else {
                        return TokenUsage(config: config, stats: nil, errorMessage: "API error: \(response.msg)", isLoading: false)
                    }
                    let stats = self.parseStats(from: response)
                    return TokenUsage(config: config, stats: stats, errorMessage: nil, isLoading: false)
                }
                .catch { error -> Just<TokenUsage> in
                    Just(TokenUsage(config: config, stats: nil, errorMessage: error.localizedDescription, isLoading: false))
                }
                .eraseToAnyPublisher()
        }

        Publishers.MergeMany(publishers)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                guard let self = self else { return }
                if let idx = self.tokenUsages.firstIndex(where: { $0.config.id == result.config.id }) {
                    self.tokenUsages[idx] = result
                }
                self.isLoading = self.tokenUsages.contains { $0.isLoading }
                self.log("✅ Updated \(result.config.name): \(result.stats?.tokenPercentage ?? -1)%")
            }
            .store(in: &cancellables)
    }

    private let apiBase = "https://api.z.ai"

    private func fetchQuota(for config: TokenConfig) -> AnyPublisher<QuotaLimitResponse, Error> {
        let url = URL(string: apiBase + "/api/monitor/usage/quota/limit")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(config.token)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"

        log("🌐 Fetching for \(config.name): \(url.absoluteString)")

        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .handleEvents(receiveOutput: { [weak self] data in
                let preview = String(data: data, encoding: .utf8).map { String($0.prefix(200)) } ?? ""
                self?.log("📦 [\(config.name)] \(preview)")
            })
            .decode(type: QuotaLimitResponse.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }

    private func parseStats(from response: QuotaLimitResponse) -> UsageStats {
        let tokenLimit = response.data.limits.first { $0.type == "TOKENS_LIMIT" && $0.unit == 3 }
        let percentage = tokenLimit?.percentage ?? 0.0
        let resetDate = tokenLimit?.nextResetTime.map { Date(timeIntervalSince1970: TimeInterval($0) / 1000) } ?? Date()

        let weeklyLimit = response.data.limits.first { $0.type == "TOKENS_LIMIT" && $0.unit == 6 }
        let weeklyPercentage = weeklyLimit?.percentage ?? 0.0
        let weeklyResetDate = weeklyLimit?.nextResetTime.map { Date(timeIntervalSince1970: TimeInterval($0) / 1000) } ?? Date()

        return UsageStats(
            tokenPercentage: percentage,
            resetTime: resetDate,
            weeklyPercentage: weeklyPercentage,
            weeklyResetTime: weeklyResetDate,
            lastUpdated: Date()
        )
    }

    private func log(_ message: String) {
        let logFile = "/tmp/glm-widget.log"
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let line = "\n[\(timestamp)] \(message)"
        if var existing = try? String(contentsOfFile: logFile, encoding: .utf8) {
            existing += line
            try? existing.write(toFile: logFile, atomically: true, encoding: .utf8)
        } else {
            try? line.write(toFile: logFile, atomically: true, encoding: .utf8)
        }
    }
}
