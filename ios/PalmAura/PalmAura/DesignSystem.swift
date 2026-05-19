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
        static func display(_ size: CGFloat, italic: Bool = false, weight: Font.Weight = .medium) -> Font {
            .custom(italic ? "CormorantGaramond-MediumItalic" : "CormorantGaramond-Medium", size: size).weight(weight)
        }
        static func body(_ size: CGFloat = 14, italic: Bool = false) -> Font {
            .custom(italic ? "EBGaramond-Italic" : "EBGaramond-Regular", size: size)
        }
        static func caps(_ size: CGFloat = 11) -> Font {
            // Cinzel ships as a variable font with named instances at Regular/Bold/Black only;
            // SemiBold is reached by setting the wght axis via .weight(.semibold).
            .custom("Cinzel-Regular", size: size).weight(.semibold)
        }
        static func hand(_ size: CGFloat = 16) -> Font {
            .custom("Caveat-Regular", size: size)
        }
        static let title = display(26)
        static let footnote = Font.footnote
        static let caption = Font.caption
    }

    enum Tracking { static let caps: CGFloat = 3.5; static let capsLg: CGFloat = 5 }
    enum Spacing { static let xxs: CGFloat = 4; static let xs: CGFloat = 8; static let sm: CGFloat = 12; static let md: CGFloat = 16; static let lg: CGFloat = 24; static let xl: CGFloat = 32; static let xxl: CGFloat = 48; static let screenInset: CGFloat = 24 }
    enum Radius { static let pill: CGFloat = 999; static let cardLg: CGFloat = 22; static let cardMd: CGFloat = 18; static let cardSm: CGFloat = 14; static let tab: CGFloat = 26; static let card: CGFloat = 22; static let hero: CGFloat = 32 }
    enum Motion { static let phraseInterval: TimeInterval = 2.8; static let phraseFade: TimeInterval = 2.8; static let stepAdvance: TimeInterval = 0.22; static let palmIgnitionDuration: TimeInterval = 2.4; static let minimumReadingDuration: TimeInterval = 8 }
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

struct ScreenHeader: View {
    var eyebrow: String = "PalmAura"
    var moon: Bool = true
    var back: Bool = false
    var onBack: (() -> Void)? = nil
    var trailingText: String? = nil
    var onTrailing: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    private var showsContext: Bool {
        let normalized = eyebrow.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return !normalized.isEmpty && normalized != "palmaura"
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(alignment: .center) {
                navIcon(systemName: "house", accessibilityLabel: "Home") {
                    NotificationCenter.default.post(name: .palmAuraNavigateHome, object: nil)
                }

                Spacer(minLength: 8)

                Button {
                    NotificationCenter.default.post(name: .palmAuraNavigateHome, object: nil)
                } label: {
                    HStack(spacing: 8) {
                        Text("PalmAura")
                            .font(DesignSystem.FontToken.caps(12))
                            .tracking(DesignSystem.Tracking.capsLg)
                            .textCase(.uppercase)
                            .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.9))
                        VStack(spacing: 1) {
                            MoonPhase(phase: MoonPhaseProvider.currentPhase)
                            Text(MoonPhaseProvider.currentCode)
                                .font(DesignSystem.FontToken.caps(5.8))
                                .tracking(1.0)
                                .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.64))
                        }
                        .frame(width: 24)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("PalmAura home")

                Spacer(minLength: 8)

                navIcon(systemName: "gearshape", accessibilityLabel: "Settings") {
                    NotificationCenter.default.post(name: .palmAuraNavigateSettings, object: nil)
                }
            }

            if showsContext || back || trailingText != nil {
                HStack(spacing: 8) {
                    if back {
                        Button(action: { if let onBack { onBack() } else { dismiss() } }) {
                            Text("‹ Back")
                                .font(DesignSystem.FontToken.caps(8))
                                .tracking(1.7)
                                .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.58))
                        }
                        .buttonStyle(.plain)
                        .frame(width: 62, alignment: .leading)
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
                .frame(height: 18)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    private func navIcon(systemName: String, accessibilityLabel: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.92))
                .frame(width: 36, height: 36)
                .background(Circle().fill(DesignSystem.ColorToken.goldCream.opacity(0.055)))
                .overlay(Circle().stroke(DesignSystem.ColorToken.goldCream.opacity(0.28), lineWidth: 0.8))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
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

struct MoonPhase: View {
    let phase: Double
    var size: CGFloat = 28
    var body: some View {
        ZStack {
            Circle().fill(DesignSystem.ColorToken.goldCream.opacity(0.10))
            Circle().stroke(DesignSystem.ColorToken.goldCream.opacity(0.4), lineWidth: 0.7)
            Circle().trim(from: 0, to: max(0.08, min(0.92, phase))).fill(DesignSystem.ColorToken.goldCream.opacity(0.75)).rotationEffect(.degrees(-90))
        }.frame(width: size, height: size)
    }
}

enum MoonPhaseProvider {
    static var currentPhase: Double {
        let knownNewMoon = Date(timeIntervalSince1970: 947182440) // 2000-01-06
        let days = Date().timeIntervalSince(knownNewMoon) / 86400
        return (days.truncatingRemainder(dividingBy: 29.53058867)) / 29.53058867
    }
    static var currentCode: String {
        switch Int((currentPhase * 8).rounded()) % 8 {
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
}

struct OrbitLoader: View {
    private let inner: [(String, Double, Double)] = [("☉", 7, 0), ("☽", 9, 120), ("☿", 11, 240)]
    private let outer: [(String, Double, Double)] = [("♀", 16, 0), ("♂", 18, 90), ("♃", 22, 180), ("♄", 26, 270)]
    var body: some View {
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            ZStack {
                Circle().stroke(DesignSystem.ColorToken.goldCream.opacity(0.18), style: .init(lineWidth: 1, dash: [2,4])).frame(width: 140, height: 140)
                Circle().stroke(DesignSystem.ColorToken.goldCream.opacity(0.14), style: .init(lineWidth: 1, dash: [2,4])).frame(width: 260, height: 260)
                Circle().fill(RadialGradient(colors: [DesignSystem.ColorToken.goldCream.opacity(0.25), .clear], center: .center, startRadius: 0, endRadius: 55)).frame(width: 110, height: 110)
                Image("PalmPlate").resizable().scaledToFit().frame(width: 82, height: 82).opacity(0.72)
                ForEach(0..<inner.count, id: \.self) { i in orbit(inner[i], t, 70) }
                ForEach(0..<outer.count, id: \.self) { i in orbit(outer[i], t, 130) }
            }.frame(width: 320, height: 320)
        }
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
}
