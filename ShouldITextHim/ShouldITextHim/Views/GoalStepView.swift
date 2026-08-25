import SwiftUI

/// Step 2 of 3 — what the user is actually trying to accomplish. This
/// answer is reused later for rewrite suggestions, so it's never asked
/// twice.
struct GoalStepView: View {
    let viewModel: JudgeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader

            Text("What are you actually trying to accomplish?")
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Goal.allCases) { goal in
                        Button {
                            Haptics.tap()
                            viewModel.selectGoal(goal)
                        } label: {
                            HStack {
                                Text(goal.title)
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
                        .accessibilityLabel(goal.title)
                        .accessibilityAddTraits(.isButton)
                    }
                }
            }
        }
        .padding(20)
    }

    private var stepHeader: some View {
        HStack {
            Button {
                Haptics.tap()
                viewModel.backToMessage()
            } label: {
                Label("Back", systemImage: "chevron.left")
            }
            .frame(minHeight: Theme.minimumTapTarget, alignment: .leading)
            Spacer()
            Text("Step 2 of 3")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    GoalStepView(viewModel: JudgeViewModel())
}
