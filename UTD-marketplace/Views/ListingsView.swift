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
                        // wrap the entire card in a NavigationLink
                        NavigationLink(destination: ListingDetailView(listing: item)) {
                            VStack(spacing: 8) {
                                // square image
                                if let ui = UIImage(data: item.imageData) {
                                    Image(uiImage: ui)
                                        .resizable()
                                        .aspectRatio(1, contentMode: .fill)
                                        .clipped()
                                }

                                Text(item.title)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text("$\(item.price)")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)  // remove default nav link styling
                    }
                }
                .padding(16)
            }
            .navigationTitle("Listings")
        }
    }
}
