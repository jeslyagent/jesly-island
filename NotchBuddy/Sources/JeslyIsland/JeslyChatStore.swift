import Combine
import Foundation

/// Un mensaje del chat de JESLY.
///
/// El modelo es el REAL de la respuesta (`ChatResponse.model`): el
/// router elige por llamada y la API no acepta fijarlo, así que
/// nunca se inventa ni se adivina. Si la respuesta no trae modelo,
/// la fila no muestra ninguno.
public struct JeslyChatMessage: Identifiable, Equatable {
    public var id = UUID()
    public var role: Role
    public var text: String
    /// Proveedor que respondió (`ChatResponse.provider`), solo en
    /// respuestas de JESLY.
    public var provider: String?
    /// Modelo real que respondió (`ChatResponse.model`).
    public var model: String?
    /// Insignia de visión ("Vio: proveedor / modelo"), solo cuando
    /// la respuesta trae `vision` (ojos, Fase 4, sesión 3).
    public var visionBadge: String?

    public enum Role: String, Equatable {
        case user
        case jesly
    }

    public init(role: Role, text: String, provider: String? = nil, model: String? = nil, visionBadge: String? = nil) {
        self.role = role
        self.text = text
        self.provider = provider
        self.model = model
        self.visionBadge = visionBadge
    }
}

/// Estado del chat de JESLY en el fork (Fase 4, sesión 2).
///
/// La vista es `JeslyChatView`; el historial vive aquí, no en la
/// vista, para que no se pierda al cambiar de vista en la isla.
///
/// Igual que la isla actual (`IslandStore.sendChat`, HEAD
/// `3e2a59db`): cada envío va por `JeslyAPIClient.chat` con el
/// proveedor elegido (nil = Automático, el router elige) y la clave
/// del llavero; la respuesta guarda proveedor y modelo reales. Sin
/// API no hay chat: el envío falla con el motivo claro y la vista
/// lo muestra como mensaje de JESLY, igual que la isla actual —
/// nunca un error que rompa la interfaz.
///
/// Los ojos (Fase 4, sesión 3) llegan por `send(_:attachments:)`
/// y el micrófono vive en `JeslyVoiceStore` / `VoiceTalker`; la
/// vista los cablea sin tocar este flujo.
@MainActor
final class JeslyChatStore: ObservableObject {
    static let shared = JeslyChatStore()

    /// Historial de esta sesión de chat (no persiste entre arranques).
    @Published private(set) var messages: [JeslyChatMessage] = []
    /// Proveedor elegido, nil = Automático (el router elige).
    /// Se guarda en UserDefaults para que sobreviva al reinicio.
    @Published var selectedProvider: String? {
        didSet {
            UserDefaults.standard.set(selectedProvider, forKey: providerKey)
        }
    }
    /// true mientras una respuesta está en vuelo.
    @Published private(set) var sending: Bool = false
    /// true cuando la última llamada llegó a la API.
    @Published private(set) var apiReachable: Bool = false
    /// Motivo del último fallo al enviar, nil cuando fue bien.
    @Published private(set) var lastError: String?

    private let providerKey = "com.jesly.island.chatProvider"

    private init() {
        self.selectedProvider = UserDefaults.standard.string(forKey: providerKey)
    }

    /// Etiqueta del chip de proveedor, igual que la isla actual:
    /// "Automático" o "Nombre · Auto".
    var providerLabel: String {
        if let id = selectedProvider, let provider = JeslyChatProvider.byId(id) {
            return "\(provider.displayName) · Auto"
        }
        return "Automático"
    }

    /// Cambia de proveedor como la isla actual: Automático →
    /// Ollama → FreeLLMAPI → Groq → Gemini → OpenRouter.
    func cycleProvider() {
        let order: [String?] = [nil] + JeslyChatProvider.all.map { $0.id }
        let idx = order.firstIndex(of: selectedProvider) ?? 0
        selectedProvider = order[(idx + 1) % order.count]
    }

    /// Envía un mensaje y añade la respuesta. Sin API, la respuesta
    /// es el mensaje de error claro de la isla actual, no una
    /// excepción en la interfaz.
    ///
    /// `attachments` son los ojos (Fase 4, sesión 3): imágenes o
    /// video en base64 que van por `POST /v1/chat` con el mismo
    /// formato exacto de la isla actual (`ChatAttachment`: kind,
    /// mediaType, data). La respuesta puede traer `vision` y la
    /// fila muestra la insignia "Vio: proveedor / modelo".
    func send(_ text: String, attachments: [ChatAttachment] = []) async {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sending, !query.isEmpty || !attachments.isEmpty else { return }
        sending = true
        defer { sending = false }
        messages.append(JeslyChatMessage(role: .user, text: query.isEmpty ? "Mira este adjunto y dime qué ves." : query))
        do {
            let client = JeslyAPIClient()
            let response = try await client.chat(message: query, provider: selectedProvider, attachments: attachments)
            apiReachable = true
            lastError = nil
            let badge = response.vision.map { "Vio: \($0.provider) / \($0.model)" }
            messages.append(JeslyChatMessage(
                role: .jesly, text: response.text,
                provider: response.provider, model: response.model,
                visionBadge: badge
            ))
        } catch {
            apiReachable = false
            lastError = error.localizedDescription
            messages.append(JeslyChatMessage(
                role: .jesly,
                text: "No pude hablar con la API. Revisa que esté arrancada."
            ))
        }
    }

    /// Añade al historial un intercambio de voz ya completado por
    /// `VoiceTalker` (que hace su propio ciclo grabar → chat →
    /// hablar). El modelo no se muestra: el talker solo guarda el
    /// texto de la respuesta, nunca un modelo inventado.
    func appendVoiceExchange(heard: String, reply: String) {
        guard !heard.isEmpty, !reply.isEmpty else { return }
        messages.append(JeslyChatMessage(role: .user, text: heard))
        messages.append(JeslyChatMessage(role: .jesly, text: reply, provider: selectedProvider))
    }

    /// Limpia el historial de esta sesión.
    func clearHistory() {
        messages = []
        lastError = nil
    }
}
