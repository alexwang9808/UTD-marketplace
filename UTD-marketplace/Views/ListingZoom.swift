import SwiftUI

struct ListingDetailView: View {
    let listing: Listing

    @EnvironmentObject private var viewModel: ListingViewModel

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // — Detail Header —
                    if let imageUrl = listing.imageUrl, let url = URL(string: "http://localhost:3001\(imageUrl)") {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(12)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 200)
                                .cornerRadius(12)
                        }
                    } else if let data = listing.imageData, let ui = UIImage(data: data) {
                        Image(uiImage: ui)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(12)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 200)
                            .cornerRadius(12)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                                    .font(.title)
                            )
                    }

                    Text(listing.title)
                        .font(.largeTitle).bold()

                    Text("$\(listing.priceString)")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                    
                    if let location = listing.location {
                        Text(location)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let description = listing.description {
                        Text(description)
                            .font(.body)
                    }

                    // Send Message Button
                    if let userId = listing.userId, userId != viewModel.currentUserId {
                        NavigationLink {
                            ConversationDetailView(
                                listing: listing, 
                                otherUser: User(
                                    id: userId, 
                                    email: "user@utdallas.edu", 
                                    name: "Seller", 
                                    imageUrl: nil
                                )
                            )
                        } label: {
                            HStack {
                                Image(systemName: "message")
                                Text("Send a Message")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding(.top)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Listing")
        .navigationBarTitleDisplayMode(.inline)
    }
}
