import SwiftUI
import PhotosUI
import StoreKit
import LocalAuthentication

struct EVItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var text: String
    var kind: String
    var source: String = ""
    var createdAt = Date()
    var favorite = false
    var imageData: Data?
    var lastShown: Date?
}

@MainActor
final class EVStore: ObservableObject {
    @Published var items: [EVItem] = [] { didSet { save() } }

    init() { load() }

    func add(_ item: EVItem) { items.insert(item, at: 0) }

    func toggleFavorite(_ id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].favorite.toggle()
    }

    func delete(_ id: UUID) { items.removeAll { $0.id == id } }

    func nextReceipt() -> EVItem? {
        guard !items.isEmpty else { return nil }
        let sorted = items.sorted {
            if $0.favorite != $1.favorite { return $0.favorite && !$1.favorite }
            return ($0.lastShown ?? .distantPast) < ($1.lastShown ?? .distantPast)
        }
        guard let chosen = sorted.first else { return nil }
        if let index = items.firstIndex(where: { $0.id == chosen.id }) { items[index].lastShown = .now }
        return chosen
    }

    private func save() { EVFileStorage.save(items) }

    private func load() {
        if let decoded = EVFileStorage.load([EVItem].self) { items = decoded }
    }
}

@MainActor
final class EVLockManager: ObservableObject {
    @Published var unlocked = false
    @Published var biometricLock: Bool {
        didSet { UserDefaults.standard.set(biometricLock, forKey: "evidence.biometricLock") }
    }

    init() { biometricLock = UserDefaults.standard.bool(forKey: "evidence.biometricLock") }

    func unlock() async {
        guard biometricLock else { unlocked = true; return }
        let context = LAContext()
        var authError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &authError) else {
            unlocked = true
            return
        }
        do {
            unlocked = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock your private Evidence vault")
        } catch {
            unlocked = false
        }
    }

    func lock() { if biometricLock { unlocked = false } }
}

@MainActor
final class EVPurchaseManager: ObservableObject {
    static let productID = "com.theaigency.evidence.lifetime"
    @Published var product: Product?
    @Published var unlocked = false
    @Published var errorMessage: String?

    init() { Task { await refresh() } }

    func refresh() async {
        do {
            product = try await Product.products(for: [Self.productID]).first
            unlocked = await entitled()
        } catch { errorMessage = error.localizedDescription }
    }

    func purchase() async {
        guard let product else { errorMessage = "Purchase is not configured yet."; return }
        do {
            let result = try await product.purchase()
            if case .success(let verification) = result {
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    unlocked = true
                case .unverified:
                    errorMessage = "The purchase could not be verified."
                }
            }
        } catch { errorMessage = error.localizedDescription }
    }

    func restore() async {
        try? await AppStore.sync()
        unlocked = await entitled()
    }

    private func entitled() async -> Bool {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.productID,
               transaction.revocationDate == nil { return true }
        }
        return false
    }
}

@main
struct EvidenceApp: App {
    @StateObject private var store = EVStore()
    @StateObject private var purchase = EVPurchaseManager()
    @StateObject private var lock = EVLockManager()

    var body: some Scene {
        WindowGroup { EVRootView().environmentObject(store).environmentObject(purchase).environmentObject(lock) }
    }
}

struct EVRootView: View {
    @EnvironmentObject var lock: EVLockManager
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("evidence.onboarded") private var onboarded = false

    var body: some View {
        Group {
            if !onboarded {
                EVOnboarding {
                    onboarded = true
                    Task { await lock.unlock() }
                }
            } else if lock.biometricLock && !lock.unlocked {
                EVLockedView()
            } else {
                EVMainView()
            }
        }
        .task { await lock.unlock() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active { lock.lock() }
            else { Task { await lock.unlock() } }
        }
        .privacySensitive()
    }
}

struct EVOnboarding: View {
    let finish: () -> Void
    var body: some View {
        TabView {
            EVOnboardPage(symbol: "brain.head.profile", title: "Your memory is selective", copy: "One bad moment can drown out a long record of things that went right.")
            EVOnboardPage(symbol: "doc.text.magnifyingglass", title: "Keep the receipts", copy: "Save compliments, wins, screenshots, feedback and moments you handled well.")
            VStack(spacing: 24) {
                Image(systemName: "lock.shield.fill").font(.system(size: 62)).foregroundStyle(.tint)
                Text("Private. Local. Yours.").font(.largeTitle.bold()).multilineTextAlignment(.center)
                Text("Evidence is not an affirmation generator. It resurfaces things that actually happened.").font(.title3).multilineTextAlignment(.center).foregroundStyle(.secondary)
                Button("START MY VAULT", action: finish).buttonStyle(.borderedProminent).controlSize(.large)
            }.padding(28)
        }.tabViewStyle(.page(indexDisplayMode: .always))
    }
}

struct EVOnboardPage: View {
    let symbol: String
    let title: String
    let copy: String
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: symbol).font(.system(size: 60)).foregroundStyle(.tint)
            Text(title).font(.largeTitle.bold()).multilineTextAlignment(.center)
            Text(copy).font(.title3).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }.padding(28)
    }
}

struct EVLockedView: View {
    @EnvironmentObject var lock: EVLockManager
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "lock.fill").font(.system(size: 54)).foregroundStyle(.tint)
            Text("Evidence is locked").font(.title.bold())
            Text("Authenticate to open your private vault.").foregroundStyle(.secondary)
            Button("Unlock") { Task { await lock.unlock() } }.buttonStyle(.borderedProminent).controlSize(.large)
        }.padding()
    }
}

struct EVMainView: View {
    @EnvironmentObject var store: EVStore
    @State private var showingAdd = false
    @State private var showingMode = false
    @State private var showingVault = false
    @State private var showingSettings = false
    @State private var receipt: EVItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("TODAY'S RECEIPT").font(.caption.bold()).foregroundStyle(.secondary)
                        Text("Your history, not hype.").font(.largeTitle.bold())
                    }

                    if let item = receipt {
                        EVReceiptCard(item: item)
                        Button("SHOW ME ANOTHER") { receipt = store.nextReceipt() }.buttonStyle(.bordered)
                        Button("I NEED EVIDENCE") { showingMode = true }.buttonStyle(.borderedProminent).controlSize(.large)
                    } else {
                        ContentUnavailableView("No evidence yet", systemImage: "checkmark.seal", description: Text("Save something real that you may want to remember later."))
                    }

                    Button { showingAdd = true } label: {
                        Label("ADD EVIDENCE", systemImage: "plus").frame(maxWidth: .infinity)
                    }.buttonStyle(.borderedProminent).controlSize(.large)
                }.padding(22)
            }
            .navigationTitle("Evidence")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { showingVault = true } label: { Image(systemName: "archivebox") }.accessibilityLabel("Vault")
                    Button { showingSettings = true } label: { Image(systemName: "gearshape") }.accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showingAdd, onDismiss: { if receipt == nil { receipt = store.nextReceipt() } }) { EVAddView() }
            .sheet(isPresented: $showingMode) { EVModeView() }
            .sheet(isPresented: $showingVault, onDismiss: {
                if let receipt, !store.items.contains(where: { $0.id == receipt.id }) { self.receipt = store.nextReceipt() }
            }) { EVVaultView() }
            .sheet(isPresented: $showingSettings) { EVSettingsView() }
            .onAppear { if receipt == nil { receipt = store.nextReceipt() } }
        }
    }
}

struct EVReceiptCard: View {
    let item: EVItem
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(item.kind.uppercased()).font(.caption.bold()).foregroundStyle(.secondary)
                Spacer()
                if item.favorite { Image(systemName: "star.fill").foregroundStyle(.yellow).accessibilityLabel("Favorite") }
            }
            if let data = item.imageData, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius: 14)).accessibilityLabel("Attached evidence image")
            }
            Text(item.text).font(.title2.weight(.semibold))
            if !item.source.isEmpty { Text("— \(item.source)").font(.subheadline).foregroundStyle(.secondary) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22))
    }
}

struct EVAddView: View {
    @EnvironmentObject var store: EVStore
    @EnvironmentObject var purchase: EVPurchaseManager
    @Environment(\.dismiss) var dismiss
    @State private var text = ""
    @State private var source = ""
    @State private var kind = "Win"
    @State private var photo: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var showingLimit = false
    private let kinds = ["Compliment", "Win", "Screenshot", "Feedback", "Milestone", "I Handled That", "Other"]

    var body: some View {
        NavigationStack {
            Form {
                Picker("Type", selection: $kind) { ForEach(kinds, id: \.self) { Text($0) } }
                TextField("What actually happened?", text: $text, axis: .vertical).lineLimit(3...8)
                TextField("Source or person (optional)", text: $source)
                if purchase.unlocked {
                    PhotosPicker("Attach screenshot or photo", selection: $photo, matching: .images)
                        .onChange(of: photo) { _, item in
                            Task {
                                let rawData = try? await item?.loadTransferable(type: Data.self)
                                imageData = EVImagePipeline.normalizedJPEG(rawData)
                            }
                        }
                } else {
                    Text("Screenshot attachments are included in the lifetime unlock.").font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Evidence")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if !purchase.unlocked && store.items.count >= 20 { showingLimit = true; return }
                        store.add(EVItem(text: text.trimmingCharacters(in: .whitespacesAndNewlines), kind: kind, source: source.trimmingCharacters(in: .whitespacesAndNewlines), imageData: imageData))
                        dismiss()
                    }.disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Free vault is full", isPresented: $showingLimit) { Button("OK") {} } message: { Text("Free includes 20 evidence entries. Lifetime unlock removes the limit and adds image attachments.") }
        }
    }
}

struct EVModeView: View {
    @EnvironmentObject var store: EVStore
    @Environment(\.dismiss) var dismiss
    @State private var current: EVItem?

    var body: some View {
        VStack(spacing: 22) {
            Text("YOU ASKED FOR EVIDENCE.").font(.caption.bold()).foregroundStyle(.secondary)
            if let item = current {
                EVReceiptCard(item: item)
                Button("SHOW ME MORE") { current = store.nextReceipt() }.buttonStyle(.borderedProminent)
            } else {
                ContentUnavailableView("No receipts yet", systemImage: "doc.text.magnifyingglass")
            }
            Text("Those things actually happened.").font(.headline).multilineTextAlignment(.center)
            Button("Done") { dismiss() }.buttonStyle(.bordered)
        }
        .padding(22)
        .onAppear { if current == nil { current = store.nextReceipt() } }
    }
}

struct EVVaultView: View {
    @EnvironmentObject var store: EVStore
    @Environment(\.dismiss) var dismiss
    @State private var search = ""
    @State private var pendingDelete: EVItem?

    private var filtered: [EVItem] {
        search.isEmpty ? store.items : store.items.filter {
            $0.text.localizedCaseInsensitiveContains(search) || $0.kind.localizedCaseInsensitiveContains(search) || $0.source.localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered) { item in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(item.kind).font(.caption.bold()).foregroundStyle(.secondary)
                            if item.favorite { Image(systemName: "star.fill").font(.caption).foregroundStyle(.yellow).accessibilityLabel("Favorite") }
                        }
                        Text(item.text).lineLimit(3)
                        if !item.source.isEmpty { Text(item.source).font(.caption).foregroundStyle(.secondary) }
                    }
                    .swipeActions {
                        Button(role: .destructive) { pendingDelete = item } label: { Label("Delete", systemImage: "trash") }
                        Button { store.toggleFavorite(item.id) } label: { Label(item.favorite ? "Unfavorite" : "Favorite", systemImage: item.favorite ? "star.slash" : "star") }.tint(.yellow)
                    }
                }
            }
            .searchable(text: $search)
            .navigationTitle("Vault")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .confirmationDialog("Delete this evidence?", isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }), titleVisibility: .visible) {
                Button("Delete permanently", role: .destructive) {
                    if let pendingDelete { store.delete(pendingDelete.id) }
                    pendingDelete = nil
                }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            } message: { Text("This removes the entry and any attached image from the local vault.") }
        }
    }
}

struct EVSettingsView: View {
    @EnvironmentObject var lock: EVLockManager
    @EnvironmentObject var purchase: EVPurchaseManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Privacy") {
                    Toggle("Require Face ID / device authentication", isOn: $lock.biometricLock)
                    Text("Evidence stays on this device in app-private protected storage. The app does not upload your entries or screenshots.").font(.footnote).foregroundStyle(.secondary)
                }
                Section("Lifetime Unlock") {
                    Button(purchase.product.map { "Unlock — \($0.displayPrice)" } ?? "Lifetime unlock") { Task { await purchase.purchase() } }.disabled(purchase.unlocked)
                    Button("Restore Purchases") { Task { await purchase.restore() } }
                    if purchase.unlocked { Label("Unlocked", systemImage: "checkmark.seal.fill").foregroundStyle(.green) }
                    if let error = purchase.errorMessage { Text(error).font(.footnote).foregroundStyle(.secondary) }
                }
                Section("About") { Text("Evidence is a reflection and journaling utility. It does not diagnose or treat mental-health conditions.").font(.footnote).foregroundStyle(.secondary) }
            }
            .navigationTitle("Settings")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
