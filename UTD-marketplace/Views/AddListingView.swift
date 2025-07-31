import SwiftUI
import PhotosUI

struct AddListingView: View {
    @EnvironmentObject private var viewModel: ListingViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title       = ""
    @State private var location    = "University Village"
    @State private var price       = ""
    @State private var description = ""
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var imageDataArray: [Data] = []
    @State private var showPriceError = false

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
            Form {
                Section("Photos") {
                    PhotosPicker(
                        selection: $photoItems,
                        maxSelectionCount: 5,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label("Choose photos (up to 5)", systemImage: "photo.on.rectangle.angled")
                    }
                    
                    if !imageDataArray.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(imageDataArray.enumerated()), id: \.offset) { index, data in
                                    if let ui = UIImage(data: data) {
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: ui)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 120, height: 120)
                                                .clipped()
                                                .cornerRadius(8)
                                            
                                            Button(action: {
                                                imageDataArray.remove(at: index)
                                                photoItems.remove(at: index)
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.white)
                                                    .background(Color.black.opacity(0.6))
                                                    .clipShape(Circle())
                                            }
                                            .padding(4)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                        
                        Text("\(imageDataArray.count) of 5 photos selected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section("Details") {
                    TextField("Title", text: $title)

                    // Location dropdown
                    Picker("Location", selection: $location) {
                        ForEach(locations, id: \.self) { loc in
                            Text(loc).tag(loc)
                        }
                    }
                    .pickerStyle(.menu)

                    // Price with digits-only filtering
                    TextField("Price", text: Binding(
                        get: { price },
                        set: { newValue in
                            let filtered = newValue.filter { $0.isNumber }
                            showPriceError = (filtered != newValue)
                            price = filtered
                        }
                    ))
                    .keyboardType(.numberPad)

                    if showPriceError {
                        Text("Numbers only")
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    TextField("Description", text: $description, axis: .vertical)
                }
            }
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
                            userId: viewModel.currentUserId,
                            imageDataArray: imageDataArray
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
                        ? .gray : .blue
                    )
                }
            }
        }
        .task(id: photoItems) {
            imageDataArray.removeAll()
            for item in photoItems {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    imageDataArray.append(data)
                }
            }
        }
    }
}
