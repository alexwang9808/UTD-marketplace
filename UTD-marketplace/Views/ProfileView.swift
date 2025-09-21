import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var viewModel: ListingViewModel
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var profileImage: UIImage?
    @State private var currentUser: User?
    @State private var isUpdatingProfile = false
    @State private var showingEditProfile = false

    @State private var showingAddListing = false
    @State private var showingMyListings = false
    @State private var showingLogoutAlert = false
    @State private var showingSettingsDropdown = false
    
    // Computed property to get current user's listings count
    private var myListingsCount: Int {
        guard let currentUserId = authManager.currentUser?.id else { return 0 }
        return viewModel.listings.filter { $0.userId == currentUserId }.count
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Clean background
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
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
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            modernProfileHeader
                            modernActionButtons
                        }
                        .padding(.top, 20)
                    }
                }
            }
            .overlay(
                // Floating settings button overlay
                settingsButtonOverlay,
                alignment: .topTrailing
            )
            .overlay(
                // Settings dropdown overlay
                settingsDropdownOverlay,
                alignment: .topTrailing
            )
            .toolbar {
                ToolbarItem(placement: .principal) {
                    TitleView(title: "Profile")
                }
            }
            .onAppear {
                fetchUserFromBackend()
            }
            .onChange(of: authManager.currentUser) {
                fetchCurrentUser()
            }
            .sheet(isPresented: $showingAddListing) {
                AddListingView()
            }
            .sheet(isPresented: $showingMyListings) {
                VStack(spacing: 0) {
                    // Simple X button at the top
                    HStack {
                        Button(action: {
                            showingMyListings = false
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.black)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(UIColor.systemBackground))
                    
                    MyListingsView()
                }
                .presentationDragIndicator(.hidden)
                .presentationDetents([.large])
                .presentationBackgroundInteraction(.disabled)
            }
            .sheet(isPresented: $showingEditProfile) {
                if let user = currentUser {
                    EditProfileView(user: user)
                } else {
                    // Show sign-in prompt with X button when not authenticated
                    NavigationStack {
                        Color(UIColor.systemBackground)
                            .ignoresSafeArea()
                            .navigationTitle("")
                            .navigationBarTitleDisplayMode(.inline)
                    }
                    .presentationDragIndicator(.hidden)
                    .presentationDetents([.large])
                    .presentationBackgroundInteraction(.disabled)
                }
            }
            .onChange(of: showingEditProfile) { 
                // Refresh user data when edit profile sheet is dismissed
                if !showingEditProfile {
                    fetchUserFromBackend()
                }
            }
            .alert("Logout", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    authManager.logout()
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
        }
    }
    
    // MARK: - Modern Profile Header
    private var modernProfileHeader: some View {
        VStack(spacing: 20) {
            // Profile picture with modern styling
            modernProfilePicture
            
            // User info
            VStack(spacing: 12) {
                Text(currentUser?.name ?? "Unknown User")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                // Bio section
                VStack(spacing: 8) {
                    if let bio = currentUser?.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.body)
                            .foregroundColor(.gray)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            
                    } 
                }
                
                if isUpdatingProfile {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Updating profile...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }
    
    private var modernProfilePicture: some View {
        // Profile image (display only)
        Group {
            if let profileImage = profileImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .scaledToFill()
            } else if let user = currentUser, 
                      let imageUrl = user.imageUrl,
                      let url = URL(string: "http://localhost:3001\(imageUrl)") {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.0, green: 0.4, blue: 0.2).opacity(0.2), Color(red: 0.0, green: 0.4, blue: 0.2).opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            ProgressView()
                                .scaleEffect(1.2)
                        )
                }
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.0, green: 0.4, blue: 0.2).opacity(0.2), Color(red: 0.0, green: 0.4, blue: 0.2).opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Color(red: 0.0, green: 0.4, blue: 0.2))
                    )
            }
        }
        .frame(width: 100, height: 100)
        .clipShape(Circle())
        .scaleEffect(isUpdatingProfile ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isUpdatingProfile)
    }
    
    // MARK: - Modern Action Buttons
    private var modernActionButtons: some View {
        VStack(spacing: 16) {
            // Add Listing Button
            modernActionButton(
                icon: "plus.circle.fill",
                title: "Add Listing",
                subtitle: "Create a new listing",
                color: .orange,
                action: { showingAddListing = true }
            )
        }
        .padding(.horizontal, 16)
    }
    
    private func modernActionButton(
        icon: String,
        title: String,
        subtitle: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
                    .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var modernMyListingsButton: some View {
        Button(action: {
            showingMyListings = true
        }) {
            HStack(spacing: 16) {
                // Icon with count
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.0, green: 0.4, blue: 0.2), Color(red: 0.0, green: 0.5, blue: 0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("My Listings")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        // Count badge
                        Text("\(myListingsCount)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(red: 0.0, green: 0.4, blue: 0.2))
                            )
                    }
                    
                    Text(myListingsCount == 0 ? "No listings yet" : "Manage your \(myListingsCount) listing\(myListingsCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
                    .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func fetchCurrentUser() {
        // Use the authenticated user's information
        if let authUser = authManager.currentUser {
            // Convert AuthUser to User for the profile display
            self.currentUser = User(
                id: authUser.id,
                email: authUser.email,
                name: authUser.name,
                imageUrl: authUser.imageUrl,
                bio: nil // AuthUser doesn't have bio, so set to nil
            )
        } else {
            self.currentUser = nil
        }
        self.profileImage = nil // Reset local image
    }
    
    private func fetchUserFromBackend() {
        guard let userId = authManager.currentUser?.id,
              let authToken = authManager.authToken else {
            fetchCurrentUser() // Fallback to current method
            return
        }
        
        let url = URL(string: "http://localhost:3001/users/\(userId)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error fetching user: \(error.localizedDescription)")
                    self.fetchCurrentUser() // Fallback
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200,
                   let data = data {
                    
                    do {
                        let user = try JSONDecoder().decode(User.self, from: data)
                        self.currentUser = user
                    } catch {
                        print("Error decoding user: \(error)")
                        self.fetchCurrentUser() // Fallback
                    }
                } else {
                    print("Failed to fetch user from backend")
                    self.fetchCurrentUser() // Fallback
                }
            }
        }.resume()
    }
    
    private func updateProfileImage(imageData: Data) async {
        isUpdatingProfile = true
        
        guard let currentUserId = authManager.currentUser?.id,
              let url = URL(string: "http://localhost:3001/users/\(currentUserId)") else {
            isUpdatingProfile = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        
        // Add authentication header
        if let authToken = authManager.authToken {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        
        // Create multipart form data using string concatenation
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var bodyString = ""
        
        // Add existing user data
        if let user = currentUser {
            bodyString += "--\(boundary)\r\n"
            bodyString += "Content-Disposition: form-data; name=\"email\"\r\n\r\n"
            bodyString += "\(user.email)\r\n"
            
            if let name = user.name {
                bodyString += "--\(boundary)\r\n"
                bodyString += "Content-Disposition: form-data; name=\"name\"\r\n\r\n"
                bodyString += "\(name)\r\n"
            }
        }
        
        // Add image header
        bodyString += "--\(boundary)\r\n"
        bodyString += "Content-Disposition: form-data; name=\"image\"; filename=\"profile.jpg\"\r\n"
        bodyString += "Content-Type: image/jpeg\r\n\r\n"
        
        var bodyData = Data(bodyString.utf8)
        bodyData.append(imageData)
        bodyData.append(Data("\r\n--\(boundary)--\r\n".utf8))
        
        request.httpBody = bodyData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let imageUrl = json["imageUrl"] as? String {
                    DispatchQueue.main.async {
                        self.isUpdatingProfile = false
                        // Update the current user's image URL
                        if let user = self.currentUser {
                            self.currentUser = User(
                                id: user.id,
                                email: user.email,
                                name: user.name,
                                imageUrl: imageUrl,
                                bio: user.bio // Preserve existing bio
                            )
                        }
                        
                        // Also update the AuthManager's currentUser to keep it in sync
                        if let authUser = self.authManager.currentUser {
                            let updatedAuthUser = AuthUser(
                                id: authUser.id,
                                email: authUser.email,
                                name: authUser.name,
                                imageUrl: imageUrl
                            )
                            self.authManager.currentUser = updatedAuthUser
                            
                            // Update UserDefaults with the new user data
                            if let userData = try? JSONEncoder().encode(updatedAuthUser) {
                                UserDefaults.standard.set(userData, forKey: "current_user_data")
                            }
                        }
                        
                        print("Profile image updated successfully")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.isUpdatingProfile = false
                    print("Failed to update profile image")
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isUpdatingProfile = false
                print("Error updating profile image: \(error)")
            }
        }
    }
    
    // MARK: - Settings Button Overlay
    @ViewBuilder
    private var settingsButtonOverlay: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                showingSettingsDropdown.toggle()
            }
        }) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 25, weight: .medium))
                .foregroundColor(.gray)
                .rotationEffect(.degrees(showingSettingsDropdown ? 45 : 0))
                .animation(.easeInOut(duration: 0.2), value: showingSettingsDropdown)
        }
        .padding(.trailing, 16)
        .padding(.top, 8)
    }
    
    // MARK: - Settings Dropdown Overlay
    @ViewBuilder
    private var settingsDropdownOverlay: some View {
        if showingSettingsDropdown {
            ZStack(alignment: .topTrailing) {
                // Invisible background to catch taps outside
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showingSettingsDropdown = false
                        }
                    }
                    .ignoresSafeArea()
                
                // Dropdown menu
                VStack(spacing: 0) {
                    // Edit profile
                    Button(action: {
                        showingEditProfile = true
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showingSettingsDropdown = false
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "person.circle")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.green)
                                .frame(width: 20)
                            Text("Edit profile")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    
                    Divider()
                        .padding(.horizontal, 16)

                    Button(action: {
                        showingMyListings = true
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showingSettingsDropdown = false
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "list.bullet.rectangle")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.orange)
                                .frame(width: 20)
                            Text("My Listings")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    
                    Divider()
                        .padding(.horizontal, 16)
                    
                    // Contact
                    Button(action: {
                        // Contact action - placeholder
                        print("Contact tapped")
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showingSettingsDropdown = false
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "envelope")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            Text("Contact")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    
                    Divider()
                        .padding(.horizontal, 16)
                    
                    // Logout
                    Button(action: {
                        showingLogoutAlert = true
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showingSettingsDropdown = false
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.right.square")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.red)
                                .frame(width: 20)
                            Text("Log out")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                )
                .frame(width: 180)
                .padding(.trailing, 16)
                .padding(.top, 45) // Position below the settings button
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .scale(scale: 0.9).combined(with: .opacity)
                ))
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(ListingViewModel())
        .environmentObject(AuthenticationManager())
}