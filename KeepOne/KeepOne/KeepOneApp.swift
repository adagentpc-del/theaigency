import SwiftUI
import PhotosUI
import StoreKit

struct KOContender: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var imageData: Data?
    var wins = 0
    var losses = 0
    var score: Int { wins - losses }
    var winRate: Double { wins + losses == 0 ? 0 : Double(wins) / Double(wins + losses) }
}

struct KOBattle: Identifiable, Codable {
    var id = UUID()
    var category: String
    var createdAt = Date()
    var contenders: [KOContender]
    var pairings: [[UUID]] = []
    var currentPairIndex = 0
    var completed = false
}

enum KOPairingEngine {
    static func makePairs(for contenders: [KOContender]) -> [[UUID]] {
        guard contenders.count > 1 else { return [] }
        var pairs: [[UUID]] = []
        let maxPairs = min(contenders.count * 3, contenders.count * (contenders.count - 1) / 2)
        outer: for offset in 1..<contenders.count {
            for i in contenders.indices {
                let j = (i + offset) % contenders.count
                guard i < j else { continue }
                pairs.append([contenders[i].id, contenders[j].id])
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
    private let key = "keepone.store.v2"
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
        if let wi = battle.contenders.firstIndex(where: { $0.id == winnerID }) { battle.contenders[wi].wins += 1 }
        if let li = battle.contenders.firstIndex(where: { $0.id == loserID }) { battle.contenders[li].losses += 1 }
        battle.currentPairIndex += 1
        if battle.currentPairIndex >= battle.pairings.count {
            battle.completed = true
            history.insert(battle, at: 0)
        }
        current = battle
        save()
    }

    func undo() {
        guard var battle = current, battle.currentPairIndex > 0 else { return }
        if battle.completed { history.removeAll { $0.id == battle.id }; battle.completed = false }
        battle.currentPairIndex -= 1
        let pair = battle.pairings[battle.currentPairIndex]
        for id in pair {
            if let i = battle.contenders.firstIndex(where: { $0.id == id }) {
                if battle.contenders[i].wins > 0 { battle.contenders[i].wins -= 1 }
                else if battle.contenders[i].losses > 0 { battle.contenders[i].losses -= 1 }
            }
        }
        current = battle
        save()
    }

    func clearCurrent() { current = nil; save() }

    private func save() {
        if let data = try? JSONEncoder().encode(Snapshot(current: current, history: history)) { UserDefaults.standard.set(data, forKey: key) }
    }
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key), let snap = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        current = snap.current; history = snap.history
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
                let transaction = try checkVerified(verification)
                await transaction.finish()
                unlocked = true
            }
        } catch { errorMessage = error.localizedDescription }
    }

    func restore() async { try? await AppStore.sync(); unlocked = await hasEntitlement() }

    private func hasEntitlement() async -> Bool {
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result, t.productID == Self.productID, t.revocationDate == nil { return true }
        }
        return false
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result { case .verified(let value): return value; case .unverified: throw StoreError.failedVerification }
    }
    enum StoreError: Error { case failedVerification }
}

@main
struct KeepOneApp: App {
    @StateObject private var store = KOStore()
    @StateObject private var purchase = KOPurchaseManager()
    var body: some Scene { WindowGroup { KORootView().environmentObject(store).environmentObject(purchase) } }
}

struct KORootView: View {
    @EnvironmentObject var store: KOStore
    @EnvironmentObject var purchase: KOPurchaseManager
    @AppStorage("keepone.onboarded") private var onboarded = false
    @State private var showingNew = false
    @State private var showingPaywall = false

    var body: some View {
        NavigationStack {
            Group {
                if !onboarded { KOOnboarding { onboarded = true } }
                else if let battle = store.current { battle.completed ? KOResultsView(battle: battle) : KOBattleView(battle: battle) }
                else { KOHomeView(showingNew: $showingNew) }
            }
            .sheet(isPresented: $showingNew) { KONewBattleView() }
            .sheet(isPresented: $showingPaywall) { KOPaywallView() }
            .toolbar {
                if onboarded { ToolbarItem(placement: .topBarTrailing) { Button { showingPaywall = true } label: { Image(systemName: purchase.unlocked ? "checkmark.seal.fill" : "lock.open") }.accessibilityLabel("Premium") } }
            }
        }
    }
}

struct KOOnboarding: View {
    var finish: () -> Void
    var body: some View {
        TabView {
            page("Too much stuff?", "Stop asking whether every item is good enough to keep.", "shippingbox")
            page("Make it compete", "Head-to-head choices reveal your real favorites with less decision fatigue.", "arrow.left.arrow.right")
            VStack(spacing: 22) {
                Image(systemName: "trophy.fill").font(.system(size: 62)).foregroundStyle(.tint)
                Text("Keep the winners").font(.largeTitle.bold())
                Text("Photos and decisions stay on your device. No account required.").multilineTextAlignment(.center).foregroundStyle(.secondary)
                Button("START A BATTLE", action: finish).buttonStyle(.borderedProminent).controlSize(.large)
            }.padding(28)
        }.tabViewStyle(.page(indexDisplayMode: .always))
    }
    private func page(_ title: String, _ body: String, _ symbol: String) -> some View {
        VStack(spacing: 22) { Image(systemName: symbol).font(.system(size: 58)); Text(title).font(.largeTitle.bold()); Text(body).font(.title3).multilineTextAlignment(.center).foregroundStyle(.secondary) }.padding(28)
    }
}

struct KOHomeView: View {
    @EnvironmentObject var store: KOStore
    @Binding var showingNew: Bool
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) { Text("KEEP ONE").font(.caption.bold()).foregroundStyle(.secondary); Text("Make your stuff compete.\nKeep the winners.").font(.largeTitle.bold()) }
                Button { showingNew = true } label: { Label("START A BATTLE", systemImage: "bolt.fill").frame(maxWidth: .infinity) }.buttonStyle(.borderedProminent).controlSize(.large)
                if !store.history.isEmpty {
                    Text("RECENT BATTLES").font(.caption.bold()).foregroundStyle(.secondary)
                    ForEach(store.history.prefix(5)) { battle in
                        let ranked = KOPairingEngine.ranked(battle.contenders)
                        HStack { VStack(alignment: .leading) { Text(battle.category).font(.headline); Text("\(battle.contenders.count) contenders").font(.caption).foregroundStyle(.secondary) }; Spacer(); if let champion = ranked.first { Text(champion.name).font(.subheadline.bold()) } }.padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
                    }
                }
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
    var maxItems: Int { purchase.unlocked ? 64 : 8 }

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                TextField("What are we decluttering?", text: $category).textFieldStyle(.roundedBorder)
                HStack {
                    TextField("Item name", text: $draft).textFieldStyle(.roundedBorder)
                    PhotosPicker(selection: $photo, matching: .images) { Image(systemName: "photo.badge.plus").font(.title2).frame(width: 44, height: 44) }
                        .onChange(of: photo) { _, item in
                            Task {
                                guard contenders.count < maxItems else { showLimit = true; return }
                                let data = try? await item?.loadTransferable(type: Data.self)
                                contenders.append(KOContender(name: draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Item \(contenders.count + 1)" : draft, imageData: data))
                                draft = ""; photo = nil
                            }
                        }
                }
                HStack { Text("\(contenders.count) / \(maxItems) contenders").font(.caption).foregroundStyle(.secondary); Spacer() }
                List { ForEach(contenders) { item in HStack { KOThumbnail(item: item).frame(width: 52, height: 52); Text(item.name) } }.onDelete { contenders.remove(atOffsets: $0) } }.listStyle(.plain)
                Button("LET THEM FIGHT") { store.start(category: category, contenders: contenders); dismiss() }.buttonStyle(.borderedProminent).controlSize(.large).disabled(contenders.count < 2)
            }.padding().navigationTitle("New Battle").toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }.alert("Free limit reached", isPresented: $showLimit) { Button("OK") {} } message: { Text("Free battles support up to 8 contenders. Lifetime unlock supports up to 64.") }
        }
    }
}

struct KOBattleView: View {
    @EnvironmentObject var store: KOStore
    let battle: KOBattle
    var pair: [KOContender] {
        guard battle.currentPairIndex < battle.pairings.count else { return [] }
        let ids = battle.pairings[battle.currentPairIndex]
        return ids.compactMap { id in battle.contenders.first { $0.id == id } }
    }
    var body: some View {
        VStack(spacing: 18) {
            Text(battle.category.uppercased()).font(.caption.bold()).foregroundStyle(.secondary)
            Text("KEEP ONE").font(.largeTitle.bold())
            Text("If you could only keep one, which wins?").foregroundStyle(.secondary).multilineTextAlignment(.center)
            ProgressView(value: Double(battle.currentPairIndex), total: Double(max(1, battle.pairings.count))).accessibilityLabel("Battle progress")
            HStack(spacing: 12) { ForEach(pair) { item in Button { store.choose(item.id) } label: { VStack { KOThumbnail(item: item).frame(height: 230); Text(item.name).font(.headline).multilineTextAlignment(.center) }.frame(maxWidth: .infinity).padding(10).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20)) }.buttonStyle(.plain).accessibilityLabel("Keep \(item.name)") } }
            Button("Undo last choice") { store.undo() }.disabled(battle.currentPairIndex == 0)
        }.padding(20).navigationBarBackButtonHidden()
    }
}

struct KOResultsView: View {
    @EnvironmentObject var store: KOStore
    let battle: KOBattle
    var ranked: [KOContender] { KOPairingEngine.ranked(battle.contenders) }
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("THE RESULTS ARE IN").font(.caption.bold()).foregroundStyle(.secondary)
                if let champion = ranked.first {
                    KOThumbnail(item: champion).frame(width: 190, height: 190)
                    Text("THE CHAMPION").font(.caption.bold()).foregroundStyle(.secondary)
                    Text(champion.name).font(.largeTitle.bold())
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text("YOUR KEEPERS").font(.headline)
                    ForEach(Array(ranked.prefix(max(1, ranked.count / 3)).enumerated()), id: \.element.id) { index, item in HStack { Text("#\(index + 1)").foregroundStyle(.secondary); Text(item.name); Spacer(); Text("\(Int(item.winRate * 100))%") } }
                }.frame(maxWidth: .infinity, alignment: .leading).padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
                VStack(alignment: .leading, spacing: 12) { Text("THE CUT LIST").font(.headline); Text("These consistently lost when you had to choose.").font(.subheadline).foregroundStyle(.secondary); ForEach(ranked.suffix(max(1, ranked.count / 3))) { Text(itemLabel($0)) } }.frame(maxWidth: .infinity, alignment: .leading).padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
                ShareLink(item: "My \(battle.category) battle: \(battle.contenders.count) contenders. Champion: \(ranked.first?.name ?? "")") { Label("Share Results", systemImage: "square.and.arrow.up") }.buttonStyle(.bordered)
                Button("DONE") { store.clearCurrent() }.buttonStyle(.borderedProminent).controlSize(.large)
            }.padding(22)
        }.navigationTitle("Results").navigationBarBackButtonHidden()
    }
    private func itemLabel(_ item: KOContender) -> String { "\(item.name) · \(item.wins) wins / \(item.losses) losses" }
}

struct KOPaywallView: View {
    @EnvironmentObject var purchase: KOPurchaseManager
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "trophy.fill").font(.system(size: 56)).foregroundStyle(.tint)
                Text("Keep One Unlocked").font(.largeTitle.bold())
                Text("Unlimited battles, up to 64 contenders, saved history, advanced results and future premium features.").multilineTextAlignment(.center).foregroundStyle(.secondary)
                Button(purchase.product.map { "Unlock for \($0.displayPrice)" } ?? "Lifetime unlock") { Task { await purchase.purchase() } }.buttonStyle(.borderedProminent).controlSize(.large).disabled(purchase.unlocked)
                Button("Restore Purchases") { Task { await purchase.restore() } }.buttonStyle(.bordered)
                if purchase.unlocked { Label("Unlocked", systemImage: "checkmark.seal.fill").foregroundStyle(.green) }
                if let error = purchase.errorMessage { Text(error).font(.footnote).foregroundStyle(.secondary) }
                Spacer()
                Text("One-time purchase. No subscription.").font(.footnote).foregroundStyle(.secondary)
            }.padding(24).toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}

struct KOThumbnail: View {
    let item: KOContender
    var body: some View {
        Group { if let data = item.imageData, let ui = UIImage(data: data) { Image(uiImage: ui).resizable().scaledToFill() } else { ZStack { Color.secondary.opacity(0.12); Image(systemName: "photo").font(.largeTitle).foregroundStyle(.secondary) } } }.clipShape(RoundedRectangle(cornerRadius: 16)).clipped().accessibilityHidden(true)
    }
}
