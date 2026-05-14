import SwiftUI

// MARK: - Root View

struct MenuBarView: View {
    @ObservedObject var service: UsageService
    @State private var showingSettings = false

    var body: some View {
        VStack(spacing: 0) {
            if showingSettings {
                SettingsView(isShowing: $showingSettings, service: service)
            } else {
                TokenListView(usages: service.tokenUsages, isLoading: service.isLoading)
                Divider()
                ActionsView(service: service, showSettings: $showingSettings)
            }
        }
        .padding(16)
        .frame(width: 300)
        .onAppear {
            if !SettingsManager.shared.hasCredentials {
                showingSettings = true
            }
        }
    }
}

// MARK: - Token List View

struct TokenListView: View {
    let usages: [TokenUsage]
    let isLoading: Bool

    var body: some View {
        if usages.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: "key.slash").font(.system(size: 28)).foregroundColor(.secondary)
                Text("No tokens configured").font(.system(size: 13, weight: .medium))
                Text("Open Settings to add a token.").font(.system(size: 11)).foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        } else {
            VStack(spacing: 12) {
                ForEach(usages) { usage in
                    TokenRowView(usage: usage)
                    if usage.id != usages.last?.id {
                        Divider()
                    }
                }
            }
        }
    }
}

// MARK: - Token Row View

struct TokenRowView: View {
    let usage: TokenUsage

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(usage.config.name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.primary)

            if usage.isLoading {
                HStack(spacing: 6) {
                    ProgressView().scaleEffect(0.7)
                    Text("Loading...").font(.system(size: 11)).foregroundColor(.secondary)
                }
            } else if let error = usage.errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange).font(.system(size: 11))
                    Text(error).font(.system(size: 11)).foregroundColor(.secondary).lineLimit(2)
                }
            } else if let stats = usage.stats {
                UsageBarsView(stats: stats)
            }
        }
    }
}

// MARK: - Usage Bars View

struct UsageBarsView: View {
    let stats: UsageStats

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 5-hour row
            HStack(spacing: 0) {
                Text("5h: ").font(.system(size: 11)).foregroundColor(.secondary).frame(width: 24, alignment: .leading)
                percentageBar(value: stats.tokenPercentage)
                Text("\(Int(stats.tokenPercentage))%")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(colorFor(stats.tokenPercentage))
                    .frame(width: 32, alignment: .trailing)
                Text("· \(timeUntil(stats.resetTime))")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .frame(width: 44, alignment: .trailing)
            }

            // Weekly row
            HStack(spacing: 0) {
                Text("7d: ").font(.system(size: 11)).foregroundColor(.secondary).frame(width: 24, alignment: .leading)
                percentageBar(value: stats.weeklyPercentage)
                Text("\(Int(stats.weeklyPercentage))%")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(colorFor(stats.weeklyPercentage))
                    .frame(width: 32, alignment: .trailing)
                Text("· \(timeUntil(stats.weeklyResetTime))")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .frame(width: 44, alignment: .trailing)
            }
        }
    }

    private func percentageBar(value: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3).fill(Color.gray.opacity(0.15))
                RoundedRectangle(cornerRadius: 3)
                    .fill(colorFor(value))
                    .frame(width: geo.size.width * CGFloat(min(value, 100) / 100))
            }
        }
        .frame(height: 6)
    }

    private func colorFor(_ p: Double) -> Color {
        if p >= 90 { return .red }
        else if p >= 70 { return .orange }
        else if p >= 50 { return .yellow }
        else { return .green }
    }

    private func timeUntil(_ date: Date) -> String {
        let interval = date.timeIntervalSinceNow
        guard interval > 0 else { return "now" }
        let h = Int(interval) / 3600
        let m = (Int(interval) % 3600) / 60
        return h > 0 ? "\(h)h\(m)m" : "\(m)m"
    }
}

// MARK: - Actions View

struct ActionsView: View {
    @ObservedObject var service: UsageService
    @Binding var showSettings: Bool

    var body: some View {
        VStack(spacing: 0) {
            actionButton(icon: "arrow.clockwise", label: "Refresh") {
                service.fetchUsage()
            }
            Divider()
            actionButton(icon: "gearshape", label: "Settings") {
                showSettings = true
            }
            Divider()
            actionButton(icon: "xmark", label: "Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }

    private func actionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 11))
                Text(label).font(.system(size: 12))
                Spacer()
            }
            .foregroundColor(.primary)
        }
        .buttonStyle(.plain)
        .padding(.vertical, 8)
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @Binding var isShowing: Bool
    @ObservedObject var service: UsageService

    // nil = showing token list; non-nil = editing/adding that config
    @State private var editingConfig: TokenConfig? = nil
    @State private var isAdding = false

    var body: some View {
        if isAdding || editingConfig != nil {
            TokenEditForm(
                config: editingConfig,
                isShowing: $isShowing,
                onSave: { updated in
                    var configs = SettingsManager.shared.configs
                    if let idx = configs.firstIndex(where: { $0.id == updated.id }) {
                        configs[idx] = updated
                    } else {
                        configs.append(updated)
                    }
                    SettingsManager.shared.save(configs: configs)
                    service.fetchUsage()
                    editingConfig = nil
                    isAdding = false
                },
                onCancel: {
                    editingConfig = nil
                    isAdding = false
                }
            )
        } else {
            TokenListSettingsView(
                isShowing: $isShowing,
                onAdd: { isAdding = true },
                onEdit: { config in editingConfig = config },
                service: service
            )
        }
    }
}

// MARK: - Settings: Token List

struct TokenListSettingsView: View {
    @Binding var isShowing: Bool
    let onAdd: () -> Void
    let onEdit: (TokenConfig) -> Void
    @ObservedObject var service: UsageService

    @State private var configs: [TokenConfig] = []
    @State private var pinnedTokenId: UUID? = SettingsManager.shared.pinnedTokenId

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tokens").font(.system(size: 13, weight: .semibold))
                Spacer()
                Button(action: onAdd) {
                    Label("Add", systemImage: "plus")
                        .font(.system(size: 11))
                }
                .disabled(configs.count >= SettingsManager.shared.maxTokens)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            if configs.isEmpty {
                Text("No tokens yet. Add one to get started.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 0) {
                    // Column header
                    HStack(spacing: 8) {
                        Text("Menu Bar")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .frame(width: 58, alignment: .center)
                        Text("Token")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.bottom, 4)

                    ForEach(configs) { config in
                        HStack(spacing: 8) {
                            // Radio-button style active selector
                            Button {
                                let newPin: UUID? = (pinnedTokenId == config.id) ? nil : config.id
                                pinnedTokenId = newPin
                                SettingsManager.shared.pinnedTokenId = newPin
                                service.pinnedTokenId = newPin
                            } label: {
                                Image(systemName: pinnedTokenId == config.id ? "largecircle.fill.circle" : "circle")
                                    .font(.system(size: 16))
                                    .foregroundColor(pinnedTokenId == config.id ? .accentColor : .secondary)
                            }
                            .buttonStyle(.plain)
                            .frame(width: 58, alignment: .center)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(config.name).font(.system(size: 12, weight: .medium))
                                Text(maskedToken(config.token)).font(.system(size: 10)).foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Edit") { onEdit(config) }
                                .buttonStyle(.plain)
                                .font(.system(size: 11))
                                .foregroundColor(.accentColor)
                            Button("Delete") { delete(config) }
                                .buttonStyle(.plain)
                                .font(.system(size: 11))
                                .foregroundColor(.red)
                        }
                        .padding(.vertical, 6)
                        if config.id != configs.last?.id { Divider() }
                    }
                }
                .padding(8)
                .background(Color.gray.opacity(0.08))
                .cornerRadius(6)

                Text("Select which token's % appears in the menu bar. If none selected, shows the highest.")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            if SettingsManager.shared.hasCredentials {
                HStack {
                    Spacer()
                    Button("Done") { isShowing = false }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                }
            }
        }
        .onAppear { configs = SettingsManager.shared.configs }
    }

    private func delete(_ config: TokenConfig) {
        var updated = SettingsManager.shared.configs
        updated.removeAll { $0.id == config.id }
        SettingsManager.shared.save(configs: updated)
        if pinnedTokenId == config.id {
            pinnedTokenId = nil
            SettingsManager.shared.pinnedTokenId = nil
            service.pinnedTokenId = nil
        }
        configs = updated
        service.fetchUsage()
    }

    private func maskedToken(_ token: String) -> String {
        guard token.count > 8 else { return String(repeating: "•", count: token.count) }
        let prefix = String(token.prefix(6))
        return prefix + "••••••••"
    }
}

// MARK: - Settings: Token Edit Form

struct TokenEditForm: View {
    let config: TokenConfig?
    @Binding var isShowing: Bool
    let onSave: (TokenConfig) -> Void
    let onCancel: () -> Void

    @State private var name: String = ""
    @State private var token: String = ""
    @State private var showToken: Bool = false

    var isEditing: Bool { config != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(isEditing ? "Edit Token" : "Add Token")
                .font(.system(size: 13, weight: .semibold))

            VStack(alignment: .leading, spacing: 4) {
                Text("Name").font(.system(size: 11)).foregroundColor(.secondary)
                TextField("e.g. Work Mac", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Auth Token").font(.system(size: 11)).foregroundColor(.secondary)
                    Spacer()
                    Button(showToken ? "Hide" : "Show") { showToken.toggle() }
                        .buttonStyle(.plain)
                        .font(.system(size: 10))
                        .foregroundColor(.accentColor)
                }
                if showToken {
                    TextField("sk-ant-...", text: $token)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12))
                } else {
                    SecureField("sk-ant-...", text: $token)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12))
                }
            }

            HStack {
                if SettingsManager.shared.hasCredentials || isEditing {
                    Button("Cancel", action: onCancel)
                        .buttonStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Save") {
                    let cfg = TokenConfig(
                        id: config?.id ?? UUID(),
                        name: name.isEmpty ? "Token" : name,
                        token: token
                    )
                    onSave(cfg)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(token.isEmpty)
            }
        }
        .onAppear {
            if let config = config {
                name = config.name
                token = config.token
            } else if !SettingsManager.shared.hasCredentials,
                      let migrated = SettingsManager.shared.migrateFromClaudeSettings() {
                name = migrated.name
                token = migrated.token
            }
        }
    }
}
