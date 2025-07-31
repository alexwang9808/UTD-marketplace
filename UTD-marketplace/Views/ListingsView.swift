import SwiftUI

struct ListingsView: View {
    @EnvironmentObject var viewModel: ListingViewModel
    @State private var showingAddListing = false

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // ✅ Clean, straight black line under nav bar
                Rectangle()
                    .fill(Color.orange)
                    .frame(height: 4)
                    .edgesIgnoringSafeArea(.horizontal)
                
                VStack(spacing: 20) {
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
                                        if let imageUrl = item.primaryImageUrl, let url = URL(string: "http://localhost:3001\(imageUrl)") {
                                            AsyncImage(url: url) { phase in
                                                switch phase {
                                                case .success(let image):
                                                    image
                                                        .resizable()
                                                        .aspectRatio(1, contentMode: .fill)
                                                        .frame(maxWidth: .infinity)
                                                        .clipped()
                                                        .cornerRadius(8)
                                                case .failure(_):
                                                    Rectangle()
                                                        .fill(Color.red.opacity(0.3))
                                                        .aspectRatio(1, contentMode: .fill)
                                                        .frame(maxWidth: .infinity)
                                                        .clipped()
                                                        .cornerRadius(8)
                                                        .overlay(
                                                            Image(systemName: "exclamationmark.triangle")
                                                                .foregroundColor(.red)
                                                        )
                                                case .empty:
                                                    Rectangle()
                                                        .fill(Color.gray.opacity(0.3))
                                                        .aspectRatio(1, contentMode: .fill)
                                                        .frame(maxWidth: .infinity)
                                                        .clipped()
                                                        .cornerRadius(8)
                                                        .overlay(
                                                            ProgressView()
                                                        )
                                                @unknown default:
                                                    Rectangle()
                                                        .fill(Color.gray.opacity(0.3))
                                                        .aspectRatio(1, contentMode: .fill)
                                                        .frame(maxWidth: .infinity)
                                                        .clipped()
                                                        .cornerRadius(8)
                                                }
                                            }
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

                                        // Seller info
                                        HStack(spacing: 6) {
                                            // Seller profile picture
                                            Group {
                                                if let user = item.user,
                                                   let imageUrl = user.imageUrl,
                                                   let url = URL(string: "http://localhost:3001\(imageUrl)") {
                                                    AsyncImage(url: url) { image in
                                                        image
                                                            .resizable()
                                                            .scaledToFill()
                                                    } placeholder: {
                                                        Circle()
                                                            .fill(Color.blue.opacity(0.2))
                                                            .overlay(
                                                                Image(systemName: "person.fill")
                                                                    .font(.system(size: 8))
                                                                    .foregroundColor(.blue)
                                                            )
                                                    }
                                                } else {
                                                    Circle()
                                                        .fill(Color.blue.opacity(0.2))
                                                        .overlay(
                                                            Image(systemName: "person.fill")
                                                                .font(.system(size: 8))
                                                                .foregroundColor(.blue)
                                                        )
                                                }
                                            }
                                            .frame(width: 16, height: 16)
                                            .clipShape(Circle())
                                            
                                            // Seller name
                                            Text(item.user?.name ?? "User \(item.userId ?? 0)")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                            
                                            Spacer()
                                        }

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
                }
            
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        TitleView(title: "Listings")
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingAddListing = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(.orange)
                        }
                    }
                }
                .sheet(isPresented: $showingAddListing) {
                    AddListingView()
                }

            }

        }
    }
}
