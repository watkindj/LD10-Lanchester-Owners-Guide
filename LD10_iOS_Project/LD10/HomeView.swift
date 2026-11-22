import SwiftUI
import WebKit
import ZIPFoundation

final class WebsiteStore: ObservableObject {
    @Published var isReady = false
    @Published var errorMessage: String?
    let rootURL: URL

    init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        rootURL = support.appendingPathComponent("LD10 Website (working) 21-12-2022", isDirectory: true)
        prepare()
    }

    private func prepare() {
        if FileManager.default.fileExists(atPath: rootURL.appendingPathComponent("index.htm").path) {
            isReady = true
            return
        }
        guard let archive = Bundle.main.url(forResource: "LD10-Website-Backup", withExtension: "zip", subdirectory: "Resources") else {
            errorMessage = "The original LD10 website archive is missing from the app."
            return
        }
        do {
            try FileManager.default.createDirectory(at: rootURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try FileManager.default.unzipItem(at: archive, to: rootURL.deletingLastPathComponent())
            isReady = FileManager.default.fileExists(atPath: rootURL.appendingPathComponent("index.htm").path)
            if !isReady { errorMessage = "The website was unpacked, but its home page could not be found." }
        } catch {
            errorMessage = "Could not unpack the offline website: \(error.localizedDescription)"
        }
    }

    func page(_ relative: String) -> URL {
        rootURL.appendingPathComponent(relative)
    }
}

struct GuideSection: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let symbol: String
    let file: String
}

struct HomeView: View {
    @StateObject private var store = WebsiteStore()
    @State private var selected: GuideSection?
    @State private var showOriginalHome = false

    private let sections = [
        GuideSection(id: "maintenance", title: "Maintenance", subtitle: "Workshop information and guidance", symbol: "wrench.and.screwdriver", file: "index_5.htm"),
        GuideSection(id: "controls", title: "Technical information", subtitle: "Systems, components and details", symbol: "gearshape.2", file: "index_6.htm"),
        GuideSection(id: "trim", title: "Body & trim", subtitle: "Interior and exterior trim", symbol: "car.side", file: "trim/ntrim.htm"),
        GuideSection(id: "spares", title: "Spares", subtitle: "Parts and spares information", symbol: "shippingbox", file: "docs/spares.htm"),
        GuideSection(id: "cars", title: "Owners' cars", subtitle: "Cars and owner information", symbol: "car.2", file: "docs/cars.htm"),
        GuideSection(id: "photos", title: "Photographs", subtitle: "Original photo collection", symbol: "photo.on.rectangle.angled", file: "photos/photos.htm"),
        GuideSection(id: "contact", title: "Contact", subtitle: "Original site contact details", symbol: "envelope", file: "docs/contact.htm")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.95, green: 0.94, blue: 0.90).ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        if let error = store.errorMessage {
                            Text(error).foregroundStyle(.red).padding()
                        } else if !store.isReady {
                            ProgressView("Preparing the offline guide…")
                                .frame(maxWidth: .infinity).padding(.vertical, 30)
                        } else {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(sections) { section in
                                    Button { selected = section } label: {
                                        VStack(alignment: .leading, spacing: 10) {
                                            Image(systemName: section.symbol)
                                                .font(.system(size: 25, weight: .medium))
                                                .foregroundStyle(Color(red: 0.78, green: 0.63, blue: 0.34))
                                            Text(section.title)
                                                .font(.headline).foregroundStyle(Color(red: 0.15, green: 0.22, blue: 0.16))
                                            Text(section.subtitle)
                                                .font(.caption).foregroundStyle(.secondary)
                                                .multilineTextAlignment(.leading)
                                            Spacer(minLength: 0)
                                        }
                                        .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
                                        .padding(15)
                                        .background(.white, in: RoundedRectangle(cornerRadius: 17))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            Button { showOriginalHome = true } label: {
                                Label("Open complete original website", systemImage: "globe")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity).padding()
                                    .background(Color(red: 0.15, green: 0.22, blue: 0.16), in: RoundedRectangle(cornerRadius: 14))
                                    .foregroundStyle(.white)
                            }
                            Text("The original website pages, photographs and PDF documents are stored in this app for offline browsing.")
                                .font(.footnote).foregroundStyle(.secondary)
                                .padding(.horizontal, 3)
                        }
                    }
                    .padding(18)
                }
            }
                        .navigationBarHidden(true)
            .sheet(item: $selected) { section in
                NavigationStack {
                    WebsitePage(url: store.page(section.file), title: section.title)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("LD10")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .tracking(2)

                Spacer()

                Text("OWNER'S GUIDE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.5)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color(red: 0.88, green: 0.84, blue: 0.73), in: Capsule())
            }

            Text("Lanchester LD10")
                .font(.system(size: 34, weight: .bold, design: .serif))
                .foregroundStyle(Color(red: 0.15, green: 0.22, blue: 0.16))

            Text("Barker & Briggs · Maintenance and information")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Group {
                if let path = Bundle.main.path(forResource: "LD10Hero", ofType: "png", inDirectory: "Resources"),
                   let uiImage = UIImage(contentsOfFile: path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                } else {
                    Color(red: 0.15, green: 0.22, blue: 0.16)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 145)
            .background(Color(red: 0.15, green: 0.22, blue: 0.16), in: RoundedRectangle(cornerRadius: 18))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(alignment: .bottomLeading) {
                Text("THE LANCHESTER LD10")
                    .font(.caption.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(.white)
                    .padding(12)
            }

            if let path = Bundle.main.path(forResource: "LD10CarDetail", ofType: "jpeg", inDirectory: "Resources"),
               let detailImage = UIImage(contentsOfFile: path) {
                Image(uiImage: detailImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
        }
    }
}
struct WebsitePage: View {
    let url: URL
    let title: String
    var body: some View {
        OfflineWebView(url: url)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .background(.white)
    }
}

struct OfflineWebView: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView()
        view.scrollView.contentInsetAdjustmentBehavior = .automatic
        view.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent().deletingLastPathComponent())
        return view
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
