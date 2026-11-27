import SwiftUI

/// La nube de humo blanca de JESLY, dibujada en `Canvas` +
/// `TimelineView` a 60 fps — como Coucou dibuja a Mochi, pero con
/// el personaje propio de JESLY: sin imágenes, sin Rive, sin Lottie.
///
/// Referencia visual: la maqueta aprobada de la esfera de humo
/// (artifact maqueta-esfera-jarvis v8). Paleta neutra: blanco sobre
/// fondo oscuro, con hueso #E8E0D0 como acento.
///
/// Animación (la matemática vive en `SmokeCharacter`, probada):
/// - respiración en espera, parpadeos, ojos que siguen el cursor,
/// - saltito de alegría cuando `joySince` tiene valor (un agente
///   acaba de terminar).
public struct SmokeCloudView: View {
    /// Tamaño de la nube en puntos (120 en el compañero flotante).
    public var size: CGFloat = 120
    /// Instante en que terminó el último agente (para el saltito).
    public var joySince: Date? = nil
    /// Estado de ánimo: la nube se inclina un poco al escuchar.
    public var listening: Bool = false

    @State private var cursor: CGPoint = .zero

    public init(size: CGFloat = 120, joySince: Date? = nil, listening: Bool = false) {
        self.size = size
        self.joySince = joySince
        self.listening = listening
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            let now = timeline.date.timeIntervalSinceReferenceDate
            let breath = SmokeCharacter.breathScale(at: now)
            let openness = SmokeCharacter.eyeOpenness(at: now)
            let hop = SmokeCharacter.joyHopHeight(
                elapsed: joySince.map { Date().timeIntervalSince($0) } ?? -1
            )
            Canvas { context, canvasSize in
                drawCloud(
                    in: &context,
                    size: canvasSize,
                    breath: breath,
                    eyeOpenness: openness,
                    hop: hop
                )
            }
            .frame(width: size, height: size)
            .onContinuousHover { phase in
                if case .active(let location) = phase {
                    cursor = location
                }
            }
        }
    }

    private func drawCloud(
        in context: inout GraphicsContext,
        size: CGSize,
        breath: Double,
        eyeOpenness: Double,
        hop: Double
    ) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2 - hop)
        let baseRadius = min(size.width, size.height) * 0.36 * breath

        // Cuerpo: racimo de círculos blancos con borde suave.
        // Hueso #E8E0D0 como halo exterior, blanco como núcleo.
        let halo = Color(red: 0.91, green: 0.88, blue: 0.82)
        let white = Color.white
        let puffs: [(dx: CGFloat, dy: CGFloat, r: CGFloat)] = [
            (0, 0.10, 1.00),
            (-0.62, 0.22, 0.68),
            (0.62, 0.22, 0.68),
            (-0.34, -0.42, 0.62),
            (0.34, -0.42, 0.62),
            (0, -0.58, 0.55),
            (-0.85, -0.05, 0.45),
            (0.85, -0.05, 0.45),
        ]
        for puff in puffs {
            let puffCenter = CGPoint(
                x: center.x + puff.dx * baseRadius,
                y: center.y + puff.dy * baseRadius
            )
            let path = Path(ellipseIn: CGRect(
                x: puffCenter.x - puff.r * baseRadius,
                y: puffCenter.y - puff.r * baseRadius,
                width: puff.r * baseRadius * 2,
                height: puff.r * baseRadius * 2
            ))
            context.fill(path, with: .color(halo.opacity(0.55)))
        }
        for puff in puffs {
            let puffCenter = CGPoint(
                x: center.x + puff.dx * baseRadius,
                y: center.y + puff.dy * baseRadius
            )
            let radius = puff.r * baseRadius * 0.88
            let path = Path(ellipseIn: CGRect(
                x: puffCenter.x - radius,
                y: puffCenter.y - radius,
                width: radius * 2,
                height: radius * 2
            ))
            context.fill(path, with: .color(white.opacity(0.95)))
        }

        // Ojos: dos óvalos oscuros que parpadean y siguen el cursor.
        let pupil = SmokeCharacter.pupilOffset(cursor: cursor, size: size)
        let eyeSpacing = baseRadius * 0.52
        let eyeY = center.y - baseRadius * 0.05
        let eyeWidth = baseRadius * 0.20
        let eyeHeight = baseRadius * 0.28 * max(eyeOpenness, 0.08)
        for sign in [-1.0, 1.0] {
            let eyeCenter = CGPoint(
                x: center.x + sign * eyeSpacing + pupil.dx,
                y: eyeY + pupil.dy
            )
            let eyePath = Path(ellipseIn: CGRect(
                x: eyeCenter.x - eyeWidth / 2,
                y: eyeCenter.y - eyeHeight / 2,
                width: eyeWidth,
                height: eyeHeight
            ))
            context.fill(eyePath, with: .color(Color.black.opacity(0.85)))
        }

        // Sonrisa pequeña cuando escucha.
        if listening {
            var smile = Path()
            smile.move(to: CGPoint(x: center.x - baseRadius * 0.22, y: center.y + baseRadius * 0.42))
            smile.addQuadCurve(
                to: CGPoint(x: center.x + baseRadius * 0.22, y: center.y + baseRadius * 0.42),
                control: CGPoint(x: center.x, y: center.y + baseRadius * 0.58)
            )
            context.stroke(smile, with: .color(Color.black.opacity(0.7)), lineWidth: max(1.5, baseRadius * 0.05))
        }
    }
}
