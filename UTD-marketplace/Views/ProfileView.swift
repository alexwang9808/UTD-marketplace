import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var viewModel: ListingViewModel
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var profileImage: UIImage?
    @State private var currentUser: User?
    @State private var isUpdatingProfile = false
    @State private var showingEditProfile = false

    @State private var showingAddListing = false
    @State private var showingLogoutAlert = false
    @State private var showingSettingsDropdown = false
    @State private var selectedListingToEdit: Listing?
    @State private var timeSnapshot = Date()
    
    // Computed property to get current user's listings count
    private var myListingsCount: Int {
        guard let currentUserId = authManager.currentUser?.id else { return 0 }
        return viewModel.listings.filter { $0.userId == currentUserId }.count
    }
    
    // Computed property to get current user's listings
    private var myListings: [Listing] {
        guard let currentUserId = authManager.currentUser?.id else { return [] }
        return viewModel.listings.filter { $0.userId == currentUserId }
    }
    
    
    var body: some View {
        NavigationView {
            ZStack {
                // Clean background
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Title and orange bar that scroll with content
                        VStack(spacing: 0) {
                            // Title
                            TitleView(title: "Profile")
                                .padding(.top, 10)
                            
                            // Orange bar
                            LinearGradient(
                                colors: [Color.orange, Color.orange.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(height: 4)
                            .padding(.horizontal, 16)
                            .padding(.top, 20)
                            
                            // Settings and Add Listing buttons below orange bar
                            HStack {
                                Spacer()
                                
                                VStack(spacing: 12) {
                                    // Settings button
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
                                    
                                    // Add Listing button
                                    Button(action: {
                                        showingAddListing = true
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 25, weight: .medium))
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 15)
                        }
                        
                        VStack(spacing: 60) {
                            modernProfileHeader
                            myListingsSection
                            
                            // Spacer to push content up so cards almost touch nav bar
                            Spacer(minLength: 100)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .overlay(
                // Settings dropdown overlay
                settingsDropdownOverlay,
                alignment: .topTrailing
            )
            .onAppear {
                fetchUserFromBackend()
                timeSnapshot = Date() // Refresh time snapshot when view appears
            }
            .onChange(of: authManager.currentUser) {
                fetchCurrentUser()
            }
            .sheet(isPresented: $showingAddListing) {
                AddListingView()
            }
            .sheet(item: $selectedListingToEdit) { listing in
                EditListingView(listing: listing)
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
                
                // Statistics section
                Text("\(myListingsCount) active listing\(myListingsCount == 1 ? "" : "s")")
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding(.top, 4)
                
                // Bio section
                VStack(spacing: 8) {
                    if let bio = currentUser?.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.subheadline)
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
    
    // MARK: - My Listings Section
    private var myListingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !myListings.isEmpty {
                Spacer()
                
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 16) {
                    ForEach(myListings, id: \.id) { listing in
                        NavigationLink {
                            ListingDetailView(listing: listing)
                        } label: {
                            myListingCard(listing: listing)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
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
    
    // MARK: - My Listing Card
    @ViewBuilder
    private func myListingCard(listing: Listing) -> some View {
        VStack(spacing: 8) {
            // Listing image (matching ListingsView style)
            Group {
                if let imageUrl = listing.imageUrls.first, let url = URL(string: "http://localhost:3001\(imageUrl)") {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(1, contentMode: .fill)
                                .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 120)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        case .failure(_):
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red.opacity(0.1))
                                .aspectRatio(1, contentMode: .fill)
                                .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 120)
                                .clipped()
                                .overlay(
                                    VStack(spacing: 4) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                        Text("Failed to load")
                                            .font(.system(size: 8))
                                            .foregroundColor(.red)
                                    }
                                )
                        case .empty:
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.1))
                                .aspectRatio(1, contentMode: .fill)
                                .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 120)
                                .clipped()
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(0.8)
                                )
                        @unknown default:
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.1))
                                .aspectRatio(1, contentMode: .fill)
                                .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 120)
                                .clipped()
                        }
                    }
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(1, contentMode: .fill)
                        .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 120)
                        .clipped()
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                                .font(.title2)
                        )
                }
            }
            
            // Listing details with fixed height
            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 30) // Fixed height for title
                
                Text("$\(listing.priceString)")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                // Time ago and Click count
                HStack(spacing: 4) {
                    // Time ago
                    HStack(spacing: 2) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                        Text(listing.timeAgo(from: timeSnapshot))
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Click count
                    HStack(spacing: 2) {
                        Image(systemName: "eye.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                        Text("\(listing.clickCount ?? 0)")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 60) // Fixed height for details section
            
            // Manage button
            Button(action: {
                selectedListingToEdit = listing
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "pencil")
                    Text("Manage")
                }
                .font(.system(size: 10))
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color.orange)
                .cornerRadius(6)
            }
        }
        .frame(height: 220) // Adjusted total card height for proper image display
        .padding(8)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
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
                .padding(.top, 85) // Position below the buttons that are now below orange bar
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