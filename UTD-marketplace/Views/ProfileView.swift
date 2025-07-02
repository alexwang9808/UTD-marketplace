import SwiftUI

struct ProfileView: View {
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ✅ Clean, straight black line under nav bar
                Rectangle()
                    .fill(Color.orange)
                    .frame(height: 4)
                    .edgesIgnoringSafeArea(.horizontal)
                    .padding(.top, -10)
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
            
            .toolbar {
                ToolbarItem(placement: .principal) {
                    TitleView(title: "Profile")
                }
            }

            }


        }
    }
}
