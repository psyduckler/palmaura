import SwiftUI

struct MysticalBackground: View {
    var body: some View {
        LinearGradient(colors: [Color.black, Color.purple.opacity(0.75), Color.black], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
    }
}
