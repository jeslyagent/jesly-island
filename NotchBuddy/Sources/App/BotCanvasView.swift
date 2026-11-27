import SwiftUI

/// La nube de puntos de JESLY en la isla del notch (Fase 2, sesión 3).
/// Reemplaza el dibujo de Mochi (`BotEngine`): la API se mantiene
/// (`state`, `particleOverhang`, `lookOriginOverride`, `paused`) para no
/// tocar a sus llamadores (`IslandRootView`, `IslandWindowController`,
/// `CornerIsland`). `BotEngine` sigue en el árbol pero ya no dibuja la isla;
/// los estados de ánimo, bailes, morph y voz de Mochi no tienen equivalente
/// en la nube (respira, parpadea y sonríe al escuchar).
struct BotCanvasView: View {
    @ObservedObject var state: AppState
    var particleOverhang: CGFloat = 0
    var lookOriginOverride: CGPoint? = nil
    var paused: Bool = false

    var body: some View {
        if paused {
            Color.clear
        } else {
            GeometryReader { geo in
                SmokeCloudView(
                    size: min(geo.size.width, geo.size.height),
                    listening: state.voiceActive
                )
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
    }
}

/// Mini nube para las pills de agente y la esquina (antes mini Mochi).
/// Mantiene la API (`task`, `isDancing`) para no tocar a sus llamadores;
/// el color de la tarea se ignora: la nube es blanca por diseño.
struct MiniBotCanvasView: View {
    let task: AgentTask
    var isDancing: Bool = false

    var body: some View {
        GeometryReader { geo in
            SmokeCloudView(size: min(geo.size.width, geo.size.height))
                .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

// MARK: - Frame clock (se mantiene: lo usan DesktopMochi, FlowHubMochis, FlowHubRoom, FlowPill, IslandViewContent)

/// Mochi's engine moves one `update(dt: 0.05)` per 60 Hz frame: his look, colour, springs and
/// particles are tuned to that. He is drawn at most 60 times a second (30 folded and for the
/// minis), so a 120 Hz screen no longer doubles his speed and his CPU cost (#1116), and a frame
/// drawn at 30 fps runs two steps. A fixed number of steps per drawn frame, not the measured
/// time between renders: that jitter froze him (0 steps) or made him jump (2+) several times
/// a second.
@MainActor
enum MochiFrameClock {
    /// The rate the engine is tuned to.
    static let engineFPS: Double = 60
    /// The mini Mochis (pills, compact island, corner).
    static let miniFPS: Double = 30

    /// The main Mochi: 60 while the island is open, 30 folded in the notch.
    static func fps(open: Bool) -> Double { open ? 60 : 30 }

    /// minimumInterval for a target rate, 10 % short: display frames come every 16.6 ms
    /// with jitter, and an interval of exactly 1/60 s skipped every other one (30 fps on a
    /// 60 Hz screen). 60 on a 60 Hz screen draws every frame; on ProMotion, one in two.
    static func interval(fps: Double) -> TimeInterval { 0.9 / fps }

    /// Engine steps for one frame drawn at `fps`: 1 at 60, 2 at 30.
    static func steps(fps: Double) -> Int { max(1, Int((engineFPS / fps).rounded())) }

    static func advance(_ engine: BotEngine, fps: Double = 60) {
        for _ in 0..<steps(fps: fps) { engine.update(dt: 0.05) }
    }
}
