import SwiftUI

struct MessagesView: View {
    @EnvironmentObject var viewModel: ListingViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Orange line right below navigation bar
                Rectangle()
                    .fill(Color.orange)
                    .frame(height: 4)
                    .edgesIgnoringSafeArea(.horizontal)
                    .padding(.top, -10)

                if viewModel.conversations.isEmpty {
                    VStack(spacing: 16) {
                        Text("No conversations yet.")
                            .font(.title3)
                            .foregroundColor(.black)
                        Text("Send a message on a listing to start a conversation!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(viewModel.conversations) { conversation in
                        NavigationLink {
                            ConversationDetailView(conversation: conversation)
                        } label: {
                            HStack(spacing: 12) {
                                // Profile image or placeholder
                                if let imageUrl = conversation.otherUser.imageUrl, let url = URL(string: "http://localhost:3001\(imageUrl)") {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .frame(width: 40, height: 40)
                                            .clipShape(Circle())
                                    } placeholder: {
                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .frame(width: 40, height: 40)
                                            .foregroundColor(.gray)
                                    }
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(.gray)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(conversation.otherUser.name ?? conversation.otherUser.email)
                                            .font(.headline)
                                        Spacer()
                                        Text(formatDate(conversation.lastMessage.createdAt))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Text("Re: \(conversation.listing.title)")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    
                                    Text(conversation.lastMessage.content)
                                        .font(.subheadline)
                                        .lineLimit(2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    TitleView(title: "Messages")
                }
            }
            .onAppear {
                viewModel.fetchConversations()
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        
        guard let date = formatter.date(from: dateString) else {
            return ""
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .none
        displayFormatter.timeStyle = .short
        
        return displayFormatter.string(from: date)
    }
}
