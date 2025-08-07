import SwiftUI

struct MyListingsView: View {
    @EnvironmentObject private var viewModel: ListingViewModel
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedListingToEdit: Listing?
    
    // Computed property to get current user's listings
    private var myListings: [Listing] {
        guard let currentUserId = authManager.currentUser?.id else { return [] }
        return viewModel.listings.filter { $0.userId == currentUserId }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Orange line right below navigation bar
                Rectangle()
                    .fill(Color.orange)
                    .frame(height: 4)
                    .edgesIgnoringSafeArea(.horizontal)
                    .padding(.top, -10)
                
                if myListings.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        VStack(spacing: 8) {
                            Text("No listings yet")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("Create your first listing to start selling")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
                } else {
                    // Listings grid
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(myListings, id: \.id) { listing in
                                VStack(spacing: 12) {
                                    // Listing image
                                    Group {
                                        if let imageUrl = listing.imageUrls.first,
                                           let url = URL(string: "http://localhost:3001\(imageUrl)") {
                                            AsyncImage(url: url) { image in
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                            } placeholder: {
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.3))
                                                    .overlay(ProgressView())
                                            }
                                        } else {
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.3))
                                                .overlay(
                                                    Image(systemName: "photo")
                                                        .foregroundColor(.gray)
                                                        .font(.title2)
                                                )
                                        }
                                    }
                                    .frame(height: 120)
                                    .clipped()
                                    .cornerRadius(12)
                                    
                                    // Listing details
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(listing.title)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .lineLimit(2)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        Text("$\(listing.priceString)")
                                            .font(.subheadline)
                                            .foregroundColor(.orange)
                                            .fontWeight(.semibold)
                                        
                                        if let location = listing.location {
                                            Text(location)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                    }
                                    
                                    // Manage button
                                    Button(action: {
                                        selectedListingToEdit = listing
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "pencil")
                                            Text("Manage")
                                        }
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(Color(red: 0.0, green: 0.4, blue: 0.2))
                                        .cornerRadius(8)
                                    }
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                            }
                        }
                        .padding()
                    }
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("My Listings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.fetchListings()
            }
            .sheet(item: $selectedListingToEdit) { listing in
                EditListingView(listing: listing)
            }
        }
    }
}

#Preview {
    MyListingsView()
        .environmentObject(ListingViewModel())
        .environmentObject(AuthenticationManager())
}