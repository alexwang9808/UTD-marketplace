import Foundation

struct Listing: Identifiable, Codable {
    let id: Int?
    let title: String
    let price: Double
    let description: String?
    let location: String?
    let imageUrls: [String]
    let createdAt: String?
    let userId: Int?
    let user: User?
    let clickCount: Int?
    
    // Local-only property for temporary image data (not encoded/decoded)
    var imageData: Data? {
        return nil // Always nil since we use imageUrl from backend
    }
    
    // Custom price display as String
    var priceString: String {
        return String(format: "%.0f", price)
    }
    
    // First image URL for compatibility
    var primaryImageUrl: String? {
        return imageUrls.first
    }
    
    // Time ago display with snapshot functionality
    func timeAgo(from snapshotDate: Date = Date()) -> String {
        guard let createdAt = createdAt else { return "Unknown" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        guard let date = formatter.date(from: createdAt) else { return "Unknown" }
        
        let timeInterval = snapshotDate.timeIntervalSince(date)
        
        let seconds = Int(timeInterval)
        let minutes = seconds / 60
        let hours = minutes / 60
        let days = hours / 24
        let weeks = days / 7
        let months = days / 30
        let years = days / 365
        
        if years > 0 {
            return years == 1 ? "1 year ago" : "\(years) years ago"
        } else if months > 0 {
            return months == 1 ? "1 month ago" : "\(months) months ago"
        } else if weeks > 0 {
            return weeks == 1 ? "1 week ago" : "\(weeks) weeks ago"
        } else if days > 0 {
            return days == 1 ? "1 day ago" : "\(days) days ago"
        } else if hours > 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else if minutes > 0 {
            return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago"
        } else {
            return seconds <= 10 ? "Just now" : "\(seconds) seconds ago"
        }
    }
    
    // Backward compatibility - uses current time
    var timeAgo: String {
        return timeAgo(from: Date())
    }
}
