import SwiftUI

struct MessagesView: View {
    // Replace with your real DM data source
    let sampleDMs = [
        ("Alice", "Hey, is that desk still available?"),
        ("Bob", "Can you drop the price by $10?"),
        ("Charlie", "Can you drop the price by $10?")
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Orange line right below navigation bar
                Rectangle()
                    .fill(Color.orange)
                    .frame(height: 4)
                    .edgesIgnoringSafeArea(.horizontal)
                    .padding(.top, -10)

                List(sampleDMs, id: \.0) { sender, preview in
                    HStack(spacing: 12) {
                        Image(systemName: "person.circle")
                            .resizable()
                            .frame(width: 32, height: 32)
                        VStack(alignment: .leading) {
                            Text(sender).bold()
                            Text(preview)
                                .lineLimit(1)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    TitleView(title: "Message")
                }
            }
        }
    }
}
