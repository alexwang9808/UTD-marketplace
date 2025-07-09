import SwiftUI

struct ListingsView: View {
    @EnvironmentObject var viewModel: ListingViewModel

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ✅ Clean, straight black line under nav bar
                Rectangle()
                    .fill(Color.orange)
                    .frame(height: 4)
                    .edgesIgnoringSafeArea(.horizontal)
                    .padding(.top, -10)

                ScrollView {
                    if viewModel.listings.isEmpty {
                        VStack(spacing: 16) {
                            Text("No listings at the moment.")
                                .font(.title3)
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity, minHeight: 300)
                    } else {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(viewModel.listings) { item in
                                NavigationLink {
                                    ListingDetailView(listing: item)
                                } label: {
                                    VStack(alignment: .leading, spacing: 8) {
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
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                }
            
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        TitleView(title: "Listings")
                    }
                }

            }

        }
    }
}
