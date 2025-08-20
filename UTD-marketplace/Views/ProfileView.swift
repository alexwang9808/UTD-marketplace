import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject private var viewModel: ListingViewModel
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var selectedItem: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var currentUser: User?
    @State private var isUpdatingProfile = false
    @State private var showingPhotoPicker = false
    @State private var showingAddListing = false
    @State private var showingMyListings = false
    @State private var showingLogoutAlert = false
    @State private var animateGradient = false
    
    // Computed property to get current user's listings count
    private var myListingsCount: Int {
        guard let currentUserId = authManager.currentUser?.id else { return 0 }
        return viewModel.listings.filter { $0.userId == currentUserId }.count
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Modern gradient background
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.03),
                        Color.purple.opacity(0.03),
                        Color.pink.opacity(0.03)
                    ],
                    startPoint: animateGradient ? .topLeading : .bottomTrailing,
                    endPoint: animateGradient ? .bottomTrailing : .topLeading
                )
                .ignoresSafeArea()
                .onAppear {
                    withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                        animateGradient.toggle()
                    }
                }
                
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
            .toolbar {
                ToolbarItem(placement: .principal) {
                    TitleView(title: "Profile")
                }
            }
            .onAppear {
                fetchCurrentUser()
            }
            .onChange(of: authManager.currentUser) {
                fetchCurrentUser()
            }
            .onChange(of: selectedItem) {
                Task {
                    if let data = try? await selectedItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        profileImage = uiImage
                        await updateProfileImage(imageData: data)
                    }
                }
            }
            .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedItem, matching: .images)
            .sheet(isPresented: $showingAddListing) {
                AddListingView()
            }
            .sheet(isPresented: $showingMyListings) {
                MyListingsView()
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
            VStack(spacing: 8) {
                Text(currentUser?.name ?? "Unknown User")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
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
        Button(action: {
            showingPhotoPicker = true
        }) {
            ZStack {
                // Profile image
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
                .frame(width: 120, height: 120)
                .clipShape(Circle())
                .shadow(color: Color(red: 0.0, green: 0.4, blue: 0.2).opacity(0.3), radius: 12, x: 0, y: 6)
                
                // Modern camera overlay
                Circle()
                    .fill(Color.black.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "camera.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .semibold))
                    )
                    .offset(x: 35, y: 35)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .scaleEffect(isUpdatingProfile ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isUpdatingProfile)
        }
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
            
            // My Listings Button
            modernMyListingsButton
            
            // Logout Button
            if authManager.isAuthenticated {
                modernActionButton(
                    icon: "power",
                    title: "Logout",
                    subtitle: "Sign out of your account",
                    color: .red,
                    action: { showingLogoutAlert = true }
                )
            }
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
                imageUrl: authUser.imageUrl
            )
        } else {
            self.currentUser = nil
        }
        self.profileImage = nil // Reset local image
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
                                imageUrl: imageUrl
                            )
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
}

#Preview {
    ProfileView()
        .environmentObject(ListingViewModel())
        .environmentObject(AuthenticationManager())
}