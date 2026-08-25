import SwiftUI

/// Step 1 of 3 — the proposed message. Judgment does not happen here;
/// NEXT only advances to the goal step.
struct MessageStepView: View {
    @Bindable var viewModel: JudgeViewModel
    @FocusState private var isEditorFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Should I Text Him?")
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
                Text("Before you send it, run it by us.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("What are you thinking about sending?")
                .font(.headline)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.proposedMessage)
                    .focused($isEditorFocused)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.cornerRadius)
                            .fill(Color(uiColor: .secondarySystemBackground))
                    )
                    .accessibilityLabel("Message to judge")
                    .accessibilityHint("Paste or type the text you're considering sending.")

                if viewModel.proposedMessage.isEmpty {
                    Text("Paste what you're about to send...")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 20)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .frame(minHeight: 180)

            if !viewModel.proposedMessage.isEmpty {
                Button(role: .destructive) {
                    Haptics.tap()
                    viewModel.proposedMessage = ""
                } label: {
                    Label("Clear", systemImage: "xmark.circle")
                }
                .font(.subheadline)
                .frame(minHeight: Theme.minimumTapTarget, alignment: .leading)
                .accessibilityLabel("Clear message")
            }

            Spacer(minLength: 0)

            Button {
                isEditorFocused = false
                Haptics.tap()
                viewModel.proceedToGoal()
            } label: {
                Text("NEXT")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: Theme.minimumTapTarget)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!viewModel.isMessageValid)
            .accessibilityLabel("Next")
            .accessibilityHint(viewModel.isMessageValid ? "" : "Enter a message first")
        }
        .padding(20)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { isEditorFocused = false }
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

#Preview {
    MessageStepView(viewModel: JudgeViewModel())
}
