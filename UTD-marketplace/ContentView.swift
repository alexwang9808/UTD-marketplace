import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            // First tab
            Text("First")
                .tabItem {
                    Image(systemName: "house")
                    Text("Listings")
                }

            // Second tab
            Text("Second")
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Messages")
                }

            // Third tab
            Text("Third")
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
        }
    }
}

#Preview {
    ContentView()
}
