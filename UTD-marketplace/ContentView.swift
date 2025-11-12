
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: ListingViewModel
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var selectedTab = 0
    @State private var readConversations: Set<String> = []
    
    private let tabs = [
        TabItem(id: 0, title: "Listings", icon: "house"),
        TabItem(id: 1, title: "Messages", icon: "message"),
        TabItem(id: 2, title: "Profile", icon: "person")
    ]
    
    // Computed property for unread message count
    private var unreadCount: Int {
        guard let currentUserId = authManager.currentUser?.id else { return 0 }
        return viewModel.conversations.filter { conversation in
            !conversation.lastMessage.isFromCurrentUser(currentUserId: currentUserId) &&
            !readConversations.contains(conversation.id)
        }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom animated content view with swipe support
            ZStack {
                // Keep all views in memory but hide non-selected ones
                ListingsView()
                    .opacity(selectedTab == 0 ? 1 : 0)
                    .animation(.linear(duration: 0.1), value: selectedTab)
                
                MessagesView()
                    .opacity(selectedTab == 1 ? 1 : 0)
                    .animation(.linear(duration: 0.1), value: selectedTab)
                
                ProfileView()
                    .opacity(selectedTab == 2 ? 1 : 0)
                    .animation(.linear(duration: 0.1), value: selectedTab)
            }
            .gesture(
                DragGesture()
                    .onEnded { value in
                        let threshold: CGFloat = 50
                        let horizontalMovement = value.translation.width
                        
                        if horizontalMovement > threshold && selectedTab > 0 {
                            // Swipe right - go to previous tab
                            withAnimation(.linear(duration: 0.1)) {
                                selectedTab -= 1
                            }
                        } else if horizontalMovement < -threshold && selectedTab < 2 {
                            // Swipe left - go to next tab
                            withAnimation(.linear(duration: 0.1)) {
                                selectedTab += 1
                            }
                        }
                    }
            )
            
            // Custom tab bar
            customTabBar
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            viewModel.fetchListings()
            if let userId = authManager.currentUser?.id {
                viewModel.fetchConversations(for: userId)
                loadReadConversations()
            }
        }
        .onChange(of: authManager.currentUser) {
            readConversations.removeAll()
            if let userId = authManager.currentUser?.id {
                viewModel.fetchConversations(for: userId)
                loadReadConversations()
            }
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            // Mark conversations as read when entering Messages tab
            if newValue == 1, let currentUserId = authManager.currentUser?.id {
                for conversation in viewModel.conversations {
                    if !conversation.lastMessage.isFromCurrentUser(currentUserId: currentUserId) {
                        readConversations.insert(conversation.id)
                    }
                }
                saveReadConversations()
            }
        }
    }
    
    // MARK: - Custom Tab Bar
    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.id) { tab in
                Button(action: {
                    withAnimation(.linear(duration: 0.1)) {
                        selectedTab = tab.id
                    }
                }) {
                    VStack(spacing: 4) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(selectedTab == tab.id ? .orange : .gray)
                                .scaleEffect(selectedTab == tab.id ? 1.1 : 1.0)
                                .animation(.linear(duration: 0.2), value: selectedTab)
                            
                            // Badge for Messages tab
                            if tab.id == 1 && unreadCount > 0 {
                                Text("\(unreadCount)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .frame(minWidth: 16, minHeight: 16)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .offset(x: 10, y: -8)
                            }
                        }
                        
                        Text(tab.title)
                            .font(.caption)
                            .foregroundColor(selectedTab == tab.id ? .orange : .gray)
                            .fontWeight(selectedTab == tab.id ? .semibold : .regular)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .background(
            Rectangle()
                .fill(Color(UIColor.systemBackground))
        )
        .frame(height: 60)
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
}

// MARK: - Supporting Types
struct TabItem {
    let id: Int
    let title: String
    let icon: String
}

#Preview {
    ContentView()
        .environmentObject(ListingViewModel())
        .environmentObject(AuthenticationManager())
}
