import SwiftUI

struct RewriteIntentView: View {
    let viewModel: JudgeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("What are you actually trying to do?")
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)
                .padding(.top, 12)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Intent.allCases) { intent in
                        Button {
                            Haptics.tap()
                            viewModel.selectIntent(intent)
                        } label: {
                            HStack {
                                Text(intent.title)
                                    .fontWeight(.semibold)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .frame(minHeight: Theme.minimumTapTarget)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                                    .fill(Color(uiColor: .secondarySystemBackground))
                            )
                        }
                        .accessibilityLabel(intent.title)
                        .accessibilityAddTraits(.isButton)
                    }
                }
            }

            Button("Cancel") {
                if case .rewriteIntent = viewModel.phase {
                    viewModel.reset()
                }
            }
            .frame(minHeight: Theme.minimumTapTarget)
        }
        .padding(20)
    }
}

#Preview {
    RewriteIntentView(viewModel: JudgeViewModel())
}
