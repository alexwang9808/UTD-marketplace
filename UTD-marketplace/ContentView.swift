
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: ListingViewModel
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var selectedTab = 0
    
    private let tabs = [
        TabItem(id: 0, title: "Listings", icon: "house"),
        TabItem(id: 1, title: "Messages", icon: "message"),
        TabItem(id: 2, title: "Profile", icon: "person")
    ]

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
            }
        }
        .onChange(of: authManager.currentUser) {
            if let userId = authManager.currentUser?.id {
                viewModel.fetchConversations(for: userId)
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
                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(selectedTab == tab.id ? .orange : .gray)
                            .scaleEffect(selectedTab == tab.id ? 1.1 : 1.0)
                            .animation(.linear(duration: 0.2), value: selectedTab)
                        
                        Text(tab.title)
                            .font(.caption)
                            .foregroundColor(selectedTab == tab.id ? .orange : .gray)
                            .fontWeight(selectedTab == tab.id ? .semibold : .regular)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
        .background(
            Rectangle()
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: -2)
        )
        .frame(height: 60)
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
