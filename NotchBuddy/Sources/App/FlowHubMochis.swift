#if !APPSTORE
import AppKit
import SwiftUI

// MARK: - Visible or not

private struct HubVisibleKey: EnvironmentKey {
    static let defaultValue = true
}

extension EnvironmentValues {
    /// Whether the Coucou window is on screen: the Mochis rest (no frame drawn) while it is hidden,
    /// minimized or covered.
    var hubVisible: Bool {
        get { self[HubVisibleKey.self] }
        set { self[HubVisibleKey.self] = newValue }
    }
}

/// Follows the Coucou window's occlusion, for `hubVisible`.
@MainActor
final class HubWindowState: ObservableObject {
    @Published private(set) var visible = true
    private var observers: [NSObjectProtocol] = []

    func watch(_ window: NSWindow) {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        let names: [Notification.Name] = [NSWindow.didChangeOcclusionStateNotification,
                                          NSWindow.didMiniaturizeNotification,
                                          NSWindow.didDeminiaturizeNotification,
                                          NSWindow.willCloseNotification]
        observers = names.map { name in
            NotificationCenter.default.addObserver(forName: name, object: window, queue: .main) { [weak self] note in
                let closing = note.name == NSWindow.willCloseNotification
                MainActor.assumeIsolated {
                    guard let self else { return }
                    let on = !closing && window.occlusionState.contains(.visible) && !window.isMiniaturized
                    if on != self.visible { self.visible = on }
                }
            }
        }
    }
}

// MARK: - The JESLY cloud in the Flow Hub

/// One JESLY cloud that stays where it is (the logo, the empty pages).
/// Fase 2, sesión 2: draws `SmokeCloudView` instead of a mini Mochi.
/// Fase 2, sesión 5: the `outfit` param is gone with the `Outfit` type —
/// JESLY has no outfits. The cloud is white by design, so `color` is
/// ignored. `BotState` has no `.listening` case (listening is a `BotEmote`),
/// so the cloud never shows the listening smile here yet.
struct HubLiveMochi: View {
    var color = "#F5F6F8"
    /// Width of the body; the drawing around it is larger.
    var size: CGFloat = 28
    var state: BotState = .idle

    var body: some View {
        SmokeCloudView(size: size)
            .frame(width: size, height: size * 0.75)
    }
}

// MARK: - The top of each page

/// A page's colour for its hero band.
/// Fase 2, sesión 5: the walking Mochi troupe is gone — JESLY has no
/// Mochis. The band keeps its colour, its backdrop particles and its title.
struct HubHeroTheme {
    var color: Color

    static func of(_ page: HubPage) -> HubHeroTheme {
        switch page {
        case .dictation: return .init(color: Color(hex: "#FB923C"))
        case .notes: return .init(color: Color(hex: "#3B9EFF"))
        case .insights: return .init(color: Color(hex: "#34D399"))
        case .dictionary: return .init(color: Color(hex: "#A78BFA"))
        case .snippets: return .init(color: Color(hex: "#F7B32B"))
        case .styles: return .init(color: Color(hex: "#F472B6"))
        case .settings: return .init(color: Color(hex: "#8E939C"))
        case .room: return .init(color: Color(hex: "#A78BFA"))
        case .general: return .init(color: Color(hex: "#8E939C"))
        case .pills: return .init(color: Color(hex: "#F5A524"))
        case .agents: return .init(color: Color(hex: "#3B9EFF"))
        case .jesly: return .init(color: Color(hex: "#E8E0D0"))
        case .chat: return .init(color: Color(hex: "#E07950"))
        case .integrations: return .init(color: Color(hex: "#7C5CFF"))
        case .voice: return .init(color: Color(hex: "#F97316"))
        case .shortcuts: return .init(color: Color(hex: "#6366F1"))
        case .mailOverview: return .init(color: Color(hex: "#2F8CFF"))
        case .mailRules: return .init(color: Color(hex: "#34D399"))
        case .mailBanned: return .init(color: Color(hex: "#FF453A"))
        case .mailVIP: return .init(color: Color(hex: "#F5A524"))
        }
    }
}

/// The top of a page: a coloured band with the title, a line and an action.
/// Fase 2, sesión 5: no Mochis walk here anymore — the band's backdrop
/// particles are the decoration.
struct HubHero<Trailing: View>: View {
    let page: HubPage
    let title: String
    var subtitle: String?
    var compact = false
    @ViewBuilder var trailing: () -> Trailing
    @StateObject private var light = HubHeroLight()

    var body: some View {
        let theme = HubHeroTheme.of(page)
        ZStack(alignment: .bottomTrailing) {
            HubHeroBackdrop(color: theme.color, light: light)
                .allowsHitTesting(false)
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: compact ? 24 : 30, weight: .bold))
                        .tracking(-0.6)
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#B7BBC2"))
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: 420, alignment: .leading)
                    }
                    Spacer(minLength: 0)
                    trailing()
                }
                .padding(compact ? 20 : 26)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(height: compact ? 116 : 170)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(theme.color.opacity(0.16)))
        // The light follows the pointer over the band.
        .onContinuousHover { phase in
            switch phase {
            case .active(let point): light.target = point
            case .ended:             light.target = nil
            }
        }
    }
}

extension HubHero where Trailing == EmptyView {
    init(page: HubPage, title: String, subtitle: String? = nil, compact: Bool = false) {
        self.page = page
        self.title = title
        self.subtitle = subtitle
        self.compact = compact
        self.trailing = { EmptyView() }
    }
}

/// The light and the particles of a band, moved frame by frame without redrawing the page: the
/// pointer is written here by the hover handler and read by the canvas.
@MainActor
final class HubHeroLight: ObservableObject {
    struct Particle {
        var x: CGFloat, y: CGFloat
        /// Drift, in points per second.
        var vx: CGFloat, vy: CGFloat
        /// Push from the pointer, fading.
        var px: CGFloat = 0, py: CGFloat = 0
        var radius: CGFloat
        var phase: CGFloat
        /// 0.4 (far, slow, dim) to 1 (near, fast, bright).
        var depth: CGFloat
        var white: Bool
    }

    /// The pointer over the band, nil when it is elsewhere.
    var target: CGPoint?
    private(set) var position: CGPoint?
    /// 0 → 1 while the pointer is over the band.
    private(set) var strength: CGFloat = 0
    private(set) var particles: [Particle] = []
    private var size: CGSize = .zero
    private var last = CACurrentMediaTime()
    let start = CACurrentMediaTime()

    func step(size: CGSize) {
        let now = CACurrentMediaTime()
        let dt = CGFloat(min(0.05, max(0, now - last)))
        last = now
        if size != self.size { reset(size) }

        if let target {
            let from = position ?? target
            let k = min(1, dt * 9)
            position = CGPoint(x: from.x + (target.x - from.x) * k, y: from.y + (target.y - from.y) * k)
            strength = min(1, strength + dt * 3.5)
        } else {
            strength = max(0, strength - dt * 1.6)
        }

        let t = CGFloat(now - start)
        for i in particles.indices {
            var p = particles[i]
            // The pointer pushes the particles near it away.
            if let pos = position, strength > 0.01 {
                let dx = p.x - pos.x, dy = p.y - pos.y
                let d = max(1, hypot(dx, dy))
                if d < 120 {
                    let push = pow(1 - d / 120, 2) * 220 * strength * p.depth
                    p.px += dx / d * push * dt
                    p.py += dy / d * push * dt
                }
            }
            p.px *= max(0, 1 - dt * 2.2)
            p.py *= max(0, 1 - dt * 2.2)
            p.x += (p.vx + sin(t * 0.7 + p.phase) * 5 * p.depth) * dt + p.px * dt * 6
            p.y += p.vy * dt + p.py * dt * 6
            // Out of the band: back in on the other side.
            if p.y < -6 { p.y = size.height + 6; p.x = CGFloat.random(in: 0...max(1, size.width)) }
            if p.y > size.height + 8 { p.y = -4 }
            if p.x < -8 { p.x = size.width + 6 }
            if p.x > size.width + 8 { p.x = -6 }
            particles[i] = p
        }
    }

    private func reset(_ size: CGSize) {
        self.size = size
        let count = Int(min(110, max(18, size.width * size.height / 3600)))
        particles = (0..<count).map { _ in
            let depth = CGFloat.random(in: 0.4...1)
            return Particle(x: .random(in: 0...max(1, size.width)), y: .random(in: 0...max(1, size.height)),
                            vx: CGFloat.random(in: -3...3) * depth, vy: CGFloat.random(in: -13 ... -3) * depth,
                            radius: .random(in: 0.5...1.5) * (0.6 + depth * 0.7),
                            phase: .random(in: 0...(2 * .pi)), depth: depth, white: Int.random(in: 0..<9) == 0)
        }
    }
}

/// A band's background: an ultra deep black, the page's colour as a glow that breathes in a
/// corner, and particles drifting up all the time, pushed away by the pointer and brighter near it.
struct HubHeroBackdrop: View {
    let color: Color
    let light: HubHeroLight
    var cornerRadius: CGFloat = 18
    @Environment(\.hubVisible) private var visible

    var body: some View {
        TimelineView(.animation(paused: !visible)) { timeline in
            let frame = timeline.date
            Canvas { context, size in
                _ = frame
                light.step(size: size)
                let rect = CGRect(origin: .zero, size: size)
                let t = CGFloat(CACurrentMediaTime() - light.start)

                // The black, deeper than the card around it.
                context.fill(Path(rect), with: .color(Color(hex: "#020203")))
                // The page's colour, low in the opposite corner and breathing in the top one.
                context.fill(Path(rect), with: .linearGradient(
                    Gradient(colors: [color.opacity(0.10), .clear]),
                    startPoint: CGPoint(x: size.width, y: 0), endPoint: CGPoint(x: size.width * 0.35, y: size.height)))
                let breath = 0.85 + 0.15 * sin(t * 0.9)
                context.fill(Path(rect), with: .radialGradient(
                    Gradient(colors: [color.opacity(0.30 * breath), color.opacity(0.08), .clear]),
                    center: CGPoint(x: size.width * 0.92, y: -size.height * 0.15),
                    startRadius: 0, endRadius: max(size.width, size.height) * 0.55 * breath))

                // The particles.
                for p in light.particles {
                    var alpha = (0.22 + 0.5 * (0.5 + 0.5 * sin(t * (1.2 + p.depth) + p.phase))) * p.depth
                    var radius = p.radius
                    if let pos = light.position, light.strength > 0.01 {
                        let d = hypot(p.x - pos.x, p.y - pos.y)
                        if d < 200 {
                            let near = (1 - d / 200) * light.strength
                            alpha += near * 0.6
                            radius *= 1 + near * 0.8
                        }
                    }
                    let tint = p.white ? Color.white : color
                    let dot = CGRect(x: p.x - radius, y: p.y - radius, width: radius * 2, height: radius * 2)
                    if radius > 1.1 {
                        // A soft halo around the bigger ones.
                        context.fill(Path(ellipseIn: dot.insetBy(dx: -radius * 1.6, dy: -radius * 1.6)),
                                     with: .color(tint.opacity(min(1, alpha) * 0.12)))
                    }
                    context.fill(Path(ellipseIn: dot), with: .color(tint.opacity(min(1, alpha))))
                }
            }
        }
    }
}

/// A card in a colour (the Notetaker's, a setup to do): the bands' deep black, their particles
/// and their light following the pointer.
struct HubGlowCard<Content: View>: View {
    let color: Color
    var padding: CGFloat = 20
    @ViewBuilder var content: () -> Content
    @StateObject private var light = HubHeroLight()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) { content() }
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(HubHeroBackdrop(color: color, light: light, cornerRadius: 14).allowsHitTesting(false))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(color.opacity(0.18)))
            .onContinuousHover { phase in
                switch phase {
                case .active(let point): light.target = point
                case .ended:             light.target = nil
                }
            }
    }
}

/// An empty page: a Mochi asleep, and a line.
struct HubEmptyState: View {
    let text: String
    var state: BotState = .sleeping
    var color = "#F5F6F8"

    var body: some View {
        VStack(spacing: 10) {
            HubLiveMochi(color: color, size: 54, state: state)
                .frame(height: 54)
            Text(text)
                .font(.system(size: 13.5))
                .foregroundColor(HubTheme.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 380)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
    }
}
#endif
