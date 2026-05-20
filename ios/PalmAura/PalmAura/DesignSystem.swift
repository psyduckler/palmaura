import SwiftUI

enum DesignSystem {
    enum ColorToken {
        static let skyDeep      = Color(red: 0.043, green: 0.031, blue: 0.125)
        static let skyWarm      = Color(red: 0.082, green: 0.063, blue: 0.184)
        static let skyIndigo    = Color(red: 0.165, green: 0.125, blue: 0.333)
        static let skyMulberry  = Color(red: 0.290, green: 0.122, blue: 0.290)
        static let goldCream     = Color(red: 0.953, green: 0.867, blue: 0.659)
        static let goldCreamSoft = Color(red: 1.000, green: 0.965, blue: 0.847)
        static let gold          = Color(red: 0.627, green: 0.478, blue: 0.227)
        static let goldDeep      = Color(red: 0.486, green: 0.353, blue: 0.133)
        static let parchmentLight = Color(red: 0.945, green: 0.906, blue: 0.812)
        static let parchment      = Color(red: 0.910, green: 0.859, blue: 0.725)
        static let parchmentDeep  = Color(red: 0.851, green: 0.784, blue: 0.612)
        static let ink            = Color(red: 0.165, green: 0.122, blue: 0.082)
        static let inkSoft        = Color(red: 0.290, green: 0.220, blue: 0.149)
        static let textPrimary    = goldCreamSoft.opacity(0.92)
        static let textSecondary  = goldCreamSoft.opacity(0.72)
        static let textTertiary   = goldCreamSoft.opacity(0.55)
        static let borderSoft     = goldCream.opacity(0.35)
        static let surfaceSoft    = goldCream.opacity(0.06)

        // Compatibility aliases while the rest of the app migrates.
        static let void = skyDeep
        static let auraViolet = skyIndigo
        static let mysticPurple = skyMulberry
        static let solarGold = goldCream
        static let moonlight = parchmentLight
        static let softText = textSecondary
        static let quietText = textTertiary
        static let cardStroke = borderSoft
    }

    enum FontToken {
        /// Display (Cormorant Garamond) — headlines and emphasized sentences.
        /// Scales relative to `.title` so headings grow with Dynamic Type but
        /// the visual hierarchy stays correct against body text.
        static func display(_ size: CGFloat, italic: Bool = false, weight: Font.Weight = .medium) -> Font {
            .custom(italic ? "CormorantGaramond-MediumItalic" : "CormorantGaramond-Medium", size: size, relativeTo: .title).weight(weight)
        }
        /// Body (EB Garamond) — paragraphs, captions, italic asides. Scales
        /// with the user's Dynamic Type setting. This is the primary
        /// accessibility surface — keep `relativeTo: .body` so it expands at
        /// xxxLarge and Accessibility sizes the way iOS users expect.
        static func body(_ size: CGFloat = 14, italic: Bool = false) -> Font {
            .custom(italic ? "EBGaramond-Italic" : "EBGaramond-Regular", size: size, relativeTo: .body)
        }
        /// Caps (Cinzel) — eyebrows, button labels, glyph annotations. Kept
        /// at fixed point size deliberately: caps live inside fixed-width
        /// chrome (pill buttons, headers, focus chips) and scaling them
        /// breaks the layout. Body and display carry the Dynamic Type
        /// contract for these screens.
        static func caps(_ size: CGFloat = 11) -> Font {
            // Cinzel ships as a variable font with named instances at Regular/Bold/Black only;
            // SemiBold is reached by setting the wght axis via .weight(.semibold).
            .custom("Cinzel-Regular", size: size).weight(.semibold)
        }
        /// Hand (Caveat) — currently unused in user-facing copy; reserved
        /// for handwritten asides. Scales with body.
        static func hand(_ size: CGFloat = 16) -> Font {
            .custom("Caveat-Regular", size: size, relativeTo: .body)
        }
        static let title = display(26)
        static let footnote = Font.footnote
        static let caption = Font.caption
    }

    enum Tracking { static let caps: CGFloat = 3.5; static let capsLg: CGFloat = 5 }
    enum Spacing { static let xxs: CGFloat = 4; static let xs: CGFloat = 8; static let sm: CGFloat = 12; static let md: CGFloat = 16; static let lg: CGFloat = 24; static let xl: CGFloat = 32; static let xxl: CGFloat = 48; static let screenInset: CGFloat = 24 }
    enum Radius { static let pill: CGFloat = 999; static let cardLg: CGFloat = 22; static let cardMd: CGFloat = 18; static let cardSm: CGFloat = 14; static let tab: CGFloat = 26; static let card: CGFloat = 22; static let hero: CGFloat = 32 }
    enum Motion { static let phraseInterval: TimeInterval = 2.8; static let phraseFade: TimeInterval = 2.8; static let stepAdvance: TimeInterval = 0.22; static let palmIgnitionDuration: TimeInterval = 2.4; static let minimumReadingDuration: TimeInterval = 5 }
}

struct DarkScreenBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [DesignSystem.ColorToken.skyDeep, DesignSystem.ColorToken.skyWarm], startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [DesignSystem.ColorToken.skyIndigo, .clear], center: .init(x: 0.3, y: 0.2), startRadius: 0, endRadius: 340).opacity(0.85)
            RadialGradient(colors: [DesignSystem.ColorToken.skyMulberry, .clear], center: .init(x: 0.75, y: 0.82), startRadius: 0, endRadius: 380).opacity(0.72)
            StarField()
        }
        .ignoresSafeArea()
    }
}

struct StarField: View {
    private let positions: [(CGPoint, CGFloat, CGFloat)] = (0..<44).map { i in
        let x = CGFloat((i * 53 + 17) % 380)
        let y = CGFloat((i * 91 + 29) % 820)
        let r = CGFloat((i * 7) % 5) / 8.0 + 0.25
        let o = 0.36 * (0.55 + CGFloat(i % 3) * 0.22)
        return (CGPoint(x: x, y: y), r, o)
    }
    var body: some View {
        GeometryReader { geo in
            ForEach(positions.indices, id: \.self) { i in
                let (p, r, o) = positions[i]
                Circle()
                    .fill(DesignSystem.ColorToken.goldCream.opacity(o))
                    .frame(width: r * 2, height: r * 2)
                    .position(x: p.x * geo.size.width / 380, y: p.y * geo.size.height / 820)
            }
        }
        .allowsHitTesting(false)
    }
}

/// Which persistent-nav destination the current screen represents. Used by
/// `ScreenHeader` to dim and disable the matching nav icon (a "you are here"
/// affordance) so users don't tap the icon for the screen they're already on.
enum ActiveNavItem: String {
    case home
    case settings
}

struct ScreenHeader: View {
    var eyebrow: String = "PalmAura"
    var back: Bool = false
    var onBack: (() -> Void)? = nil
    var trailingText: String? = nil
    var onTrailing: (() -> Void)? = nil
    var showsHomeButton: Bool = true
    /// When true, suppress the persistent global-nav top row (Home/Settings
    /// icons + PalmAura title). Used on the splash, disclaimer, and first-run
    /// onboarding so the user can't bypass those gates by tapping into
    /// Settings or Home. The contextual row (back/eyebrow/trailing) still
    /// renders if it has content.
    var compact: Bool = false
    /// Pass the matching `ActiveNavItem` so the corresponding nav icon is
    /// rendered as "you are here" (muted appearance, no-op on tap, marked
    /// `.isSelected` for VoiceOver). Pass `nil` (default) when the current
    /// screen isn't one of the persistent-nav destinations.
    var activeNavItem: ActiveNavItem? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.navigationCoordinator) private var coordinator

    private var showsContext: Bool {
        let normalized = eyebrow.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return !normalized.isEmpty && normalized != "palmaura"
    }

    private var showsContextRow: Bool {
        showsContext || back || trailingText != nil
    }

    var body: some View {
        // In compact mode with nothing to show in the context row either,
        // render nothing so the gating screens (splash, disclaimer) get the
        // full available height.
        if compact && !showsContextRow {
            EmptyView()
        } else {
            VStack(spacing: 6) {
                if !compact {
                    globalNavRow
                }
                if showsContextRow {
                    contextRow
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.top, 12)
            .padding(.bottom, 10)
        }
    }

    private var globalNavRow: some View {
        HStack(alignment: .center) {
            if showsHomeButton {
                navIcon(systemName: "house", accessibilityLabel: "Home", isActive: activeNavItem == .home) {
                    coordinator?.goHome()
                }
            } else {
                Color.clear.frame(width: 44, height: 44)
            }

            Spacer(minLength: 8)

            Button {
                coordinator?.goHome()
            } label: {
                Text("PalmAura")
                    .font(DesignSystem.FontToken.caps(12))
                    .tracking(DesignSystem.Tracking.capsLg)
                    .textCase(.uppercase)
                    .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.9))
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("PalmAura home")

            Spacer(minLength: 8)

            navIcon(systemName: "gearshape", accessibilityLabel: "Settings", isActive: activeNavItem == .settings) {
                coordinator?.goSettings()
            }
        }
    }

    @ViewBuilder
    private var contextRow: some View {
        if showsContextRow {
            HStack(spacing: 8) {
                if back {
                    Button(action: { if let onBack { onBack() } else { dismiss() } }) {
                        Text("‹ Back")
                            .font(DesignSystem.FontToken.caps(9))
                            .tracking(1.8)
                            .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.82))
                            .padding(.vertical, 12)
                            .padding(.trailing, 12)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .frame(minWidth: 62, alignment: .leading)
                } else {
                    Color.clear.frame(width: 62, height: 16)
                }

                if showsContext {
                    Text(eyebrow)
                        .font(DesignSystem.FontToken.caps(8.5))
                        .tracking(2.6)
                        .textCase(.uppercase)
                        .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.58))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                } else {
                    Spacer(minLength: 0)
                }

                if let trailingText {
                    Button(trailingText) { onTrailing?() }
                        .font(DesignSystem.FontToken.caps(8))
                        .tracking(1.8)
                        .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.7))
                        .frame(width: 62, alignment: .trailing)
                } else {
                    Color.clear.frame(width: 62, height: 16)
                }
            }
            .frame(minHeight: 18)
        }
    }

    private func navIcon(systemName: String, accessibilityLabel: String, isActive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(isActive ? 0.45 : 0.92))
                // Icon-only chrome: no visible circle, but keep the 44pt
                // rectangle tap target so the controls stay easy to hit.
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isActive ? .isSelected : [])
        .disabled(isActive)
    }
}

struct GoldButton: View {
    let title: String
    let action: () -> Void
    var small = false
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignSystem.FontToken.caps(small ? 10 : 11))
                .tracking(small ? 3 : 4)
                .textCase(.uppercase)
                .foregroundStyle(DesignSystem.ColorToken.skyDeep)
                .frame(maxWidth: .infinity)
                .padding(.vertical, small ? 12 : 15)
                .padding(.horizontal, small ? 18 : 26)
                .background(Capsule().fill(DesignSystem.ColorToken.goldCream.opacity(0.94)))
                .shadow(color: DesignSystem.ColorToken.goldCream.opacity(0.28), radius: 15)
        }.buttonStyle(.plain)
    }
}

struct GhostButton: View {
    let title: String
    let action: () -> Void
    var leading: String? = nil
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let leading { Text(leading).font(DesignSystem.FontToken.display(15)) }
                Text(title).font(DesignSystem.FontToken.caps(10)).tracking(3).textCase(.uppercase)
            }
            .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.86))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 18)
            .overlay(Capsule().stroke(DesignSystem.ColorToken.goldCream.opacity(0.35), lineWidth: 1))
        }.buttonStyle(.plain)
    }
}

struct ChoiceCard: View {
    let glyph: String
    let title: String
    let subtitle: String
    let selected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                GlyphCircle(glyph: glyph, size: 44, selected: selected)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(DesignSystem.FontToken.display(18)).foregroundStyle(DesignSystem.ColorToken.textPrimary)
                    Text(subtitle).font(DesignSystem.FontToken.body(13)).foregroundStyle(DesignSystem.ColorToken.textSecondary).lineLimit(2)
                }
                Spacer()
                ZStack {
                    Circle().stroke(DesignSystem.ColorToken.goldCream.opacity(selected ? 0.85 : 0.35), lineWidth: 1)
                    if selected { Circle().fill(DesignSystem.ColorToken.goldCream).padding(4); Text("✓").font(.system(size: 10, weight: .bold)).foregroundStyle(DesignSystem.ColorToken.skyDeep) }
                }.frame(width: 18, height: 18)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: DesignSystem.Radius.cardMd).fill(DesignSystem.ColorToken.goldCream.opacity(selected ? 0.10 : 0.055)))
            .overlay(RoundedRectangle(cornerRadius: DesignSystem.Radius.cardMd).stroke(DesignSystem.ColorToken.goldCream.opacity(selected ? 0.55 : 0.20), lineWidth: 1))
            .shadow(color: DesignSystem.ColorToken.goldCream.opacity(selected ? 0.15 : 0), radius: 18)
        }.buttonStyle(.plain)
    }
}

struct GlyphCircle: View {
    let glyph: String
    var size: CGFloat = 38
    var selected = false
    var body: some View {
        Text(glyph)
            .font(DesignSystem.FontToken.display(size * 0.48))
            .foregroundStyle(DesignSystem.ColorToken.goldCream)
            .frame(width: size, height: size)
            .background(Circle().fill(DesignSystem.ColorToken.goldCream.opacity(selected ? 0.15 : 0.06)))
            .overlay(Circle().stroke(DesignSystem.ColorToken.goldCream.opacity(selected ? 0.65 : 0.35), lineWidth: 1))
            // All callers pair this with a labelled row, chapter title, etc.
            // VoiceOver should announce the row's text, not the decorative
            // glyph (which it would otherwise read as "Heart" / "Sun" / etc.).
            .accessibilityHidden(true)
    }
}

struct StepPips: View {
    let total: Int
    let index: Int
    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(DesignSystem.ColorToken.goldCream.opacity(i == index ? 0.86 : 0.28))
                    .frame(width: i == index ? 22 : 6, height: 6)
                    .animation(.easeInOut(duration: 0.2), value: index)
            }
        }
    }
}

struct OrnamentRule: View {
    var body: some View {
        HStack(spacing: 10) {
            Rectangle().fill(DesignSystem.ColorToken.goldCream.opacity(0.35)).frame(height: 0.6)
            Text("✦").font(DesignSystem.FontToken.display(13)).foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.65))
            Rectangle().fill(DesignSystem.ColorToken.goldCream.opacity(0.35)).frame(height: 0.6)
        }
        .accessibilityHidden(true)
    }
}

struct DisclaimerFoot: View {
    var body: some View {
        Text(BrandConfig.shortDisclaimer)
            .font(DesignSystem.FontToken.caps(8))
            .tracking(2)
            .foregroundStyle(DesignSystem.ColorToken.textTertiary)
            .multilineTextAlignment(.center)
    }
}

struct ParchmentPanel<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .padding(18)
            .background(RoundedRectangle(cornerRadius: DesignSystem.Radius.cardLg).fill(DesignSystem.ColorToken.goldCream.opacity(0.075)))
            .overlay(RoundedRectangle(cornerRadius: DesignSystem.Radius.cardLg).stroke(DesignSystem.ColorToken.goldCream.opacity(0.26), lineWidth: 1))
    }
}

/// Lunar phase calculation. Used in `ReadingResultView` as a keepsake
/// timestamp; should reflect the moon at *reading time*, not view time, so
/// a saved reading opened weeks later shows the moon the reading was born
/// under. The previous `MoonPhase` visual disc was removed when the
/// persistent header dropped lunar chrome (commit 02fe980).
enum MoonPhaseProvider {
    /// Reference new-moon used to anchor the synodic cycle (2000-01-06).
    private static let referenceNewMoon = Date(timeIntervalSince1970: 947182440)
    /// Length of the synodic month in days.
    private static let synodicMonth: Double = 29.53058867

    /// Phase value in `[0, 1)` for an arbitrary date. 0 = new moon,
    /// 0.5 = full moon. Negative-spanning differences are folded back into
    /// the valid range so far-past dates work the same as recent ones.
    static func phase(for date: Date) -> Double {
        let days = date.timeIntervalSince(referenceNewMoon) / 86400
        let fractional = days.truncatingRemainder(dividingBy: synodicMonth) / synodicMonth
        return fractional >= 0 ? fractional : fractional + 1
    }

    /// Eight-segment label (NEW · MOON, WAX · CRES, etc.) for an arbitrary
    /// date.
    static func code(for date: Date) -> String {
        switch Int((phase(for: date) * 8).rounded()) % 8 {
        case 0: return "NEW · MOON"
        case 1: return "WAX · CRES"
        case 2: return "1ST · QTR"
        case 3: return "WAX · GIB"
        case 4: return "FULL · MOON"
        case 5: return "WAN · GIB"
        case 6: return "LAST · QTR"
        default: return "WAN · CRES"
        }
    }

    /// Convenience for "today's moon" — used only where a live indicator
    /// makes sense; keepsake views should pass the reading-time date via
    /// `code(for:)`.
    static var currentPhase: Double { phase(for: Date()) }
    static var currentCode: String { code(for: Date()) }
}

struct OrbitLoader: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let inner: [(String, Double, Double)] = [("☉", 7, 0), ("☽", 9, 120), ("☿", 11, 240)]
    private let outer: [(String, Double, Double)] = [("♀", 16, 0), ("♂", 18, 90), ("♃", 22, 180), ("♄", 26, 270)]

    var body: some View {
        // Keep the `TimelineView(.animation)` at the body root so SwiftUI
        // can't lose track of it through wrapper-view identity changes.
        // When Reduce Motion is enabled we freeze the timeline reference to
        // a constant 0 — planets sit at their initial angles with no
        // rotation or scale pulse — but the TimelineView itself is still
        // ticking, which keeps the animation pipeline alive.
        TimelineView(.animation) { ctx in
            let t: TimeInterval = reduceMotion ? 0 : ctx.date.timeIntervalSinceReferenceDate
            ZStack {
                Circle().stroke(DesignSystem.ColorToken.goldCream.opacity(0.18), style: .init(lineWidth: 1, dash: [2,4])).frame(width: 140, height: 140)
                Circle().stroke(DesignSystem.ColorToken.goldCream.opacity(0.14), style: .init(lineWidth: 1, dash: [2,4])).frame(width: 260, height: 260)
                Circle().fill(RadialGradient(colors: [DesignSystem.ColorToken.goldCream.opacity(0.25), .clear], center: .center, startRadius: 0, endRadius: 55)).frame(width: 110, height: 110)
                Image("PalmPlate").resizable().scaledToFit().frame(width: 82, height: 82).opacity(0.72)
                ForEach(0..<inner.count, id: \.self) { i in orbit(inner[i], t, 70) }
                ForEach(0..<outer.count, id: \.self) { i in orbit(outer[i], t, 130) }
            }.frame(width: 320, height: 320)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Mystical loading indicator")
    }

    private func orbit(_ item: (String, Double, Double), _ t: TimeInterval, _ radius: CGFloat) -> some View {
        let angle = (item.2 + (t / item.1) * 360) * .pi / 180
        let pulse = 1 + 0.08 * sin(t * .pi / 1.2)
        return Text(item.0).font(DesignSystem.FontToken.display(22)).foregroundStyle(DesignSystem.ColorToken.goldCream).shadow(color: DesignSystem.ColorToken.goldCream.opacity(0.55), radius: 6).scaleEffect(pulse).offset(x: cos(angle) * radius, y: sin(angle) * radius)
    }
}

struct LoadingPulseDots: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                if reduceMotion {
                    Circle()
                        .fill(DesignSystem.ColorToken.goldCream.opacity(0.72))
                        .frame(width: 6, height: 6)
                } else {
                    LoadingPulseDot(delay: Double(index) * 0.18)
                }
            }
        }
    }
}

private struct LoadingPulseDot: View {
    let delay: Double
    @State private var scale: CGFloat = 0.7
    @State private var opacity: Double = 0.25

    var body: some View {
        Circle()
            .fill(DesignSystem.ColorToken.goldCream.opacity(0.6))
            .frame(width: 6, height: 6)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.7).repeatForever().delay(delay)) {
                    scale = 1
                    opacity = 1
                }
            }
    }
}

extension View {
    func darkScreen() -> some View { ZStack { DarkScreenBackground(); self } }

    /// Re-enable the iOS interactive swipe-back gesture even when the
    /// navigation back button is hidden via `.navigationBarBackButtonHidden(true)`.
    ///
    /// Background: SwiftUI ties the system left-edge swipe gesture to the
    /// back button by default. When the back button is hidden — which every
    /// PalmAura screen does in favour of the custom `ScreenHeader` chrome —
    /// the swipe gesture is also disabled. iOS users expect the swipe to
    /// work; without it, navigation feels broken.
    ///
    /// This modifier injects an invisible `UIViewControllerRepresentable`
    /// that walks up to the hosting `UINavigationController` (which
    /// `NavigationStack` uses under the hood as of iOS 16+) and sets the
    /// `interactivePopGestureRecognizer.delegate = nil`, which re-enables
    /// the gesture independently of the back button visibility.
    ///
    /// Safe to apply more than once. Apply once per navigable screen. Pass
    /// `false` for terminal/in-flight screens where popping would duplicate a
    /// submission or expose an invalid previous state.
    func swipeBackEnabled(_ isEnabled: Bool = true) -> some View {
        background(NavigationBackSwipeEnabler(isEnabled: isEnabled))
    }
}

/// Invisible UIKit shim that re-enables the system interactive pop gesture
/// for the enclosing `UINavigationController`. See `View.swipeBackEnabled()`
/// for the rationale.
private struct NavigationBackSwipeEnabler: UIViewControllerRepresentable {
    let isEnabled: Bool

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Defer to the next runloop tick so the view is attached to its
        // navigation controller before we mutate the gesture delegate.
        DispatchQueue.main.async {
            guard let navController = uiViewController.parent?.navigationController
                ?? uiViewController.navigationController else { return }
            guard isEnabled, navController.viewControllers.count > 1 else {
                navController.interactivePopGestureRecognizer?.isEnabled = false
                return
            }
            navController.interactivePopGestureRecognizer?.delegate = nil
            navController.interactivePopGestureRecognizer?.isEnabled = true
        }
    }
}
