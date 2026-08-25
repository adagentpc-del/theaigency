import SwiftUI

struct RewriteResultView: View {
    let viewModel: JudgeViewModel
    let goal: Goal
    let options: [RewriteOption]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(goal.title) — pick a starting point")
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)
                .padding(.top, 12)

            ScrollView {
                VStack(spacing: 14) {
                    ForEach(options) { option in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(option.text)
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Button {
                                Haptics.tap()
                                viewModel.copy(option.text)
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                                    .frame(minHeight: Theme.minimumTapTarget)
                            }
                            .buttonStyle(.bordered)
                            .accessibilityLabel("Copy this rewrite")
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                                .fill(Color(uiColor: .secondarySystemBackground))
                        )
                    }
                }
            }

            if viewModel.lastCopiedConfirmation {
                Text("Copied to clipboard")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityLiveRegionPolite()
            }

            HStack(spacing: 12) {
                Button("Start Over") {
                    Haptics.tap()
                    viewModel.reset()
                }
                .buttonStyle(.bordered)
                .frame(minHeight: Theme.minimumTapTarget)
            }
        }
        .padding(20)
    }
}

private extension View {
    /// Small shim so the "Copied" confirmation is announced by VoiceOver
    /// without requiring iOS 17's newer accessibility APIs everywhere else.
    func accessibilityLiveRegionPolite() -> some View {
        self.accessibilityAddTraits(.updatesFrequently)
    }
}

#Preview {
    RewriteResultView(
        viewModel: JudgeViewModel(),
        goal: .getClarity,
        options: RewriteEngine.options(for: .getClarity)
    )
}
