import SwiftUI
import PhotosUI
import StoreKit

struct KOContender: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var imageData: Data?
    var wins = 0
    var losses = 0
    var disposition: String?
    var score: Int { wins - losses }
    var winRate: Double { wins + losses == 0 ? 0 : Double(wins) / Double(wins + losses) }
}

struct KODecision: Codable, Hashable {
    let winnerID: UUID
    let loserID: UUID
}

struct KOBattle: Identifiable, Codable {
    var id = UUID()
    var category: String
    var createdAt = Date()
    var contenders: [KOContender]
    var pairings: [[UUID]] = []
    var currentPairIndex = 0
    var decisions: [KODecision] = []
    var completed = false
}

enum KOPairingEngine {
    static func makePairs(for contenders: [KOContender]) -> [[UUID]] {
        guard contenders.count > 1 else { return [] }
        var pairs: [[UUID]] = []
        var seen = Set<String>()
        let maxPairs = min(contenders.count * 3, contenders.count * (contenders.count - 1) / 2)
        outer: for offset in 1..<contenders.count {
            for i in contenders.indices {
                let j = (i + offset) % contenders.count
                guard i != j else { continue }
                let a = contenders[i].id
                let b = contenders[j].id
                let key = [a.uuidString, b.uuidString].sorted().joined(separator: "|")
                guard !seen.contains(key) else { continue }
                seen.insert(key)
                pairs.append([a, b])
                if pairs.count >= maxPairs { break outer }
            }
        }
        return pairs
    }

    static func ranked(_ contenders: [KOContender]) -> [KOContender] {
        contenders.sorted {
            if $0.score != $1.score { return $0.score > $1.score }
            if $0.winRate != $1.winRate { return $0.winRate > $1.winRate }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }
}

@MainActor
final class KOStore: ObservableObject {
    @Published var current: KOBattle?
    @Published var history: [KOBattle] = []
    private struct Snapshot: Codable { let current: KOBattle?; let history: [KOBattle] }

    init() { load() }

    func start(category: String, contenders: [KOContender]) {
        current = KOBattle(category: category, contenders: contenders, pairings: KOPairingEngine.makePairs(for: contenders))
        save()
    }

    func choose(_ winnerID: UUID) {
        guard var battle = current, battle.currentPairIndex < battle.pairings.count else { return }
        let pair = battle.pairings[battle.currentPairIndex]
        guard pair.contains(winnerID), let loserID = pair.first(where: { $0 != winnerID }) else { return }
        if let winnerIndex = battle.contenders.firstIndex(where: { $0.id == winnerID }) { battle.contenders[winnerIndex].wins += 1 }
        if let loserIndex = battle.contenders.firstIndex(where: { $0.id == loserID }) { battle.contenders[loserIndex].losses += 1 }
        battle.decisions.append(KODecision(winnerID: winnerID, loserID: loserID))
        battle.currentPairIndex += 1
        if battle.currentPairIndex >= battle.pairings.count {
            battle.completed = true
            history.removeAll { $0.id == battle.id }
            history.insert(battle, at: 0)
        }
        current = battle
        save()
    }

    func undo() {
        guard var battle = current, let decision = battle.decisions.popLast(), battle.currentPairIndex > 0 else { return }
        if battle.completed { history.removeAll { $0.id == battle.id }; battle.completed = false }
        if let winnerIndex = battle.contenders.firstIndex(where: { $0.id == decision.winnerID }) {
            battle.contenders[winnerIndex].wins = max(0, battle.contenders[winnerIndex].wins - 1)
        }
        if let loserIndex = battle.contenders.firstIndex(where: { $0.id == decision.loserID }) {
            battle.contenders[loserIndex].losses = max(0, battle.contenders[loserIndex].losses - 1)
        }
        battle.currentPairIndex -= 1
        current = battle
        save()
    }

    func setDisposition(itemID: UUID, disposition: String) {
        if var battle = current, let index = battle.contenders.firstIndex(where: { $0.id == itemID }) {
            battle.contenders[index].disposition = disposition
            current = battle
        }
        for battleIndex in history.indices {
            if let contenderIndex = history[battleIndex].contenders.firstIndex(where: { $0.id == itemID }) {
                history[battleIndex].contenders[contenderIndex].disposition = disposition
            }
        }
        save()
    }

    func clearCurrent() { current = nil; save() }

    private func save() { KOFileStorage.save(Snapshot(current: current, history: history)) }

    private func load() {
        guard let snapshot = KOFileStorage.load(Snapshot.self) else { return }
        current = snapshot.current
        history = snapshot.history
    }
}

@MainActor
final class KOPurchaseManager: ObservableObject {
    static let productID = "com.theaigency.keepone.lifetime"
    @Published var product: Product?
    @Published var unlocked = false
    @Published var errorMessage: String?

    init() { Task { await refresh() } }

    func refresh() async {
        do {
            product = try await Product.products(for: [Self.productID]).first
            unlocked = await hasEntitlement()
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
        unlocked = await hasEntitlement()
    }

    private func hasEntitlement() async -> Bool {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.productID,
               transaction.revocationDate == nil { return true }
        }
        return false
    }
}

@main
struct KeepOneApp: App {
    @StateObject private var store = KOStore()
    @StateObject private var purchase = KOPurchaseManager()
    var body: some Scene {
        WindowGroup { KORootView().environmentObject(store).environmentObject(purchase) }
    }
}

struct KORootView: View {
    @EnvironmentObject var store: KOStore
    @AppStorage("keepone.onboarded") private var onboarded = false
    @State private var showingNew = false
    @State private var showingPaywall = false

    var body: some View {
        NavigationStack {
            Group {
                if !onboarded {
                    KOOnboarding { onboarded = true }
                } else if let battle = store.current {
                    if battle.completed { KOResultsView(battle: battle) }
                    else { KOBattleView(battle: battle) }
                } else {
                    KOHomeView(showingNew: $showingNew, showingPaywall: $showingPaywall)
                }
            }
            .sheet(isPresented: $showingNew) { KONewBattleView() }
            .sheet(isPresented: $showingPaywall) { KOPaywallView() }
        }
    }
}

struct KOOnboarding: View {
    let finish: () -> Void
    var body: some View {
        TabView {
            onboardingPage("Too much stuff?", "Stop asking whether every item is good enough to keep.", "shippingbox")
            onboardingPage("Make it compete", "Head-to-head choices reveal your real favorites with less decision fatigue.", "arrow.left.arrow.right")
            VStack(spacing: 24) {
                Image(systemName: "trophy.fill").font(.system(size: 64)).foregroundStyle(.tint)
                Text("Keep the winners").font(.largeTitle.bold()).multilineTextAlignment(.center)
                Text("Photos and decisions stay on your device. No account required.").font(.title3).multilineTextAlignment(.center).foregroundStyle(.secondary)
                Button("START A BATTLE", action: finish).buttonStyle(.borderedProminent).controlSize(.large)
            }.padding(28)
        }.tabViewStyle(.page(indexDisplayMode: .always))
    }

    private func onboardingPage(_ title: String, _ copy: String, _ symbol: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: symbol).font(.system(size: 60)).foregroundStyle(.tint)
            Text(title).font(.largeTitle.bold()).multilineTextAlignment(.center)
            Text(copy).font(.title3).multilineTextAlignment(.center).foregroundStyle(.secondary)
        }.padding(28)
    }
}

struct KOHomeView: View {
    @EnvironmentObject var store: KOStore
    @EnvironmentObject var purchase: KOPurchaseManager
    @Binding var showingNew: Bool
    @Binding var showingPaywall: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("KEEP ONE").font(.caption.bold()).foregroundStyle(.secondary)
                    Text("Make your stuff compete.\nKeep the winners.").font(.largeTitle.bold())
                }

                Button {
                    if !purchase.unlocked && !store.history.isEmpty { showingPaywall = true }
                    else { showingNew = true }
                } label: {
                    Label(store.history.isEmpty || purchase.unlocked ? "START A BATTLE" : "UNLOCK MORE BATTLES", systemImage: purchase.unlocked ? "bolt.fill" : (store.history.isEmpty ? "bolt.fill" : "lock.open"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                if !purchase.unlocked {
                    Text(store.history.isEmpty ? "Your first battle is free, with up to 8 contenders." : "You used your free battle. Unlock once for unlimited battles and up to 64 contenders.")
                        .font(.footnote).foregroundStyle(.secondary)
                }

                if !store.history.isEmpty {
                    Text("RECENT BATTLES").font(.caption.bold()).foregroundStyle(.secondary)
                    ForEach(store.history.prefix(5)) { battle in
                        let ranked = KOPairingEngine.ranked(battle.contenders)
                        HStack(spacing: 12) {
                            Image(systemName: "trophy.fill").foregroundStyle(.tint)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(battle.category).font(.headline)
                                Text("\(battle.contenders.count) contenders").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let champion = ranked.first { Text(champion.name).font(.subheadline.bold()).lineLimit(1) }
                        }
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
                    }
                }

                Button { showingPaywall = true } label: {
                    Label(purchase.unlocked ? "Lifetime unlocked" : "Lifetime unlock", systemImage: purchase.unlocked ? "checkmark.seal.fill" : "sparkles")
                }.buttonStyle(.bordered)
            }.padding(22)
        }.navigationTitle("Keep One")
    }
}

struct KONewBattleView: View {
    @EnvironmentObject var store: KOStore
    @EnvironmentObject var purchase: KOPurchaseManager
    @Environment(\.dismiss) var dismiss
    @State private var category = "Closet"
    @State private var draft = ""
    @State private var photo: PhotosPickerItem?
    @State private var contenders: [KOContender] = []
    @State private var showLimit = false

    private var maxItems: Int { purchase.unlocked ? 64 : 8 }

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                TextField("What are we decluttering?", text: $category).textFieldStyle(.roundedBorder)
                HStack {
                    TextField("Item name", text: $draft).textFieldStyle(.roundedBorder)
                    PhotosPicker(selection: $photo, matching: .images) {
                        Image(systemName: "photo.badge.plus").font(.title2).frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Add item photo")
                    .onChange(of: photo) { _, item in
                        Task {
                            guard contenders.count < maxItems else { showLimit = true; photo = nil; return }
                            let rawData = try? await item?.loadTransferable(type: Data.self)
                            let data = KOImagePipeline.normalizedJPEG(rawData)
                            let cleanName = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                            contenders.append(KOContender(name: cleanName.isEmpty ? "Item \(contenders.count + 1)" : cleanName, imageData: data))
                            draft = ""
                            photo = nil
                        }
                    }
                }
                HStack { Text("\(contenders.count) / \(maxItems) contenders").font(.caption).foregroundStyle(.secondary); Spacer() }
                List {
                    ForEach(contenders) { item in
                        HStack { KOThumbnail(item: item).frame(width: 52, height: 52); Text(item.name) }
                    }.onDelete { contenders.remove(atOffsets: $0) }
                }.listStyle(.plain)
                Button("LET THEM FIGHT") {
                    store.start(category: category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Battle" : category, contenders: contenders)
                    dismiss()
                }
                .buttonStyle(.borderedProminent).controlSize(.large).disabled(contenders.count < 2)
            }
            .padding()
            .navigationTitle("New Battle")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .alert("Free limit reached", isPresented: $showLimit) { Button("OK") {} } message: { Text("Free battles support up to 8 contenders. Lifetime unlock supports up to 64.") }
        }
    }
}

struct KOBattleView: View {
    @EnvironmentObject var store: KOStore
    let battle: KOBattle

    private var pair: [KOContender] {
        guard battle.currentPairIndex < battle.pairings.count else { return [] }
        let ids = battle.pairings[battle.currentPairIndex]
        return ids.compactMap { id in battle.contenders.first { $0.id == id } }
    }

    var body: some View {
        VStack(spacing: 18) {
            Text(battle.category.uppercased()).font(.caption.bold()).foregroundStyle(.secondary)
            Text("KEEP ONE").font(.largeTitle.bold())
            Text("If you could only keep one, which wins?").foregroundStyle(.secondary).multilineTextAlignment(.center)
            ProgressView(value: Double(battle.currentPairIndex), total: Double(max(1, battle.pairings.count)))
                .accessibilityLabel("Battle progress")
            HStack(spacing: 12) {
                ForEach(pair) { item in
                    Button { store.choose(item.id) } label: {
                        VStack(spacing: 10) {
                            KOThumbnail(item: item).frame(height: 230)
                            Text(item.name).font(.headline).multilineTextAlignment(.center).lineLimit(2)
                        }
                        .frame(maxWidth: .infinity).padding(10)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Keep \(item.name)")
                }
            }
            Button("Undo last choice") { store.undo() }.disabled(battle.decisions.isEmpty)
        }.padding(20).navigationBarBackButtonHidden()
    }
}

struct KOResultsView: View {
    @EnvironmentObject var store: KOStore
    let battle: KOBattle
    private var ranked: [KOContender] { KOPairingEngine.ranked(battle.contenders) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("THE RESULTS ARE IN").font(.caption.bold()).foregroundStyle(.secondary)
                if let champion = ranked.first {
                    KOThumbnail(item: champion).frame(width: 190, height: 190)
                    Text("THE CHAMPION").font(.caption.bold()).foregroundStyle(.secondary)
                    Text(champion.name).font(.largeTitle.bold()).multilineTextAlignment(.center)
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text("YOUR KEEPERS").font(.headline)
                    ForEach(Array(ranked.prefix(max(1, ranked.count / 3)).enumerated()), id: \.element.id) { index, item in
                        HStack { Text("#\(index + 1)").foregroundStyle(.secondary); Text(item.name); Spacer(); Text("\(Int(item.winRate * 100))%") }
                    }
                }.frame(maxWidth: .infinity, alignment: .leading).padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))

                VStack(alignment: .leading, spacing: 12) {
                    Text("THE CUT LIST").font(.headline)
                    Text("These consistently lost when you had to choose. You decide what happens next.").font(.subheadline).foregroundStyle(.secondary)
                    ForEach(ranked.suffix(max(1, ranked.count / 3))) { item in
                        HStack(alignment: .center, spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.name).font(.body.weight(.medium))
                                Text("\(item.wins) wins / \(item.losses) losses").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Menu(item.disposition ?? "DECIDE") {
                                Button("Sell") { store.setDisposition(itemID: item.id, disposition: "Sell") }
                                Button("Donate") { store.setDisposition(itemID: item.id, disposition: "Donate") }
                                Button("Keep Anyway") { store.setDisposition(itemID: item.id, disposition: "Keep Anyway") }
                                Button("Undecided") { store.setDisposition(itemID: item.id, disposition: "Undecided") }
                            }.buttonStyle(.bordered)
                        }
                    }
                }.frame(maxWidth: .infinity, alignment: .leading).padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))

                ShareLink(item: "My \(battle.category) battle had \(battle.contenders.count) contenders. Champion: \(ranked.first?.name ?? "")") {
                    Label("Share Results", systemImage: "square.and.arrow.up")
                }.buttonStyle(.bordered)
                Button("DONE") { store.clearCurrent() }.buttonStyle(.borderedProminent).controlSize(.large)
            }.padding(22)
        }.navigationTitle("Results").navigationBarBackButtonHidden()
    }
}

struct KOPaywallView: View {
    @EnvironmentObject var purchase: KOPurchaseManager
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "trophy.fill").font(.system(size: 56)).foregroundStyle(.tint)
                Text("Keep One Unlocked").font(.largeTitle.bold()).multilineTextAlignment(.center)
                Text("Unlimited battles, up to 64 contenders, saved history, advanced results and future premium features.").multilineTextAlignment(.center).foregroundStyle(.secondary)
                Button(purchase.product.map { "Unlock for \($0.displayPrice)" } ?? "Lifetime unlock") { Task { await purchase.purchase() } }
                    .buttonStyle(.borderedProminent).controlSize(.large).disabled(purchase.unlocked)
                Button("Restore Purchases") { Task { await purchase.restore() } }.buttonStyle(.bordered)
                if purchase.unlocked { Label("Unlocked", systemImage: "checkmark.seal.fill").foregroundStyle(.green) }
                if let error = purchase.errorMessage { Text(error).font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center) }
                Spacer()
                Text("One-time purchase. No subscription.").font(.footnote).foregroundStyle(.secondary)
            }.padding(24).toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}

struct KOThumbnail: View {
    let item: KOContender
    var body: some View {
        Group {
            if let data = item.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage).resizable().scaledToFill()
            } else {
                ZStack { Color.secondary.opacity(0.12); Image(systemName: "photo").font(.largeTitle).foregroundStyle(.secondary) }
            }
        }.clipShape(RoundedRectangle(cornerRadius: 16)).clipped().accessibilityHidden(true)
    }
}
