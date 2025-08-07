import SwiftUI

struct ConversationDetailView: View {
    // Support both existing conversation and new conversation initiation
    let conversation: Conversation?
    let listing: Listing?
    let otherUser: User?
    
    @EnvironmentObject private var viewModel: ListingViewModel
    @EnvironmentObject private var authManager: AuthenticationManager

    @State private var newMessage = ""
    
    // Computed properties to handle both cases
    private var displayListing: Listing {
        return conversation?.listing ?? listing!
    }
    
    private var displayOtherUser: User {
        return conversation?.otherUser ?? otherUser!
    }
    
    private var displayMessages: [Message] {
        return conversation?.messages ?? []
    }
    
    private var listingId: Int {
        return conversation?.listingId ?? listing!.id!
    }
    
    // Initializers
    init(conversation: Conversation) {
        self.conversation = conversation
        self.listing = nil
        self.otherUser = nil
    }
    
    init(listing: Listing, otherUser: User) {
        self.conversation = nil
        self.listing = listing
        self.otherUser = otherUser
    }

    var body: some View {
        VStack(spacing: 0) {
            // Listing header
            HStack(spacing: 12) {
                if let imageUrl = displayListing.primaryImageUrl, let url = URL(string: "http://localhost:3001\(imageUrl)") {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayListing.title)
                        .font(.headline)
                        .lineLimit(1)
                    Text("$\(displayListing.priceString)")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            
            Divider()
            
            // Messages
            ScrollView {
                LazyVStack(spacing: 12) {
                    if displayMessages.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "message")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Text("No messages yet")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            Text("Start the conversation!")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 50)
                    } else {
                        ForEach(displayMessages.sorted { $0.createdAt < $1.createdAt }) { message in
                            HStack {
                                let isSender = message.isFromCurrentUser(currentUserId: authManager.currentUser?.id ?? -1)
                                if isSender { Spacer() }
                                
                                VStack(alignment: isSender ? .trailing : .leading, spacing: 4) {
                                    Text(message.content)
                                        .padding(12)
                                        .background(
                                            isSender
                                                ? Color(red: 0.0, green: 0.4, blue: 0.2).opacity(0.7)
                                                : Color.gray.opacity(0.3)
                                        )
                                        .foregroundColor(isSender ? .white : .primary)
                                        .cornerRadius(12)
                                    
                                    HStack(spacing: 4) {
                                        if let user = message.user {
                                            Text(user.name ?? user.email)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Text(formatTime(message.createdAt))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                if !isSender { Spacer() }
                            }
                        }
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Input bar
            HStack(spacing: 8) {
                TextField("Message…", text: $newMessage)
                    .textFieldStyle(.roundedBorder)
                
                Button("Send") {
                    let text = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else { return }
                    
                    viewModel.sendMessage(to: listingId, content: text, authToken: authManager.authToken) { success in
                        if success {
                            newMessage = ""
                        }
                    }
                }
                .disabled(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .navigationTitle(displayOtherUser.name ?? displayOtherUser.email)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatTime(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        
        guard let date = formatter.date(from: dateString) else {
            return ""
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .none
        displayFormatter.timeStyle = .short
        
        return displayFormatter.string(from: date)
    }
} 