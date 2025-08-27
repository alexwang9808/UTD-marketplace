import SwiftUI

struct MessagesView: View {
    @EnvironmentObject var viewModel: ListingViewModel
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var animateGradient = false

    var body: some View {
        NavigationView {
            ZStack {
                // Modern gradient background
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.05),
                        Color.purple.opacity(0.05),
                        Color.pink.opacity(0.05)
                    ],
                    startPoint: animateGradient ? .topLeading : .bottomTrailing,
                    endPoint: animateGradient ? .bottomTrailing : .topLeading
                )
                .ignoresSafeArea()
                .onAppear {
                    withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                        animateGradient.toggle()
                    }
                }
                
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
    }
    
    // MARK: - Modern Empty State
    private var modernEmptyState: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Fun message bubble illustration
            ZStack {
                // Background bubbles
                Circle()
                    .fill(LinearGradient(colors: [.blue.opacity(0.2), .purple.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 100, height: 100)
                    .offset(x: -20, y: -10)
                
                Circle()
                    .fill(LinearGradient(colors: [.pink.opacity(0.2), .orange.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 80, height: 80)
                    .offset(x: 25, y: 15)
                
                // Main message icon
                Image(systemName: "message.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .scaleEffect(animateGradient ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateGradient)
            
            VStack(spacing: 12) {
                Text("No conversations yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("Send a message to start a new conversation!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Modern Conversations List
    private var modernConversationsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.conversations) { conversation in
                    NavigationLink {
                        ConversationDetailView(conversation: conversation)
                    } label: {
                        modernConversationCard(conversation: conversation)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
        }
    }
    
    // MARK: - Modern Conversation Card
    private func modernConversationCard(conversation: Conversation) -> some View {
        HStack(spacing: 16) {
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
                    
                    Text(formatDate(conversation.lastMessage.createdAt))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                Text(conversation.lastMessage.content)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                .shadow(color: .black.opacity(0.04), radius: 1, x: 0, y: 1)
        )
        .scaleEffect(0.98)
        .animation(.easeInOut(duration: 0.1), value: false)
    }
    
    // MARK: - Modern Anonymous State
    private var modernAnonymousState: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Fun illustration for anonymous users
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.orange.opacity(0.2), .red.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 120, height: 120)
                    .offset(x: -15, y: -15)
                
                Image(systemName: "lock.circle.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .scaleEffect(animateGradient ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: animateGradient)
            
            VStack(spacing: 12) {
                Text("Sign in to view messages")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("Send a message on a listing to start a conversation!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
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
