import SwiftUI

struct InputView: View {
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

            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.inputText)
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
                    .disabled(viewModel.isJudging)

                if viewModel.inputText.isEmpty {
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

            if !viewModel.inputText.isEmpty {
                Button(role: .destructive) {
                    Haptics.tap()
                    viewModel.inputText = ""
                } label: {
                    Label("Clear", systemImage: "xmark.circle")
                }
                .font(.subheadline)
                .frame(minHeight: Theme.minimumTapTarget, alignment: .leading)
                .accessibilityLabel("Clear message")
            }

            Spacer(minLength: 0)

            judgeButton
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

    @ViewBuilder
    private var judgeButton: some View {
        Button {
            isEditorFocused = false
            Task { await viewModel.judge() }
        } label: {
            HStack {
                if viewModel.isJudging {
                    ProgressView()
                        .tint(.white)
                    Text("Reading the room…")
                } else {
                    Text("JUDGE MY TEXT")
                        .fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: Theme.minimumTapTarget)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(!viewModel.isInputValid || viewModel.isJudging)
        .accessibilityLabel(viewModel.isJudging ? "Judging your text" : "Judge my text")
        .accessibilityHint(viewModel.isInputValid ? "" : "Enter a message first")
    }
}

#Preview {
    InputView(viewModel: JudgeViewModel())
}
