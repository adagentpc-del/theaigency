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
    private let key = "evidence.store.v2"
    init() { load() }
    func add(_ item: EVItem) { items.insert(item, at: 0) }
    func toggleFavorite(_ id: UUID) { guard let i = items.firstIndex(where: { $0.id == id }) else { return }; items[i].favorite.toggle() }
    func delete(at offsets: IndexSet) { items.remove(atOffsets: offsets) }
    func nextReceipt() -> EVItem? {
        guard !items.isEmpty else { return nil }
        let sorted = items.sorted {
            if $0.favorite != $1.favorite { return $0.favorite && !$1.favorite }
            return ($0.lastShown ?? .distantPast) < ($1.lastShown ?? .distantPast)
        }
        guard let chosen = sorted.first else { return nil }
        if let i = items.firstIndex(where: { $0.id == chosen.id }) { items[i].lastShown = .now }
        return chosen
    }
    private func save() { if let data = try? JSONEncoder().encode(items) { UserDefaults.standard.set(data, forKey: key) } }
    private func load() { if let data = UserDefaults.standard.data(forKey: key), let decoded = try? JSONDecoder().decode([EVItem].self, from: data) { items = decoded } }
}

@MainActor
final class EVLockManager: ObservableObject {
    @Published var unlocked = false
    @AppStorage("evidence.biometricLock") var biometricLock = false
    func unlock() async {
        guard biometricLock else { unlocked = true; return }
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else { unlocked = true; return }
        do { unlocked = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock your private Evidence vault") } catch { unlocked = false }
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
    func refresh() async { do { product = try await Product.products(for: [Self.productID]).first; unlocked = await entitled() } catch { errorMessage = error.localizedDescription } }
    func purchase() async {
        guard let product else { errorMessage = "Purchase is not configured yet."; return }
        do {
            let result = try await product.purchase()
            if case .success(let verification) = result, case .verified(let transaction) = verification { await transaction.finish(); unlocked = true }
        } catch { errorMessage = error.localizedDescription }
    }
    func restore() async { try? await AppStore.sync(); unlocked = await entitled() }
    private func entitled() async -> Bool { for await r in Transaction.currentEntitlements { if case .verified(let t) = r, t.productID == Self.productID, t.revocationDate == nil { return true } }; return false }
}

@main
struct EvidenceApp: App {
    @StateObject private var store = EVStore()
    @StateObject private var purchase = EVPurchaseManager()
    @StateObject private var lock = EVLockManager()
    @Environment(\.scenePhase) private var phase
    var body: some Scene {
        WindowGroup { EVRootView().environmentObject(store).environmentObject(purchase).environmentObject(lock) }
            .onChange(of: phase) { _, newPhase in if newPhase != .active { lock.lock() } }
    }
}

struct EVRootView: View {
    @EnvironmentObject var lock: EVLockManager
    @AppStorage("evidence.onboarded") private var onboarded = false
    var body: some View {
        Group {
            if !onboarded { EVOnboarding { onboarded = true; Task { await lock.unlock() } } }
            else if lock.biometricLock && !lock.unlocked { EVLockedView() }
            else { EVMainView() }
        }.task { await lock.unlock() }
    }
}

struct EVOnboarding: View {
    var finish: () -> Void
    var body: some View {
        TabView {
            EVOnboardPage(symbol: "brain.head.profile", title: "Your memory is selective", body: "One bad moment can drown out a long record of things that went right.")
            EVOnboardPage(symbol: "doc.text.magnifyingglass", title: "Keep the receipts", body: "Save compliments, wins, screenshots, feedback and moments you handled well.")
            VStack(spacing: 22) { Image(systemName: "lock.shield.fill").font(.system(size: 60)); Text("Private. Local. Yours.").font(.largeTitle.bold()); Text("Evidence is not an affirmation generator. It resurfaces things that actually happened.").multilineTextAlignment(.center).foregroundStyle(.secondary); Button("START MY VAULT", action: finish).buttonStyle(.borderedProminent).controlSize(.large) }.padding(28)
        }.tabViewStyle(.page(indexDisplayMode: .always))
    }
}

struct EVOnboardPage: View {
    let symbol: String; let title: String; let body: String
    var body: some View { VStack(spacing: 22) { Image(systemName: symbol).font(.system(size: 60)); Text(title).font(.largeTitle.bold()).multilineTextAlignment(.center); Text(body).font(.title3).foregroundStyle(.secondary).multilineTextAlignment(.center) }.padding(28) }
}

struct EVLockedView: View {
    @EnvironmentObject var lock: EVLockManager
    var body: some View { VStack(spacing: 18) { Image(systemName: "lock.fill").font(.system(size: 54)); Text("Evidence is locked").font(.title.bold()); Button("Unlock") { Task { await lock.unlock() } }.buttonStyle(.borderedProminent) }.padding() }
}

struct EVMainView: View {
    @EnvironmentObject var store: EVStore
    @EnvironmentObject var purchase: EVPurchaseManager
    @State private var showingAdd = false
    @State private var showingMode = false
    @State private var showingVault = false
    @State private var showingSettings = false
    @State private var receipt: EVItem?
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 6) { Text("TODAY'S RECEIPT").font(.caption.bold()).foregroundStyle(.secondary); Text("Your history, not hype.").font(.largeTitle.bold()) }
                    if let item = receipt ?? store.items.first {
                        EVReceiptCard(item: item)
                        Button("SHOW ME ANOTHER") { receipt = store.nextReceipt() }.buttonStyle(.bordered)
                        Button("I NEED EVIDENCE") { showingMode = true }.buttonStyle(.borderedProminent).controlSize(.large)
                    } else {
                        ContentUnavailableView("No evidence yet", systemImage: "checkmark.seal", description: Text("Save something real that you may want to remember later."))
                    }
                    Button { showingAdd = true } label: { Label("ADD EVIDENCE", systemImage: "plus").frame(maxWidth: .infinity) }.buttonStyle(.borderedProminent).controlSize(.large)
                }.padding(22)
            }.navigationTitle("Evidence")
            .toolbar { ToolbarItemGroup(placement: .topBarTrailing) { Button { showingVault = true } label: { Image(systemName: "archivebox") }.accessibilityLabel("Vault"); Button { showingSettings = true } label: { Image(systemName: "gearshape") }.accessibilityLabel("Settings") } }
            .sheet(isPresented: $showingAdd) { EVAddView() }
            .sheet(isPresented: $showingMode) { EVModeView() }
            .sheet(isPresented: $showingVault) { EVVaultView() }
            .sheet(isPresented: $showingSettings) { EVSettingsView() }
            .onAppear { if receipt == nil { receipt = store.nextReceipt() } }
        }
    }
}

struct EVReceiptCard: View {
    let item: EVItem
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack { Text(item.kind.uppercased()).font(.caption.bold()).foregroundStyle(.secondary); Spacer(); if item.favorite { Image(systemName: "star.fill").foregroundStyle(.yellow) } }
            if let data = item.imageData, let image = UIImage(data: data) { Image(uiImage: image).resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius: 14)) }
            Text(item.text).font(.title2.weight(.semibold))
            if !item.source.isEmpty { Text("— \(item.source)").font(.subheadline).foregroundStyle(.secondary) }
        }.frame(maxWidth: .infinity, alignment: .leading).padding(20).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22))
    }
}

struct EVAddView: View {
    @EnvironmentObject var store: EVStore
    @EnvironmentObject var purchase: EVPurchaseManager
    @Environment(\.dismiss) var dismiss
    @State private var text = ""; @State private var source = ""; @State private var kind = "Win"; @State private var photo: PhotosPickerItem?; @State private var imageData: Data?
    let kinds = ["Compliment","Win","Screenshot","Feedback","Milestone","I Handled That","Other"]
    var body: some View {
        NavigationStack {
            Form {
                Picker("Type", selection: $kind) { ForEach(kinds, id: \.self) { Text($0) } }
                TextField("What actually happened?", text: $text, axis: .vertical).lineLimit(3...8)
                TextField("Source or person (optional)", text: $source)
                if purchase.unlocked { PhotosPicker("Attach screenshot or photo", selection: $photo, matching: .images).onChange(of: photo) { _, item in Task { imageData = try? await item?.loadTransferable(type: Data.self) } } }
                else { Text("Screenshot attachments are included in the lifetime unlock.").font(.footnote).foregroundStyle(.secondary) }
            }.navigationTitle("Add Evidence").toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("Save") { store.add(EVItem(text: text, kind: kind, source: source, imageData: imageData)); dismiss() }.disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (!purchase.unlocked && store.items.count >= 20)) } }
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
            if let item = current ?? store.nextReceipt() { EVReceiptCard(item: item); Button("SHOW ME MORE") { current = store.nextReceipt() }.buttonStyle(.borderedProminent) }
            Text("Those things actually happened.").font(.headline)
            Button("Done") { dismiss() }.buttonStyle(.bordered)
        }.padding(22)
    }
}

struct EVVaultView: View {
    @EnvironmentObject var store: EVStore
    @Environment(\.dismiss) var dismiss
    @State private var search = ""
    var filtered: [EVItem] { search.isEmpty ? store.items : store.items.filter { $0.text.localizedCaseInsensitiveContains(search) || $0.kind.localizedCaseInsensitiveContains(search) || $0.source.localizedCaseInsensitiveContains(search) } }
    var body: some View {
        NavigationStack {
            List { ForEach(filtered) { item in VStack(alignment: .leading, spacing: 5) { Text(item.kind).font(.caption.bold()).foregroundStyle(.secondary); Text(item.text).lineLimit(3); if !item.source.isEmpty { Text(item.source).font(.caption).foregroundStyle(.secondary) } }.swipeActions { Button { store.toggleFavorite(item.id) } label: { Label("Favorite", systemImage: "star") } } } }
                .searchable(text: $search).navigationTitle("Vault").toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
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
                Section("Privacy") { Toggle("Require Face ID / device authentication", isOn: $lock.biometricLock); Text("Evidence stays on this device. The app does not upload your entries or screenshots.").font(.footnote).foregroundStyle(.secondary) }
                Section("Lifetime Unlock") { Button(purchase.product.map { "Unlock — \($0.displayPrice)" } ?? "Lifetime unlock") { Task { await purchase.purchase() } }.disabled(purchase.unlocked); Button("Restore Purchases") { Task { await purchase.restore() } }; if purchase.unlocked { Label("Unlocked", systemImage: "checkmark.seal.fill") } }
            }.navigationTitle("Settings").toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
