import Foundation

final class ListingViewModel: ObservableObject {
    @Published var listings: [Listing] = []
    @Published var messages: [Int: [Message]] = [:]

    /// Appends a new outgoing message for a listing.
    func sendMessage(to listingID: Int, text: String) {
        let msg = Message(
            id: Int(Date().timeIntervalSince1970 * 1000), // Temporary unique id
            listingID: listingID,
            text: text,
            date: Date(),
            isSender: true
        )
        messages[listingID, default: []].append(msg)
        // TODO: hook up real backend / notify seller here
    }

    func addListing(title: String, price: String, description: String, location: String, userId: Int, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "http://localhost:3001/listings") else {
            print("❌ Invalid URL")
            completion(false)
            return
        }
        print("📡 Posting to: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "title": title,
            "price": price,
            "description": description,
            "location": location,
            "userId": userId
        ]
        print("📤 Request body: \(body)")
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
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
}
