import SwiftUI


struct ListingsView: View {
    // In a real app this would come from your view-model / API
    let sampleListings = ["MacBook Pro", "iPhone 15", "AirPods Pro"]
    
    var body: some View {
        NavigationStack {
            List(sampleListings, id: \.self) { item in
                Text(item)
            }
            .navigationTitle("Listings")
        }
    }
}

struct MessagesView: View {
    // Replace with your DM model
    let sampleDMs = [
        ("Alice", "Hey, is that desk still available?"),
        ("Bob", "Can you drop the price by $10?")
    ]

    var body: some View {
        NavigationStack {
            List(sampleDMs, id: \.0) { (sender, preview) in
                HStack {
                    Image(systemName: "person.circle")
                        .resizable()
                        .frame(width: 32, height: 32)
                    VStack(alignment: .leading) {
                        Text(sender).bold()
                        Text(preview).lineLimit(1)
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Messages")
        }
    }
}

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                Text("Alex Wang")
                    .font(.title2)
                Text("alexwang9808@gmail.com")
                    .foregroundColor(.secondary)
                Spacer()
                Button("Log Out") {
                    // your log-out action
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Profile")
        }
    }
}

// MARK: – Hooking them into the TabView

struct ContentView: View {
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
    }
}

#Preview {
    ContentView()
}
