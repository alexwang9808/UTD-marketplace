import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @EnvironmentObject private var viewModel: ListingViewModel
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var bio: String = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var isUpdating = false
    @State private var animateGradient = false
    
    let user: User
    
    var body: some View {
        NavigationStack {
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
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Picture Section
                        profilePictureSection
                        
                        // Form Section
                        formSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isUpdating)
                }
            }
            .onAppear {
                setupInitialValues()
            }
            .onChange(of: selectedItem) {
                Task {
                    if let data = try? await selectedItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        profileImage = uiImage
                    }
                }
            }
        }
    }
    
    // MARK: - Profile Picture Section
    private var profilePictureSection: some View {
        VStack(spacing: 16) {
            Text("Profile Picture")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            PhotosPicker(selection: $selectedItem, matching: .images) {
                ZStack {
                    if let profileImage = profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } else if let imageUrl = user.imageUrl,
                              let url = URL(string: "http://localhost:3001\(imageUrl)") {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(0.8)
                                )
                        }
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 120, height: 120)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                            )
                    }
                    
                    // Camera overlay
                    Circle()
                        .fill(Color.black.opacity(0.7))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .semibold))
                        )
                        .offset(x: 35, y: 35)
                }
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: 20) {
            // Name Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                TextField("Enter your name", text: $name)
                    .font(.body)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1))
                    )
            }
            
            // Bio Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Bio")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                TextField("Tell us about yourself...", text: $bio, axis: .vertical)
                    .font(.body)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .lineLimit(4...8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1))
                    )
                
                Text("\(bio.count)/200")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Functions
    private func setupInitialValues() {
        name = user.name ?? ""
        bio = user.bio ?? ""
    }
    
    private func saveProfile() {
        guard let userId = user.id else {
            print("No user ID available")
            return
        }
        
        isUpdating = true
        
        // Limit bio to 200 characters
        let trimmedBio = String(bio.prefix(200))
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Create multipart form data
        let url = URL(string: "http://localhost:3001/users/\(userId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Add auth token if available
        if let authToken = authManager.authToken {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        
        var body = Data()
        
        // Add form fields
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"email\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(user.email)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"name\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(trimmedName)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"bio\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(trimmedBio)\r\n".data(using: .utf8)!)
        
        // Add image if provided
        if let profileImage = profileImage,
           let imageData = profileImage.jpegData(compressionQuality: 0.8) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"image\"; filename=\"profile.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isUpdating = false
                
                if let error = error {
                    print("Error updating profile: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200,
                   let data = data {
                    
                    do {
                        let updatedUser = try JSONDecoder().decode(User.self, from: data)
                        
                        // Update AuthManager with new data
                        if let authUser = self.authManager.currentUser {
                            let updatedAuthUser = AuthUser(
                                id: authUser.id,
                                email: authUser.email,
                                name: updatedUser.name ?? authUser.name,
                                imageUrl: updatedUser.imageUrl ?? authUser.imageUrl
                            )
                            self.authManager.currentUser = updatedAuthUser
                            
                            // Update UserDefaults
                            if let userData = try? JSONEncoder().encode(updatedAuthUser) {
                                UserDefaults.standard.set(userData, forKey: "current_user_data")
                            }
                        }
                        
                        self.dismiss()
                    } catch {
                        print("Error decoding updated user: \(error)")
                    }
                } else {
                    print("Failed to update profile")
                }
            }
        }.resume()
    }
}

#Preview {
    EditProfileView(user: User(id: 1, email: "test@example.com", name: "John Doe", imageUrl: nil, bio: "This is a sample bio"))
        .environmentObject(ListingViewModel())
        .environmentObject(AuthenticationManager())
}
