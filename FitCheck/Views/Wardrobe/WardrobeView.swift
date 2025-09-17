
import SwiftUI

struct WardrobeView: View {
    @EnvironmentObject var app: AppState
    @EnvironmentObject var theme: Theme
    @State private var query = ""

    var filtered: [WardrobeItem] {
        if query.isEmpty { return app.wardrobe }
        return app.wardrobe.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.category.localizedCaseInsensitiveContains(query) ||
            ($0.brand ?? "").localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search wardrobe", text: $query)
                    .textFieldStyle(.plain)
            }
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)

            List {
                ForEach(filtered) { item in
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 8).fill(item.color)
                            .frame(width: 28, height: 28)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.5), lineWidth: 0.5))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name).font(.subheadline.bold())
                            Text("\(item.category)\(item.brand != nil ? " • \(item.brand!)" : "")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
        }
        .background(theme.bg.ignoresSafeArea())
        .navigationTitle("Wardrobe")
    }
}
