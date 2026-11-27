import Combine
import Foundation

/// Estado de la voz "Oye JESLY" en el fork (Fase 4, sesión 3).
///
/// Dos piezas separadas, como en la isla actual:
///
/// 1. **El demonio siempre activo** (`services/wake-word/daemon.py`,
///    Vosk local): escucha "Oye JESLY" por su cuenta y hace el ciclo
///    completo del lado del servidor (`services/wake-word/cycle.py`:
///    STT → chat → TTS). La app NO graba cuando el demonio oye la
///    frase — eso lo hace el demonio solo. La app solo sondea su
///    estado con `GET /v1/voice/wake/status` cada 5 s (igual que
///    `IslandStore.refreshWake` en la isla) y lo muestra: punto
///    hueso + `WakeStatus.displayText` ("Escuchando «Oye JESLY»",
///    "Te escuchó — pensando…", …). Demonio caído = `listening`
///    false, un estado válido, nunca un error en la interfaz.
///
/// 2. **El modo voz manual** (`VoiceTalker`): el botón del micrófono
///    en el chat. Grabar → transcribir → chat → sintetizar →
///    reproducir, con `interrupt()` para cortar a JESLY en mitad de
///    una frase. El audio vive solo en memoria y se descarta.
///
/// Sin API no hay voz ni ojos y no hay errores en la interfaz: el
/// sondeo deja `wakeStatus` en `.down` y el micrófono muestra el
/// motivo claro de la isla actual.
@MainActor
final class JeslyVoiceStore: ObservableObject {
    static let shared = JeslyVoiceStore()

    /// Estado del demonio "Oye JESLY" (`.down` = no responde).
    @Published private(set) var wakeStatus: WakeStatus = .down
    /// true cuando la última llamada llegó a la API.
    @Published private(set) var apiReachable: Bool = false

    /// El modo voz manual. El cliente y el proveedor se actualizan
    /// antes de grabar (`prepareTalker`), con la clave del llavero
    /// y el proveedor elegido en el chat.
    let talker: VoiceTalker

    private var pollingTask: Task<Void, Never>?

    private init() {
        talker = VoiceTalker(client: JeslyAPIClient(), provider: nil)
    }

    /// Empieza el sondeo del demonio cada 5 s. Se llama una vez
    /// desde `AppDelegate.setupIsland`, junto al poller de
    /// propuestas. No arranca el micrófono: solo pregunta el estado.
    func start() {
        guard pollingTask == nil else { return }
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refreshWake()
                try? await Task.sleep(for: .seconds(5))
            }
        }
    }

    func stop() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    /// Un sondeo del demonio. Demonio caído = `.down`, nunca una
    /// excepción en la interfaz.
    func refreshWake() async {
        do {
            wakeStatus = try await JeslyAPIClient().wakeStatus()
            apiReachable = true
        } catch {
            wakeStatus = .down
            apiReachable = false
        }
    }

    /// Actualiza el cliente y el proveedor del talker antes de
    /// grabar, con la clave del llavero y el proveedor elegido en
    /// el chat (nil = Automático, el router elige).
    func prepareTalker() {
        talker.updateClient(JeslyAPIClient(), provider: JeslyChatStore.shared.selectedProvider)
    }
}
