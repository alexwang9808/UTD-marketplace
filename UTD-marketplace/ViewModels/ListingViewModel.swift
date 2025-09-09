import Foundation

final class ListingViewModel: ObservableObject {
    @Published var listings: [Listing] = []
    @Published var messages: [Int: [Message]] = [:]
    @Published var conversations: [Conversation] = []
    


    /// Fetches conversations for the specified user
    func fetchConversations(for userId: Int? = nil) {
        guard let userId = userId,
              let url = URL(string: "http://localhost:3001/users/\(userId)/conversations") else {
            print("Invalid URL for fetching conversations")
            return
        }
        print("Fetching conversations from: \(url)")
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("Network error fetching conversations: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Conversations HTTP Status: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("No data received when fetching conversations")
                return
            }
            
            print("Fetched conversations data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
            
            do {
                let fetchedConversations = try JSONDecoder().decode([Conversation].self, from: data)
                print("Successfully decoded \(fetchedConversations.count) conversations")
                print("DEBUG: Conversation titles: \(fetchedConversations.map { $0.listing.title })")
                DispatchQueue.main.async {
                    self?.conversations = fetchedConversations
                    print("DEBUG: Updated conversations array, count: \(self?.conversations.count ?? 0)")
                }
            } catch {
                print("Failed to decode conversations: \(error)")
                print("DEBUG: Decoding error details: \(error.localizedDescription)")
                if let decodingError = error as? DecodingError {
                    print("DEBUG: Detailed decoding error: \(decodingError)")
                }
            }
        }.resume()
    }

    /// Fetches messages for a specific listing from the backend
    func fetchMessages(for listingId: Int) {
        guard let url = URL(string: "http://localhost:3001/listings/\(listingId)/messages") else {
            print("Invalid URL for fetching messages")
            return
        }
        print("Fetching messages for listing \(listingId) from: \(url)")
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("Network error fetching messages: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Messages HTTP Status: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("No data received when fetching messages")
                return
            }
            
            print("Fetched messages data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
            
            do {
                let fetchedMessages = try JSONDecoder().decode([Message].self, from: data)
                print("Successfully decoded \(fetchedMessages.count) messages")
                DispatchQueue.main.async {
                    self?.messages[listingId] = fetchedMessages
                }
            } catch {
                print("Failed to decode messages: \(error)")
            }
        }.resume()
    }

    /// Sends a new message to the backend
    func sendMessage(to listingId: Int, content: String, authToken: String?, userId: Int? = nil, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "http://localhost:3001/messages") else {
            print("Invalid URL for sending message")
            completion(false)
            return
        }
        print("Sending message to: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add Authorization header if token is provided
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body: [String: Any] = [
            "content": content,
            "listingId": listingId
        ]
        print("Message body: \(body)")
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Network error sending message: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(false) }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Send message HTTP Status: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("No data received when sending message")
                DispatchQueue.main.async { completion(false) }
                return
            }
            
            print("Send message response: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
            
            if let message = try? JSONDecoder().decode(Message.self, from: data) {
                print("Successfully sent message")
                DispatchQueue.main.async {
                    self?.messages[listingId, default: []].append(message)
                    // Refresh conversations to show the new message
                    if let userId = userId {
                        self?.fetchConversations(for: userId)
                    }
                    completion(true)
                }
            } else {
                print("Failed to decode sent message response")
                DispatchQueue.main.async { completion(false) }
            }
        }.resume()
    }

    /// Sends an image message to the backend
    func sendImageMessage(to listingId: Int, imageData: Data, authToken: String?, userId: Int? = nil, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "http://localhost:3001/messages") else {
            print("Invalid URL for sending image message")
            completion(false)
            return
        }
        print("Sending image message to: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Add Authorization header if token is provided
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add listingId field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"listingId\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(listingId)\r\n".data(using: .utf8)!)
        
        // Add messageType field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"messageType\"\r\n\r\n".data(using: .utf8)!)
        body.append("image\r\n".data(using: .utf8)!)
        
        // Add image
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        print("Image message request body size: \(body.count) bytes")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Network error sending image message: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(false) }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Send image message HTTP Status: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("No data received when sending image message")
                DispatchQueue.main.async { completion(false) }
                return
            }
            
            print("Send image message response: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
            
            if let message = try? JSONDecoder().decode(Message.self, from: data) {
                print("Successfully sent image message")
                DispatchQueue.main.async {
                    self?.messages[listingId, default: []].append(message)
                    // Refresh conversations to show the new message
                    if let userId = userId {
                        self?.fetchConversations(for: userId)
                    }
                    completion(true)
                }
            } else {
                print("Failed to decode sent image message response")
                DispatchQueue.main.async { completion(false) }
            }
        }.resume()
    }

    func addListing(title: String, price: String, description: String, location: String, imageDataArray: [Data], authToken: String?, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "http://localhost:3001/listings") else {
            print("Invalid URL")
            completion(false)
            return
        }
        print("Posting to: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Add authorization header if token provided
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
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
        print("Request body size: \(body.count) bytes")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(false) }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("No data received")
                DispatchQueue.main.async { completion(false) }
                return
            }
            
            print("Response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
            
            if let listing = try? JSONDecoder().decode(Listing.self, from: data) {
                print("Successfully decoded listing: \(listing)")
                DispatchQueue.main.async {
                    // Refresh the entire listings array to ensure we have fresh data
                    self?.fetchListings()
                    completion(true)
                }
            } else {
                print("Failed to decode listing from response")
                DispatchQueue.main.async { completion(false) }
            }
        }.resume()
    }
    
    func updateListing(id: Int, title: String, price: String, description: String, location: String, imageDataArray: [Data]?, authToken: String?, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "http://localhost:3001/listings/\(id)") else {
            print("Invalid URL for updating listing")
            completion(false)
            return
        }
        print("Updating listing at: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        
        // Add authorization header if token provided
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
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
        
        // Add images if provided
        if let imageDataArray = imageDataArray {
            for (index, imageData) in imageDataArray.enumerated() {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"images\"; filename=\"image\(index).jpg\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
                body.append(imageData)
                body.append("\r\n".data(using: .utf8)!)
            }
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        print("Update request body size: \(body.count) bytes")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Network error updating listing: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(false) }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Update HTTP Status: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("No data received when updating listing")
                DispatchQueue.main.async { completion(false) }
                return
            }
            
            print("Update response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
            
            if let listing = try? JSONDecoder().decode(Listing.self, from: data) {
                print("Successfully updated listing: \(listing)")
                DispatchQueue.main.async {
                    // Refresh the entire listings array to ensure we have fresh data
                    self?.fetchListings()
                    completion(true)
                }
            } else {
                print("Failed to decode updated listing from response")
                DispatchQueue.main.async { completion(false) }
            }
        }.resume()
    }
    
    func deleteListing(id: Int, authToken: String?, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "http://localhost:3001/listings/\(id)") else {
            print("Invalid URL for deleting listing")
            completion(false)
            return
        }
        print("Deleting listing at: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        // Add authorization header if token provided
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Network error deleting listing: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(false) }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Delete HTTP Status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 {
                    print("Successfully deleted listing")
                    DispatchQueue.main.async {
                        // Refresh the entire listings array to ensure we have fresh data
                        self?.fetchListings()
                        completion(true)
                    }
                } else {
                    print("Failed to delete listing with status: \(httpResponse.statusCode)")
                    DispatchQueue.main.async { completion(false) }
                }
            } else {
                print("No HTTP response when deleting listing")
                DispatchQueue.main.async { completion(false) }
            }
        }.resume()
    }
    
    func fetchListings() {
        guard let url = URL(string: "http://localhost:3001/listings") else {
            print("Invalid URL for fetching listings")
            return
        }
        print("Fetching listings from: \(url)")
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("Network error fetching listings: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("No data received when fetching listings")
                return
            }
            
            print("Fetched listings data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
            
            do {
                let listings = try JSONDecoder().decode([Listing].self, from: data)
                print("Successfully decoded \(listings.count) listings")
                DispatchQueue.main.async {
                    self?.listings = listings
                }
            } catch {
                print("Failed to decode listings: \(error)")
            }
        }.resume()
    }
    
    func trackClick(for listingId: Int, authToken: String?, completion: @escaping (Bool, Int?) -> Void) {
        guard let url = URL(string: "http://localhost:3001/listings/\(listingId)/click") else {
            print("Invalid URL for tracking click")
            completion(false, nil)
            return
        }
        print("Tracking click for listing \(listingId) at: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authorization header if token provided
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error tracking click: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(false, nil) }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Click tracking HTTP Status: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("No data received when tracking click")
                DispatchQueue.main.async { completion(false, nil) }
                return
            }
            
            print("Click tracking response: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
            
            do {
                if let response = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let clickCount = response["clickCount"] as? Int {
                    print("Successfully tracked click, new count: \(clickCount)")
                    DispatchQueue.main.async { completion(true, clickCount) }
                } else {
                    print("Failed to parse click tracking response")
                    DispatchQueue.main.async { completion(false, nil) }
                }
            } catch {
                print("Failed to decode click tracking response: \(error)")
                DispatchQueue.main.async { completion(false, nil) }
            }
        }.resume()
    }
}
