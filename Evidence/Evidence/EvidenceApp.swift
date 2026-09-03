import SwiftUI
import PhotosUI

struct EvidenceItem: Identifiable, Codable {
    let id: UUID
    var text: String
    var kind: String
    var createdAt: Date
    var favorite: Bool
    var imageData: Data?
}

@MainActor
final class EvidenceStore: ObservableObject {
    @Published var items: [EvidenceItem] = [] { didSet { save() } }
    private let key = "evidence.items.v1"
    init() { load() }
    func add(text: String, kind: String, imageData: Data?) {
        items.insert(EvidenceItem(id: UUID(), text: text, kind: kind, createdAt: .now, favorite: false, imageData: imageData), at: 0)
    }
    private func save() { if let data = try? JSONEncoder().encode(items) { UserDefaults.standard.set(data, forKey: key) } }
    private func load() { if let data = UserDefaults.standard.data(forKey: key), let decoded = try? JSONDecoder().decode([EvidenceItem].self, from: data) { items = decoded } }
}

@main
struct EvidenceApp: App {
    @StateObject private var store = EvidenceStore()
    var body: some Scene { WindowGroup { EvidenceRootView().environmentObject(store) } }
}

struct EvidenceRootView: View {
    @EnvironmentObject var store: EvidenceStore
    @State private var showingAdd = false
    @State private var showingEvidence = false
    private var featured: EvidenceItem? { store.items.randomElement() }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Keep receipts for the things that actually happened.").font(.title2.bold()).multilineTextAlignment(.center)
                if let item = featured {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("TODAY'S RECEIPT").font(.caption.bold()).foregroundStyle(.secondary)
                        Text(item.text).font(.title3)
                        Text(item.kind).font(.caption).foregroundStyle(.secondary)
                    }.frame(maxWidth: .infinity, alignment: .leading).padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
                    Button("I NEED EVIDENCE") { showingEvidence = true }.buttonStyle(.borderedProminent)
                } else {
                    ContentUnavailableView("No evidence yet", systemImage: "checkmark.seal", description: Text("Save a compliment, win, screenshot, or moment you handled well."))
                }
                Spacer()
                Button("+ ADD EVIDENCE") { showingAdd = true }.buttonStyle(.borderedProminent)
            }.padding().navigationTitle("Evidence")
            .sheet(isPresented: $showingAdd) { AddEvidenceView() }
            .sheet(isPresented: $showingEvidence) { EvidenceModeView() }
        }
    }
}

struct AddEvidenceView: View {
    @EnvironmentObject var store: EvidenceStore
    @Environment(\.dismiss) var dismiss
    @State private var text = ""
    @State private var kind = "Win"
    @State private var photo: PhotosPickerItem?
    @State private var imageData: Data?
    let kinds = ["Compliment","Win","Screenshot","Feedback","Milestone","I Handled That","Other"]
    var body: some View {
        NavigationStack {
            Form {
                Picker("Type", selection: $kind) { ForEach(kinds, id: \.self) { Text($0) } }
                TextField("What happened?", text: $text, axis: .vertical).lineLimit(3...8)
                PhotosPicker("Attach image", selection: $photo, matching: .images).onChange(of: photo) { _, item in Task { imageData = try? await item?.loadTransferable(type: Data.self) } }
            }.navigationTitle("Add Evidence").toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Save") { store.add(text: text, kind: kind, imageData: imageData); dismiss() }.disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
            }
        }
    }
}

struct EvidenceModeView: View {
    @EnvironmentObject var store: EvidenceStore
    @Environment(\.dismiss) var dismiss
    @State private var index = 0
    var body: some View {
        VStack(spacing: 24) {
            Text("YOU ASKED FOR EVIDENCE.").font(.caption.bold()).foregroundStyle(.secondary)
            if !store.items.isEmpty {
                let item = store.items[index % store.items.count]
                Text(item.text).font(.largeTitle.bold()).multilineTextAlignment(.center)
                Text("Those things actually happened.").foregroundStyle(.secondary)
                Button("SHOW ME MORE") { index += 1 }.buttonStyle(.borderedProminent)
            }
            Button("Done") { dismiss() }.buttonStyle(.bordered)
        }.padding()
    }
}
