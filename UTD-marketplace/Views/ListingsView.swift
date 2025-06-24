import SwiftUI

struct ListingsView: View {
    @EnvironmentObject var viewModel: ListingViewModel

    // Two equal columns
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.listings) { item in
                        VStack(spacing: 8) {
                            // full-width square image
                            if let ui = UIImage(data: item.imageData) {
                                Image(uiImage: ui)
                                    .resizable()
                                    .aspectRatio(1, contentMode: .fill)
                                    .clipped()
                            }

                            // title + price
                            Text(item.title)
                                .font(.subheadline)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text("$" + item.price)
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity)      // fill its column
                    }
                }
                .padding(16)                         // gutter on all sides
            }
            .navigationTitle("Listings")
        }
    }
}
