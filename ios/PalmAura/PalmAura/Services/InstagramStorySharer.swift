import UIKit

enum InstagramStorySharer {
    static func share(image: UIImage) -> Bool {
        guard let url = URL(string: "instagram-stories://share?source_application=PalmAura"),
              UIApplication.shared.canOpenURL(url),
              let imageData = image.pngData() else { return false }
        UIPasteboard.general.setItems([["com.instagram.sharedSticker.backgroundImage": imageData]], options: [.expirationDate: Date().addingTimeInterval(300)])
        UIApplication.shared.open(url)
        return true
    }
}
