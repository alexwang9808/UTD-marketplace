import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject private var viewModel: ListingViewModel
    @State private var selectedItem: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var currentUser: User?
    @State private var isUpdatingProfile = false
    @State private var showingPhotoPicker = false
    @State private var showingAddListing = false
    @State private var showingMyListings = false
    
    // Computed property to get current user's listings count
    private var myListingsCount: Int {
        viewModel.listings.filter { $0.userId == viewModel.currentUserId }.count
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Orange line right below navigation bar
                Rectangle()
                    .fill(Color.orange)
                    .frame(height: 4)
                    .edgesIgnoringSafeArea(.horizontal)
                    .padding(.top, -10)
                
                ScrollView {
                VStack(spacing: 20) {
                // Profile header
                VStack(spacing: 16) {
                    // Profile picture with tap gesture
                    Button(action: {
                        showingPhotoPicker = true
                    }) {
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
                                        .fill(Color(red: 0.0, green: 0.4, blue: 0.2).opacity(0.2))
                                        .overlay(
                                            ProgressView()
                                        )
                                }
                            } else {
                                Circle()
                                    .fill(Color(red: 0.0, green: 0.4, blue: 0.2).opacity(0.2))
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(Color(red: 0.0, green: 0.4, blue: 0.2))
                                    )
                            }
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color(red: 0.0, green: 0.4, blue: 0.2), lineWidth: 3)
                        )
                        .overlay(
                            // Camera icon overlay
                            Circle()
                                .fill(Color.black.opacity(0.6))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .foregroundColor(.white)
                                        .font(.system(size: 12))
                                )
                                .offset(x: 25, y: 25)
                        )
                        .scaleEffect(isUpdatingProfile ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: isUpdatingProfile)
                    }
                    
                    Text(currentUser?.name ?? "User \(viewModel.currentUserId)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(currentUser?.email ?? "user\(viewModel.currentUserId)@utdallas.edu")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if isUpdatingProfile {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Updating profile...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top)
                
                // Development Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Development Tools")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 8) {
                        Text("Switch User (for testing)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            ForEach(1...4, id: \.self) { userId in
                                Button("User \(userId)") {
                                    viewModel.switchUser(to: userId)
                                    fetchCurrentUser()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    viewModel.currentUserId == userId 
                                        ? Color(red: 0.0, green: 0.4, blue: 0.2) 
                                        : Color.gray.opacity(0.2)
                                )
                                .foregroundColor(
                                    viewModel.currentUserId == userId 
                                        ? .white 
                                        : .primary
                                )
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(.horizontal)
                
                // Add Listing Button
                Button(action: {
                    showingAddListing = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("Add Listing")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // My Listings Button
                Button(action: {
                    showingMyListings = true
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "list.bullet.rectangle")
                                    .font(.title2)
                                Text("My Listings")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("\(myListingsCount)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.3))
                                    .cornerRadius(12)
                            }
                            
                            Text(myListingsCount == 0 ? "No listings yet" : "Manage your \(myListingsCount) listing\(myListingsCount == 1 ? "" : "s")")
                                .font(.subheadline)
                                .foregroundColor(Color(red: 0.0, green: 0.4, blue: 0.2).opacity(0.8))
                        }
                        
                        Image(systemName: "chevron.right")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(Color(red: 0.0, green: 0.4, blue: 0.2))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 0.0, green: 0.4, blue: 0.2).opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 0.0, green: 0.4, blue: 0.2).opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(.horizontal)
                
                Spacer()
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
        }
    }
    
    private func fetchCurrentUser() {
        guard let url = URL(string: "http://localhost:3001/users") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else { return }
            
            do {
                let users = try JSONDecoder().decode([User].self, from: data)
                DispatchQueue.main.async {
                    self.currentUser = users.first { $0.id == viewModel.currentUserId }
                    self.profileImage = nil // Reset local image when switching users
                }
            } catch {
                print("Failed to fetch users: \(error)")
            }
        }.resume()
    }
    
    private func updateProfileImage(imageData: Data) async {
        isUpdatingProfile = true
        
        guard let url = URL(string: "http://localhost:3001/users/\(viewModel.currentUserId)") else {
            isUpdatingProfile = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        
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
        
        // Combine string data with image data
        var body = Data()
        body.append(bodyString.data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                if let updatedUser = try? JSONDecoder().decode(User.self, from: data) {
                    DispatchQueue.main.async {
                        self.currentUser = updatedUser
                        self.isUpdatingProfile = false
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
