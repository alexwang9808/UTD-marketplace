import SwiftUI
import PhotosUI

struct AddListingView: View {
    @EnvironmentObject private var viewModel: ListingViewModel
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var title       = ""
    @State private var location    = "University Village"
    @State private var price       = ""
    @State private var priceDisplay = ""
    @State private var description = ""
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var imageDataArray: [Data] = []
    @State private var showPriceError = false
    @State private var showingAuthentication = false
    @State private var animateGradient = false
    @State private var showingLocationDropdown = false

    // Dropdown options
    private let locations = [
            "University Village",
            "Canyon Creek",
            "Northside",
            "Vega Hall",
            "Andromeda Hall",
            "Capella Hall",
            "Helix Hall",
            "Sirius Hall",
            "Other"
        ]

    var body: some View {
        NavigationStack {
            if authManager.isAuthenticated {
                authenticatedView
            } else {
                // Unauthenticated view inline
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
                    
                    VStack(spacing: 30) {
                        Spacer()
                            VStack(spacing: 8) {
                                Text("Sign In Required")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            
                            }
   
                        
                        Button(action: {
                            showingAuthentication = true
                        }) {
                            Text("Sign In to Create Listing")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            LinearGradient(
                                                colors: [.orange, .orange.opacity(0.8)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                                )
                        }
                        .padding(.horizontal, 40)
                        
                        Spacer()
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAuthentication) {
            AuthenticationView()
        }
        .task(id: photoItems) {
            // Only load new items that aren't already in imageDataArray
            let currentCount = imageDataArray.count
            let newItemsCount = photoItems.count
            
            if newItemsCount > currentCount {
                // Load only the new items
                for i in currentCount..<newItemsCount {
                    if let data = try? await photoItems[i].loadTransferable(type: Data.self) {
                        imageDataArray.append(data)
                    }
                }
            } else if newItemsCount < currentCount {
                // This case is handled by manual removal in the button action
                // No need to do anything here
            } else if newItemsCount == 0 {
                // Clear all if no items
                imageDataArray.removeAll()
            }
        }
    }
    
    private var authenticatedView: some View {
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
                    // Photos Section Card
                    modernPhotosSection()
                    
                    // Details Section Card
                    modernDetailsSection()
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
        }
        .overlay(
            // Custom location dropdown overlay
            locationDropdownOverlay(),
            alignment: .center
        )
           // .navigationTitle("New Listing")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        guard !imageDataArray.isEmpty, !title.isEmpty, !price.isEmpty, !description.isEmpty else { return }
                        viewModel.addListing(
                            title: title,
                            price: price,
                            description: description,
                            location: location,
                            imageDataArray: imageDataArray,
                            authToken: authManager.authToken
                        ) { success in
                            print("Add listing success: \(success)")
                            if success { dismiss() }
                            else { print("Failed to add listing") }
                        }
                    }
                    .disabled(
                        title.isEmpty ||
                        price.isEmpty ||
                        description.isEmpty ||
                        imageDataArray.isEmpty
                    )
                    .foregroundColor(
                        (title.isEmpty || price.isEmpty || description.isEmpty || imageDataArray.isEmpty) 
                        ? .gray : Color(red: 0.0, green: 0.4, blue: 0.2)
                    )
                }
            }
        }
    
    // MARK: - Modern Photos Section
    private func modernPhotosSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Photos")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // Photo picker button
            PhotosPicker(
                selection: $photoItems,
                maxSelectionCount: 5,
                matching: .images,
                photoLibrary: .shared()
            ) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Choose Photos")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Select up to 5 photos")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            
            // Photo preview
            if !imageDataArray.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("\(imageDataArray.count) of 5 photos selected")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(imageDataArray.enumerated()), id: \.offset) { index, data in
                                if let ui = UIImage(data: data) {
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: ui)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        
                                        Button(action: {
                                            // Remove from both arrays simultaneously to avoid rebuild
                                            imageDataArray.remove(at: index)
                                            let _ = photoItems.remove(at: index)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(.white)
                                                .background(
                                                    Circle()
                                                        .fill(Color.black.opacity(0.7))
                                                        .frame(width: 24, height: 24)
                                                )
                                        }
                                        .offset(x: 6, y: -6)
                                    }
                                    .frame(width: 112, height: 112) // Extra space for button
                                    .clipped()
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .stroke(Color.orange, lineWidth: 2)
             
        }
    }
    
    // MARK: - Modern Details Section
    private func modernDetailsSection() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Details")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                // Title field
                modernTextField(
                    title: "Title",
                    text: $title,
                    placeholder: "Enter listing title"
                )
                
                // Price field
                VStack(alignment: .leading, spacing: 8) {
                    modernTextField(
                        title: "Price",
                        text: Binding(
                            get: { price },
                            set: { newValue in
                                let filtered = newValue.filter { $0.isNumber }
                                showPriceError = (filtered != newValue)
                                price = filtered
                            }
                        ),
                        placeholder: "Enter price",
                        keyboardType: .numberPad
                    )
                    
                    if showPriceError {
                        Text("Numbers only")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.leading, 4)
                    }
                }
                
                // Custom location dropdown button
                modernLocationDropdown()
                
                // Description field
                modernTextEditor(
                    title: "Description",
                    text: $description,
                    placeholder: "Describe your item..."
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .stroke(Color.orange, lineWidth: 2)
         
        )
    }
    
    // MARK: - Modern Location Dropdown
    private func modernLocationDropdown() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Location")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showingLocationDropdown = true
                }
            }) {
                HStack(spacing: 12) {
                    Text(location)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(showingLocationDropdown ? 180 : 0))
                        .animation(.easeInOut(duration: 0.2), value: showingLocationDropdown)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    // MARK: - Custom Location Dropdown Overlay
    @ViewBuilder
    private func locationDropdownOverlay() -> some View {
        if showingLocationDropdown {
            ZStack {
                // Invisible background to catch taps outside
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showingLocationDropdown = false
                        }
                    }
                    .ignoresSafeArea()
                
                // Dropdown content
                CustomLocationDropdown(
                    locations: locations,
                    currentSelection: $location,
                    isPresented: $showingLocationDropdown
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                    removal: .scale(scale: 0.9).combined(with: .opacity)
                ))
            }
            .zIndex(1000)
        }
    }
    
    // MARK: - Helper Functions
    private func modernTextField(
        title: String,
        text: Binding<String>,
        placeholder: String,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            TextField(placeholder, text: text)
                .font(.body)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                )
                .keyboardType(keyboardType)
        }
    }
    
    private func modernTextEditor(
        title: String,
        text: Binding<String>,
        placeholder: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .frame(height: 100)
                
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                }
                
                TextEditor(text: text)
                    .font(.body)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.clear)
                    .frame(height: 100)
            }
        }
    }
}

// MARK: - Custom Location Dropdown
struct CustomLocationDropdown: View {
    let locations: [String]
    @Binding var currentSelection: String
    @Binding var isPresented: Bool
    @State private var pressedLocation: String? = nil
    
    var body: some View {
        VStack(spacing: 8) {
            // Header
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 40, height: 6)
                
                Text("Select Location")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .padding(.top, 16)
            
            // Location options
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(locations, id: \.self) { location in
                        locationOptionRow(location: location)
                    }
                }
            }
            .frame(maxHeight: 300)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .frame(width: 280)
        .onTapGesture {
            // Prevent dismissing when tapping inside the dropdown
        }
    }
    
    private func locationOptionRow(location: String) -> some View {
        let isSelected = currentSelection == location
        let isPressed = pressedLocation == location
        let shouldHighlight = isSelected || isPressed
        
        return HStack(spacing: 12) {
            Text(location)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(
                    shouldHighlight ? .orange : .primary
                )
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    shouldHighlight
                        ? Color.orange.opacity(0.08)
                        : Color.clear
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            currentSelection = location
            withAnimation(.easeInOut(duration: 0.2)) {
                isPresented = false
            }
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            pressedLocation = pressing ? location : nil
        }, perform: {})
    }

}
