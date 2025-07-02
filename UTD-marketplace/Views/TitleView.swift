import SwiftUI

struct TitleView: View {
    let title: String
    let logoSize: CGFloat = 32

    var body: some View {
        HStack(spacing: 20) {
            Text(title)
                .font(.system(size: 28, weight: .bold))
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: logoSize, height: logoSize)
        }
        .offset(y: 6) // vertical alignment tweak
    }
}
