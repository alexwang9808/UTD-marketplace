import Foundation

final class ListingViewModel: ObservableObject {
    @Published var listings: [Listing] = []
    @Published var messages: [Int: [Message]] = [:]
    @Published var conversations: [Conversation] = []
    
    // Current user ID - can be changed for testing
    @Published var currentUserId = 1
    
    // Development helper - switch between test users
    func switchUser(to userId: Int) {
        currentUserId = userId
        // Clear cached data when switching users
        conversations = []
        messages = [:]
        print("🔄 Switched to user ID: \(userId)")
        // Refresh data for new user
        fetchConversations()
    }

    /// Fetches conversations for the current user
    func fetchConversations() {
        guard let url = URL(string: "http://localhost:3001/users/\(currentUserId)/conversations") else {
            print("❌ Invalid URL for fetching conversations")
            return
        }
        print("📡 Fetching conversations from: \(url)")
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("❌ Network error fetching conversations: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 Conversations HTTP Status: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("❌ No data received when fetching conversations")
                return
            }
            
            print("📥 Fetched conversations data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
            
            do {
                let fetchedConversations = try JSONDecoder().decode([Conversation].self, from: data)
                print("✅ Successfully decoded \(fetchedConversations.count) conversations")
                DispatchQueue.main.async {
                    self?.conversations = fetchedConversations
                }
            } catch {
                print("❌ Failed to decode conversations: \(error)")
            }
        }.resume()
    }

    /// Fetches messages for a specific listing from the backend
    func fetchMessages(for listingId: Int) {
        guard let url = URL(string: "http://localhost:3001/listings/\(listingId)/messages") else {
            print("❌ Invalid URL for fetching messages")
            return
        }
        print("📡 Fetching messages for listing \(listingId) from: \(url)")
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("❌ Network error fetching messages: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 Messages HTTP Status: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("❌ No data received when fetching messages")
                return
            }
            
            print("📥 Fetched messages data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
            
            do {
                let fetchedMessages = try JSONDecoder().decode([Message].self, from: data)
                print("✅ Successfully decoded \(fetchedMessages.count) messages")
                DispatchQueue.main.async {
                    self?.messages[listingId] = fetchedMessages
                }
            } catch {
                print("❌ Failed to decode messages: \(error)")
            }
        }.resume()
    }

    /// Sends a new message to the backend
    func sendMessage(to listingId: Int, content: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "http://localhost:3001/messages") else {
            print("❌ Invalid URL for sending message")
            completion(false)
            return
        }
        print("📡 Sending message to: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "content": content,
            "userId": currentUserId,
            "listingId": listingId
        ]
        print("📤 Message body: \(body)")
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("❌ Network error sending message: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(false) }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 Send message HTTP Status: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("❌ No data received when sending message")
                DispatchQueue.main.async { completion(false) }
                return
            }
            
            print("📥 Send message response: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
            
            if let message = try? JSONDecoder().decode(Message.self, from: data) {
                print("✅ Successfully sent message")
                DispatchQueue.main.async {
                    self?.messages[listingId, default: []].append(message)
                    // Refresh conversations to show the new message
                    self?.fetchConversations()
                    completion(true)
                }
            } else {
                print("❌ Failed to decode sent message response")
                DispatchQueue.main.async { completion(false) }
            }
        }.resume()
    }

    func addListing(title: String, price: String, description: String, location: String, userId: Int, imageDataArray: [Data], completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "http://localhost:3001/listings") else {
            print("❌ Invalid URL")
            completion(false)
            return
        }
        print("📡 Posting to: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add text fields
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"title\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(title)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"price\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(price)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"description\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(description)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"location\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(location)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"userId\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(userId)\r\n".data(using: .utf8)!)
        
        // Add images if provided
        for (index, imageData) in imageDataArray.enumerated() {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"images\"; filename=\"image\(index).jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        print("📤 Request body size: \(body.count) bytes")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(false) }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 HTTP Status: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("❌ No data received")
                DispatchQueue.main.async { completion(false) }
                return
            }
            
            print("📥 Response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
            
            if let listing = try? JSONDecoder().decode(Listing.self, from: data) {
                print("✅ Successfully decoded listing: \(listing)")
                DispatchQueue.main.async {
                    self?.listings.append(listing)
                    completion(true)
                }
            } else {
                print("❌ Failed to decode listing from response")
                DispatchQueue.main.async { completion(false) }
            }
        }.resume()
    }
    
    func fetchListings() {
        guard let url = URL(string: "http://localhost:3001/listings") else {
            print("❌ Invalid URL for fetching listings")
            return
        }
        print("📡 Fetching listings from: \(url)")
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("❌ Network error fetching listings: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 HTTP Status: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("❌ No data received when fetching listings")
                return
            }
            
            print("📥 Fetched listings data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
            
            do {
                let listings = try JSONDecoder().decode([Listing].self, from: data)
                print("✅ Successfully decoded \(listings.count) listings")
                DispatchQueue.main.async {
                    self?.listings = listings
                }
            } catch {
                print("❌ Failed to decode listings: \(error)")
            }
        }.resume()
    }
}
