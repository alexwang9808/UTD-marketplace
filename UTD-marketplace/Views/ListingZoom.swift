import SwiftUI

struct ListingDetailView: View {
    let listing: Listing

    @EnvironmentObject private var viewModel: ListingViewModel
    @State private var newMessage = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // — Detail Header —
                    if let ui = UIImage(data: listing.imageData) {
                        Image(uiImage: ui)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(12)
                    }

                    Text(listing.title)
                        .font(.largeTitle).bold()

                    Text("$\(listing.price)")
                        .font(.title2)
                        .foregroundColor(.accentColor)

                    Text(listing.description)
                        .font(.body)

                    // — Message History —
                    Divider().padding(.vertical, 8)
                    ForEach(viewModel.messages[listing.id] ?? []) { msg in
                        HStack {
                            if msg.isSender { Spacer() }
                            Text(msg.text)
                                .padding(10)
                                .background(
                                    msg.isSender
                                        ? Color.blue.opacity(0.7)
                                        : Color.gray.opacity(0.3)
                                )
                                .foregroundColor(msg.isSender ? .white : .primary)
                                .cornerRadius(8)
                            if !msg.isSender { Spacer() }
                        }
                    }
                }
                .padding()
            }

            Divider()

            // — Input Bar —
            HStack(spacing: 8) {
                TextField("Message…", text: $newMessage)
                    .textFieldStyle(.roundedBorder)

                Button("Send") {
                    let text = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else { return }
                    viewModel.sendMessage(to: listing.id, text: text)
                    newMessage = ""
                }
            }
            .padding()
        }
        .navigationTitle("Listing")
        .navigationBarTitleDisplayMode(.inline)
    }
}
