import SwiftUI
import PhotosUI

struct ProfileView: View {
    @State private var showingAdd = false
    @State private var showingImagePicker = false
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var profileImage: UIImage? = nil

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
                    Group {
                        if let image = profileImage {
                            Image(uiImage: image)
                                .resizable()
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                    .onTapGesture {
                        showingImagePicker = true
                    }
                    
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
                .photosPicker(isPresented: $showingImagePicker, selection: $selectedItem)
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
    }
}
