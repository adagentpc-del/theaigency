import SwiftUI

struct LoopItem: Identifiable, Codable {
    let id: UUID
    var text: String
    var status: String
    var createdAt: Date
    var scheduledFor: Date?
}

@MainActor
final class LoopStore: ObservableObject {
    @Published var active: [LoopItem] = [] { didSet { save() } }
    @Published var closed: [LoopItem] = [] { didSet { save() } }
    private let key = "killtheloop.v1"
    init() { load() }
    func add(_ text: String) { active.append(LoopItem(id: UUID(), text: text, status: "open", createdAt: .now, scheduledFor: nil)) }
    func resolveCurrent(status: String, scheduledFor: Date? = nil) {
        guard !active.isEmpty else { return }
        var item = active.removeFirst()
        item.status = status
        item.scheduledFor = scheduledFor
        closed.insert(item, at: 0)
    }
    private struct Snapshot: Codable { var active:[LoopItem]; var closed:[LoopItem] }
    private func save() { if let data = try? JSONEncoder().encode(Snapshot(active: active, closed: closed)) { UserDefaults.standard.set(data, forKey: key) } }
    private func load() { if let data = UserDefaults.standard.data(forKey: key), let s = try? JSONDecoder().decode(Snapshot.self, from: data) { active = s.active; closed = s.closed } }
}

@main
struct KillTheLoopApp: App {
    @StateObject private var store = LoopStore()
    var body: some Scene { WindowGroup { KillTheLoopRootView().environmentObject(store) } }
}

struct KillTheLoopRootView: View {
    @EnvironmentObject var store: LoopStore
    @State private var draft = ""
    @State private var capturing = false
    @State private var showingSchedule = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if store.active.isEmpty { zeroState } else { loopMode }
            }.padding().navigationTitle("Kill The Loop")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { capturing = true } label: { Image(systemName: "plus") } } }
            .sheet(isPresented: $capturing) { captureSheet }
            .sheet(isPresented: $showingSchedule) { scheduleSheet }
        }
    }

    private var loopMode: some View {
        VStack(spacing: 24) {
            Text("ONE LOOP. ONE DECISION.").font(.caption.bold()).foregroundStyle(.secondary)
            Text(store.active[0].text).font(.largeTitle.bold()).multilineTextAlignment(.center).frame(maxHeight: .infinity)
            Text("\(store.active.count) loops remaining").font(.caption).foregroundStyle(.secondary)
            Button("DO IT") { store.resolveCurrent(status: "done") }.buttonStyle(.borderedProminent)
            Button("SCHEDULE IT") { showingSchedule = true }.buttonStyle(.bordered)
            Button("KILL IT", role: .destructive) { store.resolveCurrent(status: "killed") }.buttonStyle(.bordered)
        }
    }

    private var zeroState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.circle.fill").font(.system(size: 64)).foregroundStyle(.green)
            Text("ZERO OPEN LOOPS").font(.largeTitle.bold())
            Text("Nothing in this app is waiting for you.").foregroundStyle(.secondary)
            Button("EMPTY MY HEAD") { capturing = true }.buttonStyle(.borderedProminent)
            Spacer()
            Text("Closed: \(store.closed.count)").font(.caption).foregroundStyle(.secondary)
        }
    }

    private var captureSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("WHAT'S TAKING UP SPACE IN YOUR HEAD?").font(.title2.bold()).multilineTextAlignment(.center)
                TextField("Return package, call dentist…", text: $draft).textFieldStyle(.roundedBorder).submitLabel(.done).onSubmit { addDraft() }
                Button("ADD LOOP") { addDraft() }.buttonStyle(.borderedProminent).disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Spacer()
            }.padding().toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { capturing = false } } }
        }
    }

    private var scheduleSheet: some View {
        NavigationStack {
            List {
                Button("Later today") { schedule(hours: 3) }
                Button("Tomorrow") { schedule(hours: 24) }
                Button("This weekend") { schedule(hours: 72) }
            }.navigationTitle("Schedule It")
        }
    }

    private func addDraft() {
        let t = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        store.add(t); draft = ""
    }
    private func schedule(hours: Int) { store.resolveCurrent(status: "scheduled", scheduledFor: Calendar.current.date(byAdding: .hour, value: hours, to: .now)); showingSchedule = false }
}
