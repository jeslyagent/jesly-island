import Combine
import Foundation

/// Poller básico de propuestas de JESLY (Fase 3, sesión 1).
///
/// Cada 5 s —el mismo sondeo que la isla actual— pregunta a la API
/// local `GET /v1/tasks?status=esperando_aprobacion&kind=propuesta`
/// y publica la lista para quien la observe. La tarjeta de
/// Propuesta/Permiso (sesión 2) la leerá desde aquí.
///
/// Comportamiento con la API apagada, a propósito: NO es un error
/// que rompa nada. `apiReachable` pasa a `false`, `lastError` guarda
/// el motivo y la lista anterior se conserva (una lista vieja en
/// pantalla es mejor que un parpadeo a vacío cada 5 s). La pill
/// muestra 0 propuestas pendientes, igual que la isla cuando la API
/// no responde.
///
/// El sondeo solo corre cuando la pill está activa
/// (`AppState.activeIntegrations` contiene `jesly_propuestas`) y se
/// respeta `DemoEngine.isPollerPaused`, como hacen los pollers de
/// Coucou. OJO: Ajustes solo deja 4 pills activas a la vez y por
/// defecto ya hay 4 (Resend, n8n, Vercel, GitHub): para activar
/// `jesly_propuestas` hay que desactivar una. Sin activar la pill,
/// el poller no pega a la API.
///
/// El cliente se crea nuevo en cada sondeo: `JeslyAPIClient.init`
/// lee la clave del llavero al construirse, así que si JC pega la
/// clave en Ajustes (sesión 2) el siguiente sondeo ya la usa, sin
/// reiniciar la app.
@MainActor
final class JeslyProposalsPoller: ObservableObject {
    static let shared = JeslyProposalsPoller()

    /// Id de la pill en `PillCatalog` (categoría agente).
    static let pillId = "jesly_propuestas"
    /// Sondeo cada 5 s, como la isla actual.
    static let pollInterval: TimeInterval = 5

    /// Propuestas esperando aprobación, en el orden que devuelve la API.
    @Published private(set) var proposals: [JeslyTask] = []
    /// false cuando el último sondeo no llegó a la API (apagada o sin red local).
    @Published private(set) var apiReachable: Bool = false
    /// Motivo del último fallo, nil cuando el último sondeo fue bien.
    @Published private(set) var lastError: String?

    private var timer: Timer?
    private var inFlight = false

    private init() {}

    func start() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: Self.pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in await self?.poll() }
        }
        Task { await poll() }
    }

    /// Sondeo inmediato (lo usará la tarjeta de la sesión 2 al enfocarse).
    func refreshNow() {
        Task { await poll() }
    }

    private func poll() async {
        guard !inFlight, !DemoEngine.isPollerPaused else { return }
        guard AppState.shared.activeIntegrations.contains(Self.pillId) else { return }
        inFlight = true
        defer { inFlight = false }
        do {
            // Cliente nuevo por sondeo: relee la clave del llavero cada vez.
            let client = JeslyAPIClient()
            proposals = try await client.pendingProposals()
            apiReachable = true
            lastError = nil
        } catch {
            apiReachable = false
            lastError = error.localizedDescription
            // La lista anterior se conserva a propósito (ver cabecera).
        }
    }
}
