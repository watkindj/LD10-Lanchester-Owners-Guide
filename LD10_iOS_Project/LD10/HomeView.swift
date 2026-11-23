import SwiftUI
import WebKit
import ZIPFoundation

@MainActor
final class WebsiteStore: ObservableObject {
    @Published var isReady = true
    @Published var errorMessage: String?

    let rootURL: URL

    private let packages: [String: String] = [
        "main": "https://raw.githubusercontent.com/watkindj/LD10-Lanchester-Owners-Guide/refs/heads/main/WebsitePackages/LD10-Main.zip",
        "bay": "https://raw.githubusercontent.com/watkindj/LD10-Lanchester-Owners-Guide/refs/heads/main/WebsitePackages/LD10-Bay.zip",
        "controls": "https://raw.githubusercontent.com/watkindj/LD10-Lanchester-Owners-Guide/refs/heads/main/WebsitePackages/LD10-Controls.zip",
        "restore": "https://raw.githubusercontent.com/watkindj/LD10-Lanchester-Owners-Guide/refs/heads/main/WebsitePackages/LD10-Restore.zip",
        "trim": "https://raw.githubusercontent.com/watkindj/LD10-Lanchester-Owners-Guide/refs/heads/main/WebsitePackages/LD10-Trim.zip"
    ]

    private enum StoreError: LocalizedError {
        case invalidPackageURL
        case pageNotFound(String)

        var errorDescription: String? {
            switch self {
            case .invalidPackageURL:
                return "The website package address is invalid."
            case .pageNotFound(let page):
                return "The website page could not be found: \(page)"
            }
        }
    }

    init() {
        let support = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]

        rootURL = support.appendingPathComponent(
            "LD10 Website Packages",
            isDirectory: true
        )
    }

    func page(_ relative: String) -> URL {
        rootURL.appendingPathComponent(relative)
    }

    func preparePage(_ relative: String) async throws -> URL {
        try await ensurePackage("main")

        let folder = relative.lowercased()

        if folder.hasPrefix("bay/") {
            try await ensurePackage("bay")
        } else if folder.hasPrefix("controls/") {
            try await ensurePackage("controls")
        } else if folder.hasPrefix("restore/") {
            try await ensurePackage("restore")
        } else if folder.hasPrefix("trim/") {
            try await ensurePackage("trim")
        }

        let pageURL = page(relative)

        guard FileManager.default.fileExists(atPath: pageURL.path) else {
            throw StoreError.pageNotFound(relative)
        }

        return pageURL
    }

    private func ensurePackage(_ name: String) async throws {
        let marker = rootURL.appendingPathComponent(
            ".ld10-\(name)-installed"
        )

        if FileManager.default.fileExists(atPath: marker.path) {
            return
        }

        guard
            let address = packages[name],
            let remoteURL = URL(string: address)
        else {
            throw StoreError.invalidPackageURL
        }

        try FileManager.default.createDirectory(
            at: rootURL,
            withIntermediateDirectories: true
        )

        let (archiveURL, _) = try await URLSession.shared.download(
            from: remoteURL
        )

        try FileManager.default.unzipItem(
            at: archiveURL,
            to: rootURL
        )

        FileManager.default.createFile(
            atPath: marker.path,
            contents: Data()
        )
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
            }            .navigationBarHidden(true)
            .sheet(item: $selected) { section in
                NavigationStack {
                    WebsitePage(
                        store: store,
                        relativePath: section.file,
                        title: section.title
                    )
                }
            }
            .sheet(isPresented: $showOriginalHome) {
                NavigationStack {
                    WebsitePage(
                        store: store,
                        relativePath: "index.htm",
                        title: "Lanchester LD10"
                    )
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
                if let path = Bundle.main.path(forResource: "LD10Hero", ofType: "png", inDirectory: "LD10Media"),
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

            if let path = Bundle.main.path(forResource: "LD10CarDetail", ofType: "jpeg", inDirectory: "LD10Media"),
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
    @ObservedObject var store: WebsiteStore
    let relativePath: String
    let title: String

    @State private var pageURL: URL?
    @State private var errorMessage: String?
    @State private var isLoading = true

    var body: some View {
        Group {
            if let pageURL {
                OfflineWebView(url: pageURL, store: store)
            } else if let errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                    Text("Unable to open page")
                        .font(.headline)
                    Text(errorMessage)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                    Button("Try again") {
                        Task { await loadPage() }
                    }
                }
                .padding()
            } else if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Preparing website page…")
                        .font(.subheadline)
                    Text("The required package will be downloaded if needed.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .background(.white)
        .task {
            await loadPage()
        }
    }

    @MainActor
    private func loadPage() async {
        isLoading = true
        errorMessage = nil

        do {
            pageURL = try await store.preparePage(relativePath)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

struct OfflineWebView: UIViewRepresentable {
    let url: URL
    let store: WebsiteStore

    func makeCoordinator() -> Coordinator {
        Coordinator(store: store)
    }

    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView()
        view.scrollView.contentInsetAdjustmentBehavior = .automatic
        view.navigationDelegate = context.coordinator

        context.coordinator.preparedURLs.insert(url.standardizedFileURL.path)

        view.loadFileURL(
            url,
            allowingReadAccessTo: store.rootURL
        )

        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate {
        let store: WebsiteStore
        var preparedURLs = Set<String>()

        init(store: WebsiteStore) {
            self.store = store
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let destination = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            guard destination.isFileURL else {
                decisionHandler(.allow)
                return
            }

            let destinationPath = destination.standardizedFileURL.path
            let rootPath = store.rootURL.standardizedFileURL.path

            guard destinationPath.hasPrefix(rootPath + "/") else {
                decisionHandler(.allow)
                return
            }

            if preparedURLs.remove(destinationPath) != nil {
                decisionHandler(.allow)
                return
            }

            decisionHandler(.cancel)

            let relativePath = String(
                destinationPath.dropFirst(rootPath.count + 1)
            )

            Task { @MainActor in
                do {
                    let preparedURL = try await store.preparePage(relativePath)

                    preparedURLs.insert(preparedURL.standardizedFileURL.path)

                    webView.loadFileURL(
                        preparedURL,
                        allowingReadAccessTo: store.rootURL
                    )
                } catch {
                    print("LD10 page loading error: \(error.localizedDescription)")
                }
            }
        }
    }
}
