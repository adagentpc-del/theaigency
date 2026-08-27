import SwiftUI

/// A small, no-shame stats readout — never a dashboard, never a breakable
/// streak. Currently embedded directly in `HomeView`; kept as its own view
/// so it stays swappable/testable without touching Home's layout.
struct StatsSummaryView: View {
    let summaryText: String

    var body: some View {
        Text(summaryText)
            .font(Theme.Typography.caption())
            .foregroundStyle(Theme.Color.inkSecondary)
            .accessibilityIdentifier(A11yID.Home.statsSummary)
    }
}

#Preview {
    StatsSummaryView(summaryText: "You started 4 things today.")
}
