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
    "trim": "https://raw.githubusercontent.com/watkindj/LD10-Lanchester-Owners-Guide/refs/heads/main/WebsitePackages/LD10-Trim.zip",
    "photos01": "https://raw.githubusercontent.com/watkindj/LD10-Lanchester-Owners-Guide/refs/heads/main/WebsitePackages/Photos-01.zip",
    "photos02": "https://raw.githubusercontent.com/watkindj/LD10-Lanchester-Owners-Guide/refs/heads/main/WebsitePackages/Photos-02.zip",
    "photos03": "https://raw.githubusercontent.com/watkindj/LD10-Lanchester-Owners-Guide/refs/heads/main/WebsitePackages/Photos-03.zip",
    "photos04": "https://raw.githubusercontent.com/watkindj/LD10-Lanchester-Owners-Guide/refs/heads/main/WebsitePackages/Photos-04.zip",
    "photos05": "https://raw.githubusercontent.com/watkindj/LD10-Lanchester-Owners-Guide/refs/heads/main/WebsitePackages/Photos-05.zip",
    "photos06": "https://raw.githubusercontent.com/watkindj/LD10-Lanchester-Owners-Guide/refs/heads/main/WebsitePackages/Photos-06.zip",
    "photos07": "https://raw.githubusercontent.com/watkindj/LD10-Lanchester-Owners-Guide/refs/heads/main/WebsitePackages/Photos-07.zip"
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
            "LD10 Website Packages v5",
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
        } else if folder.hasPrefix("photos/") {
            try await ensurePackage("photos01")
            try await ensurePackage("photos02")
            try await ensurePackage("photos03")
            try await ensurePackage("photos04")
            try await ensurePackage("photos05")
            try await ensurePackage("photos06")
            try await ensurePackage("photos07")
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
    let expectedFilesExist: Bool

    switch name {
    case "trim":
        expectedFilesExist = FileManager.default.fileExists(
            atPath: rootURL.appendingPathComponent("trim/ntrim.htm").path
        )
    case "photos01", "photos02", "photos03", "photos04",
         "photos05", "photos06", "photos07":
        expectedFilesExist = FileManager.default.fileExists(
            atPath: rootURL.appendingPathComponent("photos").path
        )
    default:
        expectedFilesExist = true
    }

    if expectedFilesExist {
        return
    }

    try FileManager.default.removeItem(at: marker)
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

    let destinationURL: URL

if name.hasPrefix("photos") {
        destinationURL = rootURL.appendingPathComponent(
            "photos",
            isDirectory: true
        )
    } else {
        destinationURL = rootURL
    }

    try FileManager.default.createDirectory(
        at: destinationURL,
        withIntermediateDirectories: true
    )

    let (archiveURL, _) = try await URLSession.shared.download(
        from: remoteURL
    )

    try FileManager.default.unzipItem(
        at: archiveURL,
        to: destinationURL
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
        GuideSection(id: "controls", title: "Technical Information", subtitle: "Systems, components and details", symbol: "gearshape.2", file: "index_6.htm"),
        GuideSection(id: "trim", title: "Interior & Exterior", subtitle: "Upholstery, Trim, Body & Chromework", symbol: "car.side", file: "trim/ntrim.htm"),
        GuideSection(id: "spares", title: "Spares", subtitle: "Parts and spares information", symbol: "shippingbox", file: "docs/spares.htm"),
        GuideSection(id: "cars", title: "Owners' Cars", subtitle: "Cars and owner information", symbol: "car.2", file: "docs/cars.htm"),
        GuideSection(id: "photos", title: "Photographs", subtitle: "Original photo collection", symbol: "photo.on.rectangle.angled", file: "photos/photos.htm"),
        GuideSection(id: "contact", title: "Contact", subtitle: "Original site contact details", symbol: "envelope", file: "docs/contact.htm")
    ]


var body: some View {
    GeometryReader { geometry in
        let useDuoLayout =
            UIDevice.current.userInterfaceIdiom == .phone &&
            geometry.size.width >= 700

        NavigationStack {
            ZStack {
                Color(red: 0.07, green: 0.22, blue: 0.13)
                    .ignoresSafeArea()

                ScrollView {
                    Group {
                        if useDuoLayout {
                            HStack(alignment: .center, spacing: 24) {
                                header
                                    .frame(maxWidth: 420)

                                navigationPanel
                                    .frame(maxWidth: 560)
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 20) {
                                header
                                navigationPanel
                            }
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: useDuoLayout ? 1100 : 850)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: geometry.size.height, alignment: .top)
                }
            }
            .navigationBarHidden(true)
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
}



private var navigationPanel: some View {
    VStack(alignment: .leading, spacing: 20) {
        if let error = store.errorMessage {
            Text(error)
                .foregroundStyle(.red)
                .padding()
        } else if !store.isReady {
            ProgressView("Preparing the offline guide…")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
        } else {
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: 12
            ) {
                ForEach(sections) { section in
                    Button {
                        selected = section
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: section.symbol)
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(Color(red: 0.91, green: 0.82, blue: 0.59))
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 7) {
                                Text(section.title)
                                    .font(.system(size: 15, weight: .bold, design: .serif))
                                    .foregroundStyle(Color(red: 0.96, green: 0.91, blue: 0.79))
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.7)

                                Text(section.subtitle)
                                    .font(.system(size: 10, design: .serif))
                                    .foregroundStyle(Color(red: 0.91, green: 0.82, blue: 0.59))
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.8)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .layoutPriority(1)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color(red: 0.91, green: 0.82, blue: 0.59))
                        }
                        .frame(maxWidth: .infinity, minHeight: 115)
                        .padding(10)
                        .background(
                            Color(red: 0.09, green: 0.27, blue: 0.17),
                            in: RoundedRectangle(cornerRadius: 18)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(
                                    Color(red: 0.91, green: 0.82, blue: 0.59),
                                    lineWidth: 2
                                )
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Button {
                showOriginalHome = true
            } label: {
                Label("Open complete original website", systemImage: "globe")
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        Color(red: 0.09, green: 0.27, blue: 0.17),
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                Color(red: 0.91, green: 0.82, blue: 0.59),
                                lineWidth: 2
                            )
                    }
                    .foregroundStyle(Color(red: 0.96, green: 0.91, blue: 0.79))
            }
            .buttonStyle(.plain)

            Text("The original website pages, photographs and PDF documents are stored in this app for offline browsing.")
                .font(.footnote)
                .foregroundStyle(Color(red: 0.96, green: 0.91, blue: 0.79))
                .padding(.horizontal, 3)
        }
    }
}


private var header: some View {
    VStack(spacing: 15) {

        if let path = Bundle.main.path(
            forResource: "LD10Logo_Cream",
            ofType: "png",
            inDirectory: "LD10Media"
        ), let logo = UIImage(contentsOfFile: path) {
            Image(uiImage: logo)
                .resizable()
                .scaledToFit()
                .frame(height: 50)
        } else {
            Text("LANCHESTER")
                .font(.system(size: 30, weight: .medium, design: .serif))
                .tracking(5)
                .foregroundStyle(Color(red: 0.96, green: 0.91, blue: 0.79))
        }

        if let path = Bundle.main.path(
            forResource: "LD10Script_Cream",
            ofType: "png",
            inDirectory: "LD10Media"
        ), let script = UIImage(contentsOfFile: path) {
            Image(uiImage: script)
                .resizable()
                .scaledToFit()
                .frame(height: 65)
        }

        Text("Briggs and Barker Owner's Guide")
            .font(.system(size: 17, weight: .semibold, design: .serif))
            .italic()
            .foregroundStyle(Color(red: 0.96, green: 0.91, blue: 0.79))
            .multilineTextAlignment(.center)

        if let path = Bundle.main.path(
            forResource: "LD10Hero",
            ofType: "png",
            inDirectory: "LD10Media"
        ), let car = UIImage(contentsOfFile: path) {
            Image(uiImage: car)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 650)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .overlay {
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(
                            Color(red: 0.91, green: 0.84, blue: 0.65),
                            lineWidth: 3
                        )
                }
        }

        Text("History  ·  Engineering  ·  Preservation")
            .font(.system(size: 17, weight: .semibold, design: .serif))
            .italic()
            .foregroundStyle(Color(red: 0.96, green: 0.91, blue: 0.79))
            .multilineTextAlignment(.center)
    }
    .padding(16)
    .frame(maxWidth: .infinity)
    .background(
        Color(red: 0.07, green: 0.22, blue: 0.13),
        in: RoundedRectangle(cornerRadius: 22)
    )
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
