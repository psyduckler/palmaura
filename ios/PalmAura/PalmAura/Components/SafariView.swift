import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = false
        
        let safariVC = SFSafariViewController(url: url, configuration: configuration)
        // Match the gold-cream and dark indigo/deep space branding
        safariVC.preferredControlTintColor = UIColor(red: 0.953, green: 0.867, blue: 0.659, alpha: 1.0) // DesignSystem.ColorToken.goldCream (approx)
        safariVC.preferredBarTintColor = UIColor(red: 0.043, green: 0.031, blue: 0.125, alpha: 1.0)     // DesignSystem.ColorToken.skyDeep (approx)
        return safariVC
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
