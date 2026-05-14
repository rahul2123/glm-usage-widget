import Foundation
import Security

class SettingsManager {
    static let shared = SettingsManager()

    private let keychainService = "com.glm.usage-widget"
    private let keychainAccount = "token-configs"
    let maxTokens = 5

    // UUID of the token whose % is shown in the menu bar label.
    // nil = show highest % across all tokens.
    var pinnedTokenId: UUID? {
        get {
            (UserDefaults.standard.string(forKey: "pinnedTokenId")).flatMap { UUID(uuidString: $0) }
        }
        set {
            if let id = newValue {
                UserDefaults.standard.set(id.uuidString, forKey: "pinnedTokenId")
            } else {
                UserDefaults.standard.removeObject(forKey: "pinnedTokenId")
            }
        }
    }

    var configs: [TokenConfig] {
        readFromKeychain()
    }

    var hasCredentials: Bool {
        !readFromKeychain().isEmpty
    }

    func save(configs: [TokenConfig]) {
        writeToKeychain(configs)
    }

    // Returns a pre-filled TokenConfig from ~/.claude/settings.json if present.
    // Used to populate the Add form on first run.
    func migrateFromClaudeSettings() -> TokenConfig? {
        let path = "\(NSHomeDirectory())/.claude/settings.json"
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let env = json["env"] as? [String: String],
              let token = env["ANTHROPIC_AUTH_TOKEN"], !token.isEmpty else {
            return nil
        }
        return TokenConfig(name: "Default", token: token)
    }

    // MARK: - Keychain

    private func readFromKeychain() -> [TokenConfig] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let configs = try? JSONDecoder().decode([TokenConfig].self, from: data) else {
            return []
        }
        return configs
    }

    private func writeToKeychain(_ configs: [TokenConfig]) {
        guard let data = try? JSONEncoder().encode(configs) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]

        let existing = SecItemCopyMatching(query as CFDictionary, nil)
        if existing == errSecSuccess {
            let update: [String: Any] = [kSecValueData as String: data]
            SecItemUpdate(query as CFDictionary, update as CFDictionary)
        } else {
            var item = query
            item[kSecValueData as String] = data
            SecItemAdd(item as CFDictionary, nil)
        }
    }

    private init() {}
}
