import SwiftUI

/// Step 3 of 3 — what happened before this. The user picks one of two
/// ways to describe it, then judgment (Step 4) runs on NEXT/JUDGE MY
/// TEXT — never before this step completes.
struct ContextStepView: View {
    @Bindable var viewModel: JudgeViewModel
    @FocusState private var isConversationFocused: Bool
    @FocusState private var isNotesFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                stepHeader

                Text("Okay. What happened before this?")
                    .font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)

                Picker("Context method", selection: $viewModel.contextMethod) {
                    Text("Paste conversation").tag(ContextMethod.conversation)
                    Text("Quick context").tag(ContextMethod.quick)
                }
                .pickerStyle(.segmented)
                .disabled(viewModel.isJudging)
                .accessibilityLabel("Context method")

                switch viewModel.contextMethod {
                case .conversation:
                    conversationSection
                case .quick:
                    quickContextSection
                }

                judgeButton
            }
            .padding(20)
        }
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isConversationFocused = false
                    isNotesFocused = false
                }
            }
        }
    }

    private var stepHeader: some View {
        HStack {
            Button {
                Haptics.tap()
                viewModel.backToGoal()
            } label: {
                Label("Back", systemImage: "chevron.left")
            }
            .frame(minHeight: Theme.minimumTapTarget, alignment: .leading)
            .disabled(viewModel.isJudging)
            Spacer()
            Text("Step 3 of 3")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Option A: paste conversation

    private var conversationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Paste just the relevant recent part of the conversation — you don't need the whole history.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.conversationText)
                    .focused($isConversationFocused)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.cornerRadius)
                            .fill(Color(uiColor: .secondarySystemBackground))
                    )
                    .accessibilityLabel("Recent conversation")
                    .accessibilityHint("Paste the relevant recent messages.")
                    .disabled(viewModel.isJudging)

                if viewModel.conversationText.isEmpty {
                    Text("Paste the recent conversation here...")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 20)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .frame(minHeight: 160)

            Text("This stays on your device and is never sent anywhere.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Option B: quick context

    private var quickContextSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            quickQuestion(title: "Who texted last?", selection: $viewModel.quickWhoTextedLast)
            quickQuestion(title: "How long since the last message?", selection: $viewModel.quickTimeSinceLastMessage)
            quickQuestion(title: "Did he respond to your last message/question?", selection: $viewModel.quickDidHeRespond)

            VStack(alignment: .leading, spacing: 8) {
                Text("Anything else I should know? (optional)")
                    .font(.subheadline.weight(.semibold))
                TextField("A sentence or two is plenty", text: $viewModel.quickAdditionalNotes, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .focused($isNotesFocused)
                    .lineLimit(1...3)
                    .disabled(viewModel.isJudging)
                    .accessibilityLabel("Anything else I should know")
            }
        }
    }

    @ViewBuilder
    private func quickQuestion<T: QuickChoiceOption & CaseIterable>(
        title: String,
        selection: Binding<T?>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            VStack(spacing: 8) {
                ForEach(Array(T.allCases)) { option in
                    Button {
                        Haptics.tap()
                        selection.wrappedValue = option
                    } label: {
                        HStack {
                            Text(option.title)
                            Spacer()
                            Image(systemName: selection.wrappedValue == option ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selection.wrappedValue == option ? Color.accentColor : .secondary)
                        }
                        .padding(12)
                        .frame(minHeight: Theme.minimumTapTarget)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(uiColor: .secondarySystemBackground))
                        )
                    }
                    .disabled(viewModel.isJudging)
                    .accessibilityLabel(option.title)
                    .accessibilityAddTraits(selection.wrappedValue == option ? [.isButton, .isSelected] : [.isButton])
                }
            }
        }
    }

    // MARK: - Judge CTA

    private var judgeButton: some View {
        Button {
            isConversationFocused = false
            isNotesFocused = false
            Task { await viewModel.submitContext() }
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
        .disabled(!viewModel.isContextValid || viewModel.isJudging)
        .accessibilityLabel(viewModel.isJudging ? "Judging your text" : "Judge my text")
        .accessibilityHint(viewModel.isContextValid ? "" : "Answer the context questions or paste a conversation first")
    }
}

#Preview {
    ContextStepView(viewModel: JudgeViewModel())
}
