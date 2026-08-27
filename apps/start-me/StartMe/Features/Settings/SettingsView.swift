import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsStore: SettingsStore
    let statsStore: StatsStore

    @State private var showingClearConfirmation = false
    @State private var didClearData = false

    var body: some View {
        Form {
            Section("Session") {
                Toggle("Haptics", isOn: $settingsStore.hapticsEnabled)
                    .accessibilityIdentifier(A11yID.Settings.hapticsToggle)
            }

            Section("Your Data") {
                Button(role: .destructive) {
                    showingClearConfirmation = true
                } label: {
                    Text("Clear Local Data")
                }
                .accessibilityIdentifier(A11yID.Settings.clearDataButton)

                if didClearData {
                    Text("Local data cleared.")
                        .font(Theme.Typography.caption())
                        .foregroundStyle(Theme.Color.inkSecondary)
                }
            }

            Section("About") {
                Link("Privacy Policy", destination: URL(string: "https://theAIgincy.com/apps/start-me/privacy")!)
                    .accessibilityIdentifier(A11yID.Settings.privacyLink)
                Link("Support", destination: URL(string: "https://theAIgincy.com/apps/start-me/support")!)
                    .accessibilityIdentifier(A11yID.Settings.supportLink)
                NavigationLink("About Start Me") {
                    AboutView()
                }
            }
        }
        .navigationTitle("Settings")
        .confirmationDialog(
            "Clear all local Start Me data?",
            isPresented: $showingClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear Local Data", role: .destructive) {
                statsStore.clearAllData()
                didClearData = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes your start counts. Task text is never stored, so there's nothing else to clear.")
        }
    }
}

private struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("Start Me")
                    .font(Theme.Typography.action())

                Text("You already know what you need to do. You just can't make yourself start. Start Me gives you the smallest possible first move and 60 seconds to begin.")
                    .font(Theme.Typography.body())

                Text("Everything runs on your device. Start Me has no account, no backend, and no AI — just a small local engine and a timer.")
                    .font(Theme.Typography.body())
                    .foregroundStyle(Theme.Color.inkSecondary)
            }
            .padding(Theme.Spacing.lg)
        }
        .navigationTitle("About")
    }
}

#Preview {
    NavigationStack {
        SettingsView(settingsStore: SettingsStore(), statsStore: StatsStore())
    }
}
