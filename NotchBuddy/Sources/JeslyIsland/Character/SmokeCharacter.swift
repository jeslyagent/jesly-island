import CoreGraphics
import Foundation

/// Matemática del personaje de JESLY: una nube de humo blanca.
///
/// Lógica pura, sin AppKit ni SwiftUI: se prueba sin compilar la app
/// (`Tests/JeslyIslandTests/SmokeCharacterTests.swift`). La vista
/// (`SmokeCloudView`) solo dibuja lo que estas funciones calculan.
///
/// La maqueta aprobada de la esfera de humo (artifact
/// maqueta-esfera-jarvis v8) es la referencia visual. Nada de Mochi:
/// ni su forma, ni su nombre, ni sus sonidos, ni sus colores.
///
/// - Respiración en espera: la nube crece y encoge despacio.
/// - Parpadeos: cada pocos segundos, los ojos se cierran un instante.
/// - Ojos que siguen el cursor: las pupilas se mueven hacia el mouse.
/// - Saltito de alegría: al terminar un agente, la nube salta.
public enum SmokeCharacter {
    /// Escala de la respiración en el instante `time` (segundos).
    /// Periodo 3 s, amplitud ±3%: despacio, como Coucou en espera.
    public static func breathScale(at time: TimeInterval) -> Double {
        1.0 + 0.03 * sin(2.0 * .pi * time / 3.0)
    }

    /// Apertura de los ojos (1 = abiertos, 0 = cerrados) en `time`.
    /// Parpadeo cada 4 s, dura 0,12 s. El parpadeo es una rampa de
    /// bajada y subida, no un corte seco.
    public static func eyeOpenness(at time: TimeInterval) -> Double {
        let cycle = time.truncatingRemainder(dividingBy: 4.0)
        let blinkDuration = 0.12
        guard cycle < blinkDuration else { return 1.0 }
        let half = blinkDuration / 2.0
        if cycle < half {
            return 1.0 - (cycle / half)
        }
        return (cycle - half) / half
    }

    /// Desplazamiento de la pupila hacia el cursor.
    /// `cursor` en coordenadas de la vista; `size` es el tamaño de la
    /// nube. El desplazamiento se limita a `maxOffset` puntos para que
    /// la pupila nunca salga del ojo.
    public static func pupilOffset(
        cursor: CGPoint,
        size: CGSize,
        maxOffset: CGFloat = 4.0
    ) -> CGVector {
        guard size.width > 0, size.height > 0 else { return CGVector.zero }
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let dx = cursor.x - center.x
        let dy = cursor.y - center.y
        let distance = sqrt(dx * dx + dy * dy)
        guard distance > 0.001 else { return CGVector.zero }
        let scale = min(maxOffset / distance, 1.0)
        // En la vista, Y crece hacia abajo; la pupila sigue al cursor.
        return CGVector(dx: dx * scale, dy: dy * scale)
    }

    /// Altura del saltito de alegría, en puntos.
    /// `elapsed` son los segundos desde que terminó el agente.
    /// Dura 0,6 s: sube y baja en parábola, con pico de 10 pt.
    public static func joyHopHeight(elapsed: TimeInterval) -> Double {
        let duration = 0.6
        guard elapsed >= 0, elapsed <= duration else { return 0 }
        let t = elapsed / duration
        return 10.0 * 4.0 * t * (1.0 - t)
    }

    /// ¿Está saltando de alegría en este instante?
    public static func isHopping(elapsed: TimeInterval?) -> Bool {
        guard let elapsed else { return false }
        return elapsed >= 0 && elapsed <= 0.6
    }
}
