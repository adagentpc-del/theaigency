import SwiftUI
import StoreKit
import UserNotifications

struct KLItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var text: String
    var status = "open"
    var createdAt = Date()
    var resolvedAt: Date?
    var scheduledFor: Date?
}

@MainActor
final class KLStore: ObservableObject {
    @Published var active: [KLItem] = [] { didSet { save() } }
    @Published var closed: [KLItem] = [] { didSet { save() } }
    private let key = "killtheloop.store.v3"
    private struct Snapshot: Codable { let active: [KLItem]; let closed: [KLItem] }

    init() { load(); returnScheduledDue() }

    func add(_ text: String) {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        active.append(KLItem(text: clean))
    }

    @discardableResult
    func resolveCurrent(status: String, scheduledFor: Date? = nil) -> KLItem? {
        guard !active.isEmpty else { return nil }
        var item = active.removeFirst()
        item.status = status
        item.resolvedAt = .now
        item.scheduledFor = scheduledFor
        closed.insert(item, at: 0)
        return item
    }

    func returnScheduledDue(now: Date = .now) {
        let due = closed.filter { $0.status == "scheduled" && ($0.scheduledFor ?? .distantFuture) <= now }
        guard !due.isEmpty else { return }
        let dueIDs = Set(due.map(\.id))
        closed.removeAll { dueIDs.contains($0.id) }
        let reopened = due.map { item -> KLItem in
            var copy = item
            copy.status = "open"
            copy.resolvedAt = nil
            return copy
        }
        active.insert(contentsOf: reopened, at: 0)
    }

    var closedToday: Int {
        closed.filter { Calendar.current.isDateInToday($0.resolvedAt ?? .distantPast) }.count
    }

    private func save() {
        if let data = try? JSONEncoder().encode(Snapshot(active: active, closed: closed)) { UserDefaults.standard.set(data, forKey: key) }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key), let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        active = snapshot.active
        closed = snapshot.closed
    }
}

@MainActor
final class KLNotifications: ObservableObject {
    @Published var authorized = false

    init() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            authorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
        }
    }

    func request() async {
        do { authorized = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) }
        catch { authorized = false }
    }

    func schedule(item: KLItem, date: Date) async {
        if !authorized { await request() }
        guard authorized else { return }
        let content = UNMutableNotificationContent()
        content.title = "One loop is ready to close"
        content.body = "Open Kill The Loop when you're ready."
        content.sound = .default
        let interval = max(60, date.timeIntervalSinceNow)
        let request = UNNotificationRequest(identifier: "loop-\(item.id.uuidString)", content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false))
        try? await UNUserNotificationCenter.current().add(request)
    }
}

@MainActor
final class KLPurchaseManager: ObservableObject {
    static let productID = "com.theaigency.killtheloop.lifetime"
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
struct KillTheLoopApp: App {
    @StateObject private var store = KLStore()
    @StateObject private var purchase = KLPurchaseManager()
    @StateObject private var notifications = KLNotifications()

    var body: some Scene {
        WindowGroup { KLRootView().environmentObject(store).environmentObject(purchase).environmentObject(notifications) }
    }
}

struct KLRootView: View {
    @EnvironmentObject var store: KLStore
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("killtheloop.onboarded") private var onboarded = false
    @State private var capture = false
    @State private var history = false
    @State private var settings = false

    var body: some View {
        NavigationStack {
            Group {
                if !onboarded {
                    KLOnboarding { onboarded = true; capture = true }
                } else if store.active.isEmpty {
                    KLZeroView(capture: $capture)
                } else {
                    KLLoopView()
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if onboarded {
                        Button { history = true } label: { Image(systemName: "clock.arrow.circlepath") }.accessibilityLabel("History")
                        Button { capture = true } label: { Image(systemName: "plus") }.accessibilityLabel("Add loop")
                        Button { settings = true } label: { Image(systemName: "gearshape") }.accessibilityLabel("Settings")
                    }
                }
            }
            .sheet(isPresented: $capture) { KLCaptureView() }
            .sheet(isPresented: $history) { KLHistoryView() }
            .sheet(isPresented: $settings) { KLSettingsView() }
        }
        .onChange(of: scenePhase) { _, newPhase in if newPhase == .active { store.returnScheduledDue() } }
    }
}

struct KLOnboarding: View {
    let finish: () -> Void
    var body: some View {
        TabView {
            KLOnboardPage(symbol: "rectangle.stack", title: "Too many tabs open?", copy: "Unanswered text. Return. Appointment. Form. They all take up mental space.")
            KLOnboardPage(symbol: "1.circle", title: "See one thing", copy: "No giant default list. Resolve one open loop before seeing the next.")
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 62)).foregroundStyle(.tint)
                Text("Do it. Schedule it. Kill it.").font(.largeTitle.bold()).multilineTextAlignment(.center)
                Text("Completion isn't the only valid resolution. You can deliberately let something go.").font(.title3).multilineTextAlignment(.center).foregroundStyle(.secondary)
                Button("EMPTY MY HEAD", action: finish).buttonStyle(.borderedProminent).controlSize(.large)
            }.padding(28)
        }.tabViewStyle(.page(indexDisplayMode: .always))
    }
}

struct KLOnboardPage: View {
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

struct KLZeroView: View {
    @EnvironmentObject var store: KLStore
    @Binding var capture: Bool
    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "checkmark.circle.fill").font(.system(size: 72)).foregroundStyle(.green)
            Text("ZERO OPEN LOOPS").font(.largeTitle.bold()).multilineTextAlignment(.center)
            Text("Nothing in this app is waiting for you.").foregroundStyle(.secondary)
            Text("\(store.closedToday) closed today").font(.caption.bold()).foregroundStyle(.secondary)
            Button("EMPTY MY HEAD") { capture = true }.buttonStyle(.borderedProminent).controlSize(.large)
            Spacer()
        }.padding(24).navigationTitle("Kill The Loop")
    }
}

struct KLLoopView: View {
    @EnvironmentObject var store: KLStore
    @State private var doing = false
    @State private var scheduling = false
    @State private var confirmingKill = false

    private var current: KLItem? { store.active.first }

    var body: some View {
        VStack(spacing: 22) {
            Text("ONE LOOP. ONE DECISION.").font(.caption.bold()).foregroundStyle(.secondary)
            Spacer()
            if let current {
                Text(current.text).font(.system(.largeTitle, design: .rounded, weight: .bold)).multilineTextAlignment(.center).minimumScaleFactor(0.7)
            }
            Spacer()
            Text("\(store.active.count) open \(store.active.count == 1 ? "loop" : "loops")").font(.caption).foregroundStyle(.secondary)
            Button("DO IT") { doing = true }.buttonStyle(.borderedProminent).controlSize(.large)
            Button("SCHEDULE IT") { scheduling = true }.buttonStyle(.bordered).controlSize(.large)
            Button("KILL IT", role: .destructive) { confirmingKill = true }.buttonStyle(.bordered).controlSize(.large)
        }
        .padding(24)
        .navigationTitle("Kill The Loop")
        .navigationBarBackButtonHidden()
        .confirmationDialog("Choose to let this go?", isPresented: $confirmingKill, titleVisibility: .visible) {
            Button("Kill the loop", role: .destructive) { store.resolveCurrent(status: "killed") }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This records a deliberate decision not to do it. You can still see it in History.") }
        .sheet(isPresented: $doing) { if let current { KLDoItView(item: current) } }
        .sheet(isPresented: $scheduling) { if let current { KLScheduleView(item: current) } }
    }
}

struct KLDoItView: View {
    @EnvironmentObject var store: KLStore
    @Environment(\.dismiss) var dismiss
    let item: KLItem
    @State private var started = false
    @State private var endDate: Date?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(item.text).font(.title.bold()).multilineTextAlignment(.center)
                if !started {
                    Text("How much runway do you want?").font(.headline)
                    Text("The timer is optional. It exists to create a starting boundary, not a deadline.").font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    HStack(spacing: 10) {
                        timerButton("5 MIN", minutes: 5)
                        timerButton("10 MIN", minutes: 10)
                        timerButton("15 MIN", minutes: 15)
                    }
                    Button("NO TIMER") { started = true; endDate = nil }.buttonStyle(.bordered)
                } else {
                    Spacer()
                    Text("GO CLOSE IT.").font(.largeTitle.bold()).multilineTextAlignment(.center)
                    if let endDate {
                        TimelineView(.periodic(from: .now, by: 1)) { context in
                            let remaining = max(0, Int(endDate.timeIntervalSince(context.date)))
                            VStack(spacing: 8) {
                                Text(timeString(remaining)).font(.system(size: 48, weight: .semibold, design: .monospaced)).contentTransition(.numericText())
                                Text(remaining > 0 ? "Use the boundary. You can finish early." : "Time's up. Decide what happened.").font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                            }
                        }
                    } else {
                        Text("No countdown. Just the next move.").foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("DONE") {
                        if store.active.first?.id == item.id { store.resolveCurrent(status: "done") }
                        dismiss()
                    }.buttonStyle(.borderedProminent).controlSize(.large)
                    Button("NOT DONE — PUT IT BACK") { dismiss() }.buttonStyle(.bordered)
                }
                Spacer()
            }
            .padding(24)
            .navigationTitle("Do It")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }

    private func timerButton(_ title: String, minutes: Int) -> some View {
        Button(title) {
            endDate = Date().addingTimeInterval(Double(minutes * 60))
            started = true
        }.buttonStyle(.borderedProminent)
    }

    private func timeString(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

struct KLCaptureView: View {
    @EnvironmentObject var store: KLStore
    @EnvironmentObject var purchase: KLPurchaseManager
    @Environment(\.dismiss) var dismiss
    @State private var draft = ""
    @State private var added = 0

    private var atLimit: Bool { !purchase.unlocked && store.active.count >= 10 }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("WHAT'S TAKING UP SPACE IN YOUR HEAD?").font(.title2.bold())
                Text("Capture fast. No priorities, projects, tags or due dates required.").foregroundStyle(.secondary)
                TextField("Return package, call dentist…", text: $draft, axis: .vertical).textFieldStyle(.roundedBorder).submitLabel(.done).onSubmit(add)
                Button("ADD LOOP", action: add).buttonStyle(.borderedProminent).disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || atLimit)
                if atLimit { Text("Free supports 10 active loops. Lifetime unlock removes the limit.").font(.footnote).foregroundStyle(.secondary) }
                if added > 0 { Label("\(added) captured", systemImage: "checkmark").font(.caption).foregroundStyle(.secondary) }
                Spacer()
            }
            .padding(22)
            .navigationTitle("Brain Dump")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    private func add() {
        guard !atLimit else { return }
        let clean = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        store.add(clean)
        added += 1
        draft = ""
    }
}

struct KLScheduleView: View {
    @EnvironmentObject var store: KLStore
    @EnvironmentObject var notifications: KLNotifications
    @Environment(\.dismiss) var dismiss
    let item: KLItem
    @State private var customDate = Date().addingTimeInterval(3600)

    var body: some View {
        NavigationStack {
            Form {
                Section("Quick") {
                    Button("Later today") { schedule(Date().addingTimeInterval(3 * 3600)) }
                    Button("Tomorrow") { schedule(Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now) }
                    Button("This weekend") { schedule(nextWeekendMorning()) }
                }
                Section("Choose a time") {
                    DatePicker("When", selection: $customDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                    Button("Schedule") { schedule(customDate) }
                }
            }
            .navigationTitle("Schedule It")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }

    private func schedule(_ date: Date) {
        if let scheduled = store.resolveCurrent(status: "scheduled", scheduledFor: date) {
            Task { await notifications.schedule(item: scheduled, date: date) }
        }
        dismiss()
    }

    private func nextWeekendMorning() -> Date {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: .now)
        if weekday == 7 {
            return calendar.nextDate(after: .now, matching: DateComponents(hour: 10, weekday: 1), matchingPolicy: .nextTime) ?? Date().addingTimeInterval(24 * 3600)
        }
        if weekday == 1 {
            let todayTen = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: .now) ?? .now
            if todayTen > .now { return todayTen }
        }
        return calendar.nextDate(after: .now, matching: DateComponents(hour: 10, weekday: 7), matchingPolicy: .nextTime) ?? Date().addingTimeInterval(72 * 3600)
    }
}

struct KLHistoryView: View {
    @EnvironmentObject var store: KLStore
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.closed) { item in
                    HStack(spacing: 12) {
                        Image(systemName: icon(item.status)).foregroundStyle(item.status == "killed" ? Color.red : Color.accentColor)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.text)
                            Text(item.status.capitalized).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
            }
            .navigationTitle("Closed")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    private func icon(_ status: String) -> String {
        status == "done" ? "checkmark.circle.fill" : status == "scheduled" ? "calendar.badge.clock" : "xmark.circle.fill"
    }
}

struct KLSettingsView: View {
    @EnvironmentObject var purchase: KLPurchaseManager
    @EnvironmentObject var notifications: KLNotifications
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Lifetime Unlock") {
                    Button(purchase.product.map { "Unlock — \($0.displayPrice)" } ?? "Lifetime unlock") { Task { await purchase.purchase() } }.disabled(purchase.unlocked)
                    Button("Restore Purchases") { Task { await purchase.restore() } }
                    if purchase.unlocked { Label("Unlocked", systemImage: "checkmark.seal.fill").foregroundStyle(.green) }
                    if let error = purchase.errorMessage { Text(error).font(.footnote).foregroundStyle(.secondary) }
                }
                Section("Notifications") {
                    Button(notifications.authorized ? "Notifications enabled" : "Enable notifications") { Task { await notifications.request() } }.disabled(notifications.authorized)
                    Text("Notification previews intentionally do not include the text of your open loop.").font(.footnote).foregroundStyle(.secondary)
                }
                Section("Privacy") { Text("Your loops are stored locally. No account or backend is required.").font(.footnote).foregroundStyle(.secondary) }
            }
            .navigationTitle("Settings")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
