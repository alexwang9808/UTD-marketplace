
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: ListingViewModel
    @EnvironmentObject private var authManager: AuthenticationManager

    var body: some View {
        TabView {
            ListingsView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Listings")
                }

            MessagesView()
                .tabItem {
                    Image(systemName: "message")
                    Text("Messages")
                }

            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
        }
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
}

#Preview {
    ContentView()
        .environmentObject(ListingViewModel())
        .environmentObject(AuthenticationManager())
}
