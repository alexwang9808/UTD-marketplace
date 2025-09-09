import SwiftUI

struct ConversationDetailView: View {
    // Support both existing conversation and new conversation initiation
    let conversation: Conversation?
    let listing: Listing?
    let otherUser: User?
    
    @EnvironmentObject private var viewModel: ListingViewModel
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var newMessage = ""
    @State private var isTyping = false
    @FocusState private var isTextFieldFocused: Bool
    
    // Computed properties to handle both cases
    private var displayListing: Listing {
        return conversation?.listing ?? listing!
    }
    
    private var displayOtherUser: User {
        return conversation?.otherUser ?? otherUser!
    }
    
    private var displayMessages: [Message] {
        // Use live messages from ViewModel if available, fallback to conversation messages
        let liveMessages = viewModel.messages[listingId] ?? []
        return liveMessages.isEmpty ? (conversation?.messages ?? []) : liveMessages
    }
    
    private var listingId: Int {
        return conversation?.listingId ?? listing!.id!
    }
    
    // Initializers
    init(conversation: Conversation) {
        self.conversation = conversation
        self.listing = nil
        self.otherUser = nil
    }
    
    init(listing: Listing, otherUser: User) {
        self.conversation = nil
        self.listing = listing
        self.otherUser = otherUser
    }

    var body: some View {
        ZStack {
            // Clean background
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
                .onAppear {
                    // Fetch messages for this specific listing when view appears
                    viewModel.fetchMessages(for: listingId)
                }
            
            VStack(spacing: 0) {
                // Modern listing header card
                modernListingHeader
                
                // Messages area
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if displayMessages.isEmpty {
                                modernEmptyState
                            } else {
                                let sortedMessages = displayMessages.sorted { $0.createdAt < $1.createdAt }
                                ForEach(Array(sortedMessages.enumerated()), id: \.element.id) { index, message in
                                    let shouldShowTime = shouldShowTimestamp(for: message, at: index, in: sortedMessages)
                                    modernMessageBubble(message: message, showTimestamp: shouldShowTime)
                                        .id(message.id)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                    }
                    .onChange(of: displayMessages.count) {
                        // Auto-scroll to the latest message
                        if let lastMessage = displayMessages.sorted(by: { $0.createdAt < $1.createdAt }).last {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onAppear {
                        // Scroll to bottom when view first appears
                        if let lastMessage = displayMessages.sorted(by: { $0.createdAt < $1.createdAt }).last {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Modern input bar
                modernInputBar
            }
        }
        .navigationTitle(displayOtherUser.name ?? displayOtherUser.email)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                }
            }
        }
    }
    
    // MARK: - Modern Listing Header
    private var modernListingHeader: some View {
        HStack(spacing: 16) {
            // Clickable listing image
            NavigationLink {
                ListingDetailView(listing: displayListing)
            } label: {
                if let imageUrl = displayListing.primaryImageUrl, let url = URL(string: "http://localhost:3001\(imageUrl)") {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                                    .font(.title2)
                            )
                    }
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                                .font(.title2)
                        )
                }
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(displayListing.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                Text("$\(displayListing.priceString)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Modern Empty State
    private var modernEmptyState: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Fun chat illustration
            ZStack {
                // Background bubbles
                Circle()
                    .fill(LinearGradient(colors: [.green.opacity(0.2), .blue.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 80, height: 80)
                    .offset(x: -15, y: -10)
                
                Circle()
                    .fill(LinearGradient(colors: [.purple.opacity(0.2), .pink.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 60, height: 60)
                    .offset(x: 20, y: 10)
                
                // Main chat icon
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 12) {
                Text("No messages yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("Start the conversation!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
    
    // MARK: - Modern Message Bubble
    private func modernMessageBubble(message: Message, showTimestamp: Bool = true) -> some View {
        HStack {
            let isSender = message.isFromCurrentUser(currentUserId: authManager.currentUser?.id ?? -1)
            if isSender { Spacer(minLength: 60) }
            
            VStack(alignment: isSender ? .trailing : .leading, spacing: 6) {
                // Message content based on type
                if message.type == .image {
                    modernImageMessage(message: message, isSender: isSender)
                } else {
                    modernTextMessage(message: message, isSender: isSender)
                }
                
                // Message metadata (only show if showTimestamp is true)
                if showTimestamp {
                    HStack(spacing: 6) {
                        Text(formatTime(message.createdAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 4)
                }
            }
            
            if !isSender { Spacer(minLength: 60) }
        }
    }
    
    // MARK: - Modern Native Input Bar
    private var modernInputBar: some View {
        HStack(spacing: 12) {
            // Message input container
            HStack(spacing: 12) {
                // Text field with native keyboard
                TextField("Message...", text: $newMessage)
                    .font(.system(size: 16))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .focused($isTextFieldFocused)
                    .onChange(of: newMessage) {
                        isTyping = !newMessage.isEmpty
                    }
                    .onSubmit {
                        if !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            sendTextMessage()
                        }
                    }
            }
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(isTextFieldFocused ? Color.orange.opacity(0.5) : Color.gray.opacity(0.2), lineWidth: 1.5)
                    )
            )
            
            // Send button (only show when typing)
            if !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button(action: sendTextMessage) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.orange, .orange.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: newMessage.isEmpty)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: -2)
        )
    }
    
    private func formatTime(_ dateString: String) -> String {
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
    
    private func shouldShowTimestamp(for message: Message, at index: Int, in messages: [Message]) -> Bool {
        // Always show timestamp for the last message
        if index == messages.count - 1 {
            return true
        }
        
        // Check if the next message is from a different user
        let nextMessage = messages[index + 1]
        if nextMessage.userId != message.userId {
            return true
        }
        
        // Check if the next message was sent more than 2 minutes later
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        
        guard let currentDate = formatter.date(from: message.createdAt),
              let nextDate = formatter.date(from: nextMessage.createdAt) else {
            return true
        }
        
        let timeDifference = nextDate.timeIntervalSince(currentDate)
        return timeDifference > 120 // 2 minutes
    }
    
    // MARK: - Message Components
    private func modernTextMessage(message: Message, isSender: Bool) -> some View {
        Text(message.displayContent)
            .font(.system(size: 16))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        isSender
                            ? LinearGradient(
                                colors: [.orange, .orange.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
            )
            .foregroundColor(isSender ? .white : .primary)
    }
    
    private func modernImageMessage(message: Message, isSender: Bool) -> some View {
        Group {
            if let imageUrl = message.imageUrl,
               let url = URL(string: "http://localhost:3001\(imageUrl)") {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: 200, maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                } placeholder: {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 200, height: 200)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        )
                }
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.title2)
                                .foregroundColor(.red)
                            Text("Failed to load image")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    )
            }
        }
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Message Actions
    private func sendTextMessage() {
        let text = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        viewModel.sendMessage(to: listingId, content: text, authToken: authManager.authToken, userId: authManager.currentUser?.id) { success in
            if success {
                newMessage = ""
                isTyping = false
            }
        }
    }
    

} 