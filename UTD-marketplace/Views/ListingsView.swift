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
                                        if let imageUrl = item.imageUrl, let url = URL(string: "http://localhost:3001\(imageUrl)") {
                                            AsyncImage(url: url) { image in
                                                image
                                                    .resizable()
                                                    .aspectRatio(1, contentMode: .fill)
                                                    .frame(maxWidth: .infinity)
                                                    .clipped()
                                                    .cornerRadius(8)
                                            } placeholder: {
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.3))
                                                    .aspectRatio(1, contentMode: .fill)
                                                    .frame(maxWidth: .infinity)
                                                    .clipped()
                                                    .cornerRadius(8)
                                            }
                                        } else if let data = item.imageData, let ui = UIImage(data: data) {
                                            Image(uiImage: ui)
                                                .resizable()
                                                .aspectRatio(1, contentMode: .fill)
                                                .frame(maxWidth: .infinity)
                                                .clipped()
                                                .cornerRadius(8)
                                        } else {
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.3))
                                                .aspectRatio(1, contentMode: .fill)
                                                .frame(maxWidth: .infinity)
                                                .clipped()
                                                .cornerRadius(8)
                                                .overlay(
                                                    Image(systemName: "photo")
                                                        .foregroundColor(.gray)
                                                        .font(.title)
                                                )
                                        }

                                        Text(item.title)
                                            .font(.subheadline)
                                            .lineLimit(1)

                                        Text("$\(item.priceString)")
                                            .font(.headline)

                                        if let location = item.location {
                                            Text(location)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
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
