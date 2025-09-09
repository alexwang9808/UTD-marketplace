import SwiftUI

struct SellerProfileView: View {
    let seller: User
    @EnvironmentObject private var viewModel: ListingViewModel
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    @State private var pressedListingId: Int? = nil
    
    // Computed property to get seller's listings count
    private var sellerListingsCount: Int {
        guard let sellerId = seller.id else { return 0 }
        return viewModel.listings.filter { $0.userId == sellerId }.count
    }
    
    // Get seller's listings
    private var sellerListings: [Listing] {
        guard let sellerId = seller.id else { return [] }
        return viewModel.listings.filter { $0.userId == sellerId }
    }
    
    var body: some View {
            ZStack {
                // Clean background
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Modern orange accent bar
                    LinearGradient(
                        colors: [Color.orange, Color.orange.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 4)
                    .frame(maxWidth: .infinity)
                    
                    // Profile header
                    VStack(spacing: 16) {
                        // Profile picture
                        Group {
                            if let imageUrl = seller.imageUrl,
                               let url = URL(string: "http://localhost:3001\(imageUrl)") {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } placeholder: {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 100, height: 100)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 40))
                                                .foregroundColor(.gray)
                                        )
                                }
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(.gray)
                                    )
                            }
                        }
                        
                        // User info
                        VStack(spacing: 12) {
                            Text(seller.name ?? "Unknown User")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            // Bio section
                            if let bio = seller.bio, !bio.isEmpty {
                                Text(bio)
                                    .font(.body)
                                    .foregroundColor(.gray)
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(3)
                            }

                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Seller's listings section
                    if !sellerListings.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("\(sellerListingsCount) \(sellerListingsCount == 1 ? "listing" : "listings")")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ], spacing: 16) {
                                ForEach(sellerListings, id: \.id) { listing in
                                    NavigationLink(destination: ListingDetailView(listing: listing)) {
                                        sellerListingCard(listing: listing, isPressed: pressedListingId == listing.id)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .simultaneousGesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { _ in
                                                pressedListingId = listing.id
                                            }
                                            .onEnded { _ in
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                                    pressedListingId = nil
                                                }
                                            }
                                    )
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
            }
        }
        .navigationTitle(seller.name ?? "Profile")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                }
            }
        }
    }
    
    @ViewBuilder
    private func sellerListingCard(listing: Listing, isPressed: Bool = false) -> some View {
        VStack(spacing: 0) {
            // Image
            if let imageUrl = listing.primaryImageUrl,
               let url = URL(string: "http://localhost:3001\(imageUrl)") {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 120)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 120)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 24))
                                .foregroundColor(.gray)
                        )
                }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 120)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    )
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(listing.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text("$\(listing.priceString)")
                    .font(.title3)
                    .fontWeight(.bold)
                
                // Time and clicks
                HStack(spacing: 8) {
                    HStack(spacing: 3) {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(listing.timeAgo)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 3) {
                        Image(systemName: "eye.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(listing.clickCount ?? 0)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            ZStack {
                // Base white rounded rectangle background
                Color.white
                
                // Gray bubble overlay when pressed
                if isPressed {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.2))
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

struct SellerProfileView_Previews: PreviewProvider {
    static var previews: some View {
        let mockSeller = User(
            id: 1,
            email: "seller@test.com",
            name: "John Doe",
            imageUrl: nil,
            bio: "Selling great items on campus!"
        )
        
        NavigationView {
            SellerProfileView(seller: mockSeller)
                .environmentObject(ListingViewModel())
                .environmentObject(AuthenticationManager())
        }
    }
}
