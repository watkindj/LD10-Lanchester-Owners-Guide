
import SwiftUI

struct LD10Section: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let symbol: String
}

struct ContentView: View {

    private let green = Color(
        red: 31/255,
        green: 57/255,
        blue: 43/255
    )

    private let cream = Color(
        red: 246/255,
        green: 235/255,
        blue: 204/255
    )

    private let sections = [
        LD10Section(
            title: "History",
            subtitle: "Articles and photographs",
            symbol: "book.closed"
        ),
        LD10Section(
            title: "Technical Library",
            subtitle: "Engineering and information",
            symbol: "wrench.and.screwdriver"
        ),
        LD10Section(
            title: "Manuals & PDFs",
            subtitle: "Workshop resources",
            symbol: "doc.text"
        ),
        LD10Section(
            title: "Latest News",
            subtitle: "Updates and events",
            symbol: "newspaper"
        )
    ]

    private let columns = [
        GridItem(.adaptive(minimum: 145), spacing: 14)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {

                    Text("LANCHESTER")
                        .font(.system(
                            size: 27,
                            weight: .regular,
                            design: .serif
                        ))
                        .tracking(6)

                    Text("LD10")
                        .font(.system(
                            size: 64,
                            weight: .bold,
                            design: .serif
                        ))

                    Image("LD10Car")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 235)
                        .clipped()
                        .clipShape(
                            RoundedRectangle(cornerRadius: 18)
                        )

                    Text("History • Engineering • Preservation")
                        .font(.system(
                            size: 15,
                            design: .serif
                        ))
                        .italic()

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(sections) { section in
                            NavigationLink {
                                SectionView(section: section)
                            } label: {
                                VStack(spacing: 12) {
                                    Image(systemName: section.symbol)
                                        .font(.system(size: 30))

                                    Text(section.title)
                                        .font(.system(
                                            size: 18,
                                            weight: .semibold,
                                            design: .serif
                                        ))

                                    Text(section.subtitle)
                                        .font(.caption)
                                        .multilineTextAlignment(.center)
                                }
                                .foregroundStyle(cream)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 145)
                                .padding(10)
                                .background(green)
                                .clipShape(
                                    RoundedRectangle(cornerRadius: 14)
                                )
                            }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: 850)
                .frame(maxWidth: .infinity)
            }
            .background(cream.opacity(0.35))
            .navigationBarHidden(true)
        }
    }
}

struct SectionView: View {
    let section: LD10Section

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: section.symbol)
                .font(.system(size: 45))

            Text(section.title)
                .font(.largeTitle)
                .fontDesign(.serif)

            Text(section.subtitle)

            Text("LD10 website content will be connected here.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .navigationTitle(section.title)
    }
}
