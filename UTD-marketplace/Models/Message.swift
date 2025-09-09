import Foundation

struct Message: Identifiable, Codable {
    let id: Int
    let content: String?
    let imageUrl: String?
    let messageType: String?
    let createdAt: String
    let userId: Int
    let listingId: Int
    let user: User?
    
    enum MessageType: String, CaseIterable {
        case text = "text"
        case image = "image"
        case system = "system"
    }
    
    var type: MessageType {
        return MessageType(rawValue: messageType ?? "text") ?? .text
    }
    
    // Helper to determine if message is from current user
    func isFromCurrentUser(currentUserId: Int) -> Bool {
        return userId == currentUserId
    }
    
    // Helper to get display content
    var displayContent: String {
        if type == .image && (content?.isEmpty ?? true) {
            return "📷 Photo"
        }
        return content ?? ""
    }
    
    // Time ago display with snapshot functionality
    func timeAgo(from snapshotDate: Date = Date()) -> String {
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
            return years == 1 ? "1y" : "\(years)y"
        } else if months > 0 {
            return months == 1 ? "1mo" : "\(months)mo"
        } else if weeks > 0 {
            return weeks == 1 ? "1w" : "\(weeks)w"
        } else if days > 0 {
            return days == 1 ? "1d" : "\(days)d"
        } else if hours > 0 {
            return hours == 1 ? "1h" : "\(hours)h"
        } else if minutes > 0 {
            return minutes == 1 ? "1m" : "\(minutes)m"
        } else {
            return "now"
        }
    }
    
    // Backward compatibility - uses current time
    var timeAgo: String {
        return timeAgo(from: Date())
    }
}
