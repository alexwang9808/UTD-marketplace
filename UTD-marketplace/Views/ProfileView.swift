import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject private var viewModel: ListingViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Profile header
                VStack(spacing: 16) {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                        )
                    
                    Text("User \(viewModel.currentUserId)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("user\(viewModel.currentUserId)@utdallas.edu")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    viewModel.currentUserId == userId 
                                        ? Color.blue 
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
                
                Spacer()
                
                // Profile options
                VStack(spacing: 0) {
                    ProfileRow(icon: "person.circle", title: "Edit Profile", action: {})
                    ProfileRow(icon: "heart", title: "Favorites", action: {})
                    ProfileRow(icon: "clock", title: "Order History", action: {})
                    ProfileRow(icon: "gear", title: "Settings", action: {})
                    ProfileRow(icon: "questionmark.circle", title: "Help & Support", action: {})
                }
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Profile")
        }
    }
}

struct ProfileRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
}
