import SwiftUI
import Combine

@main
struct GLMUsageWidgetApp: App {
    @StateObject private var service = UsageService()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(service: service)
        } label: {
            MenuBarLabel(service: service)
        }
        .menuBarExtraStyle(.window)
    }
}

struct MenuBarLabel: View {
    @ObservedObject var service: UsageService

    private var icon: NSImage {
        let img = NSApp.applicationIconImage.copy() as! NSImage
        img.size = NSSize(width: 16, height: 16)
        return img
    }

    private var displayUsage: TokenUsage? {
        if let pinned = service.pinnedTokenId {
            return service.tokenUsages.first { $0.config.id == pinned }
        }
        return service.tokenUsages
            .filter { $0.stats != nil }
            .max(by: { ($0.stats?.tokenPercentage ?? 0) < ($1.stats?.tokenPercentage ?? 0) })
    }

    private var displayPercentage: Double {
        displayUsage?.stats?.tokenPercentage ?? 0
    }

    var body: some View {
        HStack(spacing: 3) {
            Image(nsImage: icon)
            if service.tokenUsages.isEmpty && !SettingsManager.shared.hasCredentials {
                Text("⚠️").font(.system(size: 12))
            } else if service.tokenUsages.allSatisfy({ $0.isLoading }) {
                Text("...").font(.system(size: 12))
            } else {
                Text("\(Int(displayPercentage))%")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(colorForPercentage(displayPercentage))
            }
        }
    }

    private func colorForPercentage(_ p: Double) -> Color {
        if p >= 90 { return .red }
        else if p >= 70 { return .orange }
        else if p >= 50 { return .yellow }
        else { return .green }
    }
}
