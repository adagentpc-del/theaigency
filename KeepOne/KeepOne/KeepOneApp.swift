import SwiftUI
import PhotosUI

struct Contender: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var imageData: Data?
    var wins = 0
    var losses = 0
}

@main
struct KeepOneApp: App {
    var body: some Scene { WindowGroup { KeepOneRootView() } }
}

struct KeepOneRootView: View {
    @State private var contenders: [Contender] = []
    @State private var category = "Closet"
    @State private var started = false
    @State private var pairIndex = 0
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var draftName = ""

    var currentPair: (Int, Int)? {
        guard contenders.count >= 2 else { return nil }
        let a = pairIndex % contenders.count
        let b = (a + 1) % contenders.count
        return a == b ? nil : (a, b)
    }

    var body: some View {
        NavigationStack {
            Group {
                if started { battleView } else { setupView }
            }
            .navigationTitle("Keep One")
            .padding()
        }
    }

    private var setupView: some View {
        VStack(spacing: 18) {
            Text("Make your stuff compete. Keep the winners.").font(.title2.bold()).multilineTextAlignment(.center)
            TextField("What are we decluttering?", text: $category).textFieldStyle(.roundedBorder)
            HStack {
                TextField("Item name", text: $draftName).textFieldStyle(.roundedBorder)
                PhotosPicker(selection: $selectedPhoto, matching: .images) { Image(systemName: "photo.badge.plus").font(.title2) }
                    .onChange(of: selectedPhoto) { _, newValue in
                        Task {
                            let data = try? await newValue?.loadTransferable(type: Data.self)
                            contenders.append(Contender(name: draftName.isEmpty ? "Item \(contenders.count + 1)" : draftName, imageData: data))
                            draftName = ""
                            selectedPhoto = nil
                        }
                    }
            }
            List { ForEach(contenders) { item in HStack { thumbnail(item); Text(item.name) } }.onDelete { contenders.remove(atOffsets: $0) } }
            Button("LET THEM FIGHT") { started = contenders.count >= 2 }.buttonStyle(.borderedProminent).disabled(contenders.count < 2)
        }
    }

    private var battleView: some View {
        VStack(spacing: 20) {
            Text(category.uppercased()).font(.caption.bold()).foregroundStyle(.secondary)
            Text("KEEP ONE").font(.largeTitle.bold())
            Text("If you could only keep one, which wins?").foregroundStyle(.secondary)
            if let (a,b) = currentPair {
                HStack(spacing: 14) {
                    choiceCard(index: a)
                    choiceCard(index: b)
                }
                Text("Match \(pairIndex + 1)").font(.caption).foregroundStyle(.secondary)
            }
            Button("Finish & Rank") { started = false; pairIndex = 0; contenders.sort { $0.wins > $1.wins } }.buttonStyle(.bordered)
        }
    }

    private func choiceCard(index: Int) -> some View {
        Button {
            let other = currentPair!.0 == index ? currentPair!.1 : currentPair!.0
            contenders[index].wins += 1
            contenders[other].losses += 1
            pairIndex += 1
        } label: {
            VStack(spacing: 10) {
                thumbnail(contenders[index]).frame(height: 180)
                Text(contenders[index].name).font(.headline)
                Text("\(contenders[index].wins) wins").font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity).padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
        }.buttonStyle(.plain)
    }

    private func thumbnail(_ item: Contender) -> some View {
        Group {
            if let data = item.imageData, let image = UIImage(data: data) { Image(uiImage: image).resizable().scaledToFill().clipShape(RoundedRectangle(cornerRadius: 14)) }
            else { Image(systemName: "photo").resizable().scaledToFit().padding().foregroundStyle(.secondary) }
        }
    }
}
