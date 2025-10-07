import SwiftUI

struct MessagesView: View {
    @EnvironmentObject var viewModel: ListingViewModel
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var showingAuthentication = false
    @State private var pressedConversationId: String? = nil
    @State private var readConversations: Set<String> = []

    var body: some View {
        NavigationView {
            ZStack {
                // Clean background
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                if authManager.isAuthenticated {
                    if viewModel.conversations.isEmpty {
                        modernEmptyStateWithHeader
                    } else {
                        modernConversationsListWithHeader
                    }
                } else {
                    modernAnonymousStateWithHeader
                }
            }
            .onAppear {
                if authManager.isAuthenticated, let userId = authManager.currentUser?.id {
                    viewModel.fetchConversations(for: userId)
                    loadReadConversations()
                }
            }
            .onChange(of: authManager.currentUser?.id) { oldValue, newValue in
                // Clear and reload read conversations when user changes
                readConversations.removeAll()
                if authManager.isAuthenticated, let userId = authManager.currentUser?.id {
                    viewModel.fetchConversations(for: userId)
                    loadReadConversations()
                }
            }
            .refreshable {
                if authManager.isAuthenticated, let userId = authManager.currentUser?.id {
                    viewModel.fetchConversations(for: userId)
                }
            }
        }
        .sheet(isPresented: $showingAuthentication) {
            AuthenticationView()
        }
    }
    
    // MARK: - Modern Empty State with Header
    private var modernEmptyStateWithHeader: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Title and orange bar that scroll with content
                VStack(spacing: 0) {
                    TitleView(title: "Messages")
                        .padding(.top, 10)
                    
                    LinearGradient(
                        colors: [Color.orange, Color.orange.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 4)
                    .padding(.top, 20)
                }
                
                VStack(spacing: 24) {
                    Spacer(minLength: 100)
                    
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
                    
                    Spacer(minLength: 100)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Modern Conversations List with Header
    private var modernConversationsListWithHeader: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Title and orange bar that scroll with content
                VStack(spacing: 0) {
                    TitleView(title: "Messages")
                        .padding(.top, 10)
                    
                    LinearGradient(
                        colors: [Color.orange, Color.orange.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 4)
                    .padding(.top, 20)
                }
                
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.conversations) { conversation in
                        NavigationLink {
                            ConversationDetailView(conversation: conversation)
                                .onAppear {
                                    markConversationAsRead(conversation.id)
                                }
                                .onDisappear {
                                    // Refresh conversations when returning from detail view
                                    if let userId = authManager.currentUser?.id {
                                        viewModel.fetchConversations(for: userId)
                                    }
                                }
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
    }
    
    // MARK: - Modern Conversation Card
    private func modernConversationCard(conversation: Conversation, isPressed: Bool = false) -> some View {
        return HStack(spacing: 16) {
            // Listing image
            if let imageUrl = conversation.listing.primaryImageUrl, let url = URL(string: "\(AppConfig.baseURL)\(imageUrl)") {
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
                    
                    // Unread indicator (gray dot if last message is not from current user and conversation hasn't been read)
                    if let currentUserId = authManager.currentUser?.id,
                       !conversation.lastMessage.isFromCurrentUser(currentUserId: currentUserId),
                       !readConversations.contains(conversation.id) {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 8, height: 8)
                    }
                    
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
    
    // MARK: - Modern Anonymous State with Header
    private var modernAnonymousStateWithHeader: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Title and orange bar that scroll with content
                VStack(spacing: 0) {
                    TitleView(title: "Messages")
                        .padding(.top, 10)
                    
                    LinearGradient(
                        colors: [Color.orange, Color.orange.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 4)
                    .padding(.top, 20)
                }
                
                VStack(spacing: 24) {
                    Spacer(minLength: 100)
                    
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
                    
                    Spacer(minLength: 100)
                }
                .frame(maxWidth: .infinity)
            }
        }
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
    
    // MARK: - Read Status Management
    private func loadReadConversations() {
        guard let userId = authManager.currentUser?.id else { return }
        let key = "readConversations_\(userId)"
        if let data = UserDefaults.standard.data(forKey: key),
           let conversations = try? JSONDecoder().decode(Set<String>.self, from: data) {
            readConversations = conversations
        }
    }
    
    private func saveReadConversations() {
        guard let userId = authManager.currentUser?.id else { return }
        let key = "readConversations_\(userId)"
        if let data = try? JSONEncoder().encode(readConversations) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    private func markConversationAsRead(_ conversationId: String) {
        readConversations.insert(conversationId)
        saveReadConversations()
    }
}
