import SwiftUI

struct ProfileView: View {
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)

                Text("Alex Wang")
                    .font(.title2)

                Button("Add Listing") {
                    showingAdd = true
                }
                .buttonStyle(.borderedProminent)
                .sheet(isPresented: $showingAdd) {
                    AddListingView()
                }

                Spacer()

                Button("Log Out") {
                    // your log-out logic
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Profile")
        }
    }
}
