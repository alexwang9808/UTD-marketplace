import SwiftUI

struct ListingDetailView: View {
    let listing: Listing

    @EnvironmentObject private var viewModel: ListingViewModel
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var messageText = ""
    @State private var isSendingMessage = false
    @State private var showSuccessMessage = false
    @State private var showingAuthentication = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // — Image Gallery —
                    if !listing.imageUrls.isEmpty {
                        TabView {
                            ForEach(Array(listing.imageUrls.enumerated()), id: \.offset) { index, imageUrl in
                                if let url = URL(string: "http://localhost:3001\(imageUrl)") {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .cornerRadius(12)
                                        case .failure(_):
                                            Rectangle()
                                                .fill(Color.red.opacity(0.3))
                                                .frame(height: 200)
                                                .cornerRadius(12)
                                                .overlay(
                                                    Image(systemName: "exclamationmark.triangle")
                                                        .foregroundColor(.red)
                                                )
                                        case .empty:
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(height: 200)
                                                .cornerRadius(12)
                                                .overlay(
                                                    ProgressView()
                                                )
                                        @unknown default:
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(height: 200)
                                                .cornerRadius(12)
                                        }
                                    }
                                }
                            }
                        }
                        .frame(height: 250)
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
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

                    // Seller info section
                    HStack(spacing: 12) {
                        // Seller profile picture
                        Group {
                            if let user = listing.user,
                               let imageUrl = user.imageUrl,
                               let url = URL(string: "http://localhost:3001\(imageUrl)") {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Circle()
                                        .fill(Color(red: 0.0, green: 0.4, blue: 0.2).opacity(0.2))
                                        .overlay(
                                            ProgressView()
                                                .scaleEffect(0.6)
                                        )
                                }
                            } else {
                                Circle()
                                    .fill(Color(red: 0.0, green: 0.4, blue: 0.2).opacity(0.2))
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(Color(red: 0.0, green: 0.4, blue: 0.2))
                                    )
                            }
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Seller")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(listing.user?.name ?? "User \(listing.userId ?? 0)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

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

                    // Message Composer Section (for other users' listings)
                    if let userId = listing.userId, 
                       let currentUserId = authManager.currentUser?.id,
                       userId != currentUserId {
                        VStack(spacing: 12) {
                            // Success message
                            if showSuccessMessage {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Message sent! Check your Messages tab to continue the conversation.")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            if authManager.isAuthenticated {
                                // Message composer for authenticated users
                                VStack(spacing: 8) {
                                    Text("Send a message to \(listing.user?.name ?? "User \(userId)")")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    HStack(spacing: 12) {
                                        TextField("Type your message...", text: $messageText, axis: .vertical)
                                            .textFieldStyle(.roundedBorder)
                                            .lineLimit(1...3)
                                            .disabled(isSendingMessage)
                                        
                                        Button {
                                            sendMessage()
                                        } label: {
                                            if isSendingMessage {
                                                ProgressView()
                                                    .scaleEffect(0.8)
                                            } else {
                                                Image(systemName: "paperplane.fill")
                                            }
                                        }
                                        .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSendingMessage)
                                        .padding(8)
                                        .background(
                                            messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSendingMessage 
                                            ? Color.gray.opacity(0.3) 
                                            : Color(red: 0.0, green: 0.4, blue: 0.2)
                                        )
                                        .foregroundColor(
                                            messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSendingMessage 
                                            ? .secondary 
                                            : .white
                                        )
                                        .cornerRadius(8)
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            } else {
                                // Login prompt for unauthenticated users
                                VStack(spacing: 12) {
                                    HStack {
                                        Image(systemName: "lock.circle")
                                            .font(.title2)
                                            .foregroundColor(.orange)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Login Required")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                            Text("Sign in to message \(listing.user?.name ?? "the seller")")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                    }
                                    
                                    Button(action: {
                                        showingAuthentication = true
                                    }) {
                                        Text("Login to Send Message")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.orange)
                                            .cornerRadius(8)
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.top)
                    }
                    

                }
                .padding()
            }
        }
        .navigationTitle("Listing")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAuthentication) {
            AuthenticationView()
        }
    }
    
    private func sendMessage() {
        guard let listingId = listing.id,
              !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        isSendingMessage = true
        
        viewModel.sendMessage(
            to: listingId,
            content: messageText.trimmingCharacters(in: .whitespacesAndNewlines),
            authToken: authManager.authToken
        ) { success in
            DispatchQueue.main.async {
                isSendingMessage = false
                
                if success {
                    messageText = ""
                    showSuccessMessage = true
                    
                    // Refresh conversations so they appear in Messages tab
                    viewModel.fetchConversations()
                } else {
                    // Could add error handling here
                    print("Failed to send message")
                }
            }
        }
    }
}
