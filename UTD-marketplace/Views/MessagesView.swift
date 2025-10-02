import SwiftUI

struct MessagesView: View {
    @EnvironmentObject var viewModel: ListingViewModel
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var showingAuthentication = false
    @State private var pressedConversationId: String? = nil

    var body: some View {
        NavigationView {
            ZStack {
                // Clean background
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Modern orange accent bar
                    LinearGradient(
                        colors: [Color.orange, Color.orange.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 4)
                    .edgesIgnoringSafeArea(.horizontal)
                    .padding(.top, -10)
                    
                    if authManager.isAuthenticated {
                        if viewModel.conversations.isEmpty {
                            modernEmptyState
                        } else {
                            modernConversationsList
                        }
                    } else {
                        modernAnonymousState
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    TitleView(title: "Messages")
                }
            }
            .onAppear {
                if authManager.isAuthenticated, let userId = authManager.currentUser?.id {
                    viewModel.fetchConversations(for: userId)
                }
            }
        }
        .sheet(isPresented: $showingAuthentication) {
            AuthenticationView()
        }
    }
    
    // MARK: - Modern Empty State
    private var modernEmptyState: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Simple message bubble illustration
            ZStack {
       
                
                Image(systemName: "message")
                    .font(.system(size: 65, weight: .regular))
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 12) {
                Text("No conversations yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
  
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.top, -40)
    }
    
    // MARK: - Modern Conversations List
    private var modernConversationsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.conversations) { conversation in
                    NavigationLink {
                        ConversationDetailView(conversation: conversation)
                    } label: {
                        modernConversationCard(conversation: conversation, isPressed: pressedConversationId == conversation.id)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                pressedConversationId = conversation.id
                            }
                            .onEnded { _ in
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                    pressedConversationId = nil
                                }
                            }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
        }
    }
    
    // MARK: - Modern Conversation Card
    private func modernConversationCard(conversation: Conversation, isPressed: Bool = false) -> some View {
        return HStack(spacing: 16) {
            // Listing image
            if let imageUrl = conversation.listing.primaryImageUrl, let url = URL(string: "http://localhost:3001\(imageUrl)") {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 20))
                                .foregroundColor(.gray)
                        )
                }
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    )
            }
            
            // Message content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("\(conversation.otherUser.name ?? conversation.otherUser.email)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(conversation.listing.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(conversation.lastMessage.timeAgo)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                Text(conversation.lastMessage.displayContent)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(20)
        .background(
            ZStack {
                // Base white rectangle background
                Rectangle()
                    .fill(Color.white)
                
                // Gray bubble overlay when pressed
                if isPressed {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.2))
                }
            }
        )
    }
    
    // MARK: - Modern Anonymous State
    private var modernAnonymousState: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 12) {
                Text("Sign in to view messages")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            Button(action: {
                showingAuthentication = true
            }) {
                Text("Sign in")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [.orange, .orange.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .orange.opacity(0.3), radius: 6, x: 0, y: 3)
                    )
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func formatDate(_ dateString: String) -> String {
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
