
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ListingViewModel()

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
        .environmentObject(viewModel)
        .onAppear {
            viewModel.fetchListings()
        }
    }
}

#Preview {
    ContentView()
}
