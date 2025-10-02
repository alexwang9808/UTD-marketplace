import SwiftUI

struct ListingDetailView: View {
    let listing: Listing

    @EnvironmentObject private var viewModel: ListingViewModel
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    @State private var messageText = ""
    @State private var isSendingMessage = false
    @State private var showSuccessMessage = false
    @State private var showingAuthentication = false
    @State private var pressedSellerProfile = false
    
    // Use live listing data from viewModel if available, fallback to passed listing
    private var currentListing: Listing {
        if let listingId = listing.id,
           let liveListing = viewModel.listings.first(where: { $0.id == listingId }) {
            return liveListing
        }
        return listing
    }

    var body: some View {
        ZStack {
            // Clean background
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // — Modern Image Gallery Card —
                    VStack(spacing: 0) {
                        if !currentListing.imageUrls.isEmpty {
                            TabView {
                                ForEach(Array(currentListing.imageUrls.enumerated()), id: \.offset) { index, imageUrl in
                                    if let url = URL(string: "http://localhost:3001\(imageUrl)") {
                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                            case .failure(_):
                                                RoundedRectangle(cornerRadius: 20)
                                                    .fill(Color.red.opacity(0.1))
                                                    .frame(height: 250)
                                                    .overlay(
                                                        VStack(spacing: 8) {
                                                            Image(systemName: "exclamationmark.triangle.fill")
                                                                .font(.title2)
                                                                .foregroundColor(.red)
                                                            Text("Failed to load")
                                                                .font(.caption)
                                                                .foregroundColor(.red)
                                                        }
                                                    )
                                            case .empty:
                                                RoundedRectangle(cornerRadius: 20)
                                                    .fill(Color.gray.opacity(0.1))
                                                    .frame(height: 250)
                                                    .overlay(
                                                        ProgressView()
                                                            .scaleEffect(1.2)
                                                    )
                                            @unknown default:
                                                RoundedRectangle(cornerRadius: 20)
                                                    .fill(Color.gray.opacity(0.1))
                                                    .frame(height: 250)
                                            }
                                        }
                                    }
                                }
                            }
                            .frame(height: 300)
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                        } else {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(height: 250)
                                .overlay(
                                    VStack(spacing: 12) {
                                        Image(systemName: "photo.fill")
                                            .font(.system(size: 48))
                                            .foregroundColor(.gray.opacity(0.6))
                                        Text("No images available")
                                            .font(.headline)
                                            .foregroundColor(.gray)
                                    }
                                )
                        }
                    }
                    .padding(.horizontal, 16)

                    // — Modern Listing Info Card —
                    VStack(alignment: .leading, spacing: 20) {
                        // Title
                        Text(currentListing.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        // Price
                        Text("$\(currentListing.priceString)")
                            .font(.title)
                            .fontWeight(.bold)
        
                        
                        // Seller info section (clickable)
                        if let user = currentListing.user {
                            NavigationLink(destination: SellerProfileView(seller: user)) {
                                HStack(spacing: 16) {
                                    // Seller profile picture
                                    Group {
                                        if let imageUrl = user.imageUrl,
                                           let url = URL(string: "http://localhost:3001\(imageUrl)") {
                                            AsyncImage(url: url) { image in
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                            } placeholder: {
                                                Circle()
                                                    .fill(Color(red: 0.0, green: 0, blue: 0).opacity(0.2))
                                                    .overlay(
                                                        ProgressView()
                                                            .scaleEffect(0.8)
                                                    )
                                            }
                                        } else {
                                            Circle()
                                                .fill(Color.gray.opacity(0.3))
                                                .overlay(
                                                    Image(systemName: "person.fill")
                                                        .font(.system(size: 20))
                                                        .foregroundColor(.gray)
                                                )
                                        }
                                    }
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(user.name ?? "User \(currentListing.userId ?? 0)")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                    }
                                    
                                    Spacer()
                                    
                                    // Navigation indicator
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    ZStack {
                                        // Base clear background that fills entire area
                                        Rectangle()
                                            .fill(Color.clear)
                                        
                                        // Gray bubble overlay when pressed
                                        if pressedSellerProfile {
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.gray.opacity(0.2))
                                        }
                                    }
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { _ in
                                        pressedSellerProfile = true
                                    }
                                    .onEnded { _ in
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                            pressedSellerProfile = false
                                        }
                                    }
                            )
                        } else {
                            // Fallback for when user data is not available
                            HStack(spacing: 16) {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.gray)
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("User \(currentListing.userId ?? 0)")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                }
                                
                                Spacer()
                            }
                        }
                        
                        // Description
                        if let description = currentListing.description {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                Text(description)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .lineSpacing(2)
                            }
                        }
                        
                        // Time ago and Location
                        VStack(spacing: 8) {
                            // Time ago
                            HStack(spacing: 6) {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                Text(currentListing.timeAgo)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            
                            // Location and Click count on same row
                            HStack {
                                if let location = currentListing.location {
                                    HStack(spacing: 8) {
                                        Image(systemName: "location.fill")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                        Text(location)
                                            .font(.body)
                                            .foregroundColor(.black)
                                    }
                                }
                                
                                Spacer()
                                
                                // Click count on bottom right
                                HStack(spacing: 6) {
                                    Image(systemName: "eye.fill")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                    Text("\(currentListing.clickCount ?? 0) \((currentListing.clickCount ?? 0) == 1 ? "click" : "clicks")")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
                            .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
                    )
                    .padding(.horizontal, 16)

                    // — Modern Message Composer Card —
                    if let userId = currentListing.userId, 
                       let currentUserId = authManager.currentUser?.id,
                       userId != currentUserId {
                        VStack(spacing: 16) {
                            // Success message
                            if showSuccessMessage {
                                HStack(spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.green)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Message sent!")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.green)
                                    }
                                    Spacer()
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.green.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                            
                            if authManager.isAuthenticated {
                                // Modern message composer for authenticated users
                                VStack(spacing: 16) {
                                    Text("Send a message to \(currentListing.user?.name ?? "User \(userId)")")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    HStack(spacing: 12) {
                                        // Modern text field
                                        TextField("Type your message...", text: $messageText, axis: .vertical)
                                            .font(.body)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .lineLimit(1...3)
                                            .disabled(isSendingMessage)
                                            .background(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .fill(Color.gray.opacity(0.1))
                                            )
                                        
                                        // Modern send button
                                        Button {
                                            sendMessage()
                                        } label: {
                                            if isSendingMessage {
                                                ProgressView()
                                                    .scaleEffect(0.8)
                                                    .tint(.white)
                                            } else {
                                                Image(systemName: "paperplane.fill")
                                                    .font(.system(size: 16, weight: .semibold))
                                            }
                                        }
                                        .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSendingMessage)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            Circle()
                                                .fill(
                                                    messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSendingMessage
                                                        ? LinearGradient(colors: [.gray.opacity(0.4), .gray.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                                        : LinearGradient(colors: [Color(red: 0.0, green: 0.4, blue: 0.2), Color(red: 0.0, green: 0.5, blue: 0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                                )
                                                .shadow(
                                                    color: messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSendingMessage
                                                        ? .clear
                                                        : Color(red: 0.0, green: 0.4, blue: 0.2).opacity(0.3),
                                                    radius: 8,
                                                    x: 0,
                                                    y: 4
                                                )
                                        )
                                        .foregroundColor(.white)
                                        .scaleEffect(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSendingMessage ? 0.9 : 1.0)
                                        .animation(.easeInOut(duration: 0.2), value: messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                    }
                                }
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.white)
                                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
                                        .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
                                )
                            } else {
                                // Modern login prompt for unauthenticated users
                                VStack(spacing: 16) {
                                    HStack(spacing: 16) {
                                        Image(systemName: "lock.circle.fill")
                                            .font(.system(size: 32))
                                            .foregroundColor(.orange)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Login Required")
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                            Text("Sign in to message \(currentListing.user?.name ?? "the seller")")
                                                .font(.body)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                    }
                                    
                                    Button(action: {
                                        showingAuthentication = true
                                    }) {
                                        Text("Login to Send Message")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 16)
                                            .background(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .fill(
                                                        LinearGradient(
                                                            colors: [.orange, .orange.opacity(0.8)],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                                    .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                                            )
                                    }
                                }
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.white)
                                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
                                        .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    

                }
                .padding(.vertical, 20)
            }
        }
        .navigationTitle("Listing")
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
        .sheet(isPresented: $showingAuthentication) {
            AuthenticationView()
        }
    }
    
    private func sendMessage() {
        guard let listingId = currentListing.id,
              !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        // Check if user is authenticated
        guard authManager.isAuthenticated, authManager.authToken != nil else {
            showingAuthentication = true
            return
        }
        
        isSendingMessage = true
        
        viewModel.sendMessage(
            to: listingId,
            content: messageText.trimmingCharacters(in: .whitespacesAndNewlines),
            authToken: authManager.authToken,
            userId: authManager.currentUser?.id
        ) { success in
            DispatchQueue.main.async {
                self.isSendingMessage = false
                
                if success {
                    self.messageText = ""
                    self.showSuccessMessage = true
                    
                    // Refresh conversations so they appear in Messages tab
                    if let userId = self.authManager.currentUser?.id {
                        self.viewModel.fetchConversations(for: userId)
                    }
                } else {
                    // Could add error handling here
                    print("Failed to send message")
                }
            }
        }
    }
}
