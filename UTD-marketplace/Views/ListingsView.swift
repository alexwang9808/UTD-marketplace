import SwiftUI

struct ListingsView: View {
    @EnvironmentObject var viewModel: ListingViewModel

    // two equal columns
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.listings) { item in
                        NavigationLink {
                            ListingDetailView(listing: item)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                // square image with a corner radius
                                if let ui = UIImage(data: item.imageData) {
                                    Image(uiImage: ui)
                                        .resizable()
                                        .aspectRatio(1, contentMode: .fill)
                                        .frame(maxWidth: .infinity)
                                        .clipped()
                                        .cornerRadius(8)
                                }

                                Text(item.title)
                                    .font(.subheadline)
                                    .lineLimit(1)

                                Text("$\(item.price)")
                                    .font(.headline)

                                Text(item.location)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)  // remove default nav link styling
                    }
                }
                .padding(16)  // gutter on all sides
            }
            .navigationTitle("Listings")
        }
    }
}
