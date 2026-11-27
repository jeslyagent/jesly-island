import Combine
import Foundation

/// Regla "Siempre": la isla aprueba sola las próximas propuestas del
/// mismo agente y tipo, sin que JC tenga que tocar nada.
///
/// Porte verbatim de la isla actual (`IslandStore.swift`, HEAD
/// `3e2a59db`): la misma clave de UserDefaults
/// (`com.jesly.island.alwaysRules`), así que las reglas que JC ya
/// creó en la isla actual se leen igual desde el fork.
///
/// Como Coucou: la decisión solo vale para lo que está esperando —
/// cada aprobación pasa por el endpoint real
/// `POST /v1/tasks/:id/approve` de esa propuesta concreta, queda en
/// la auditoría del servidor y la isla la muestra en el registro.
/// La regla se revoca en Ajustes. Sin regla no hay ninguna
/// aprobación automática, nunca.
public struct AlwaysRule: Codable, Equatable, Identifiable {
    public var id: String { "\(agentId):\(kind)" }
    public var agentId: String
    public var kind: String
    public var createdAt: Date

    public init(agentId: String, kind: String, createdAt: Date = Date()) {
        self.agentId = agentId
        self.kind = kind
        self.createdAt = createdAt
    }
}

/// Estado de las propuestas de JESLY en el fork (Fase 3, sesión 2).
///
/// Lee las tres listas de `JeslyProposalsPoller` (sesión 1) y pone
/// la primera propuesta —esperando, luego planificada, luego
/// aplicada— en la tarjeta que toca: esperando → `JeslyProposalView`
/// (sesión 2); planificada/aplicada → `JeslySessionView` (sesión 3),
/// que lleva los mismos botones de esa tarea. La tarjeta nunca habla con el hook de Coucou: cada botón llama a
/// `JeslyAPIClient.proposalAction(_:taskId:)` con el `task id`
/// exacto de la propuesta que está en pantalla, y la decisión solo
/// vale para esa propuesta.
///
/// Con la API apagada no aparece ninguna tarjeta nueva y no hay
/// errores: el poller conserva las listas anteriores (sesión 1) y
/// la pill muestra 0 propuestas pendientes.
@MainActor
final class JeslyProposalStore: ObservableObject {
    static let shared = JeslyProposalStore()

    /// La propuesta que muestra la tarjeta, nil cuando no hay ninguna.
    /// Orden: esperando → planificada → aplicada.
    @Published private(set) var current: JeslyTask?
    /// Cuántas propuestas hay en total (la tarjeta muestra "1/N").
    @Published private(set) var totalCount: Int = 0
    /// Motivo del último fallo al actuar, nil cuando fue bien.
    @Published private(set) var lastError: String?
    /// Último informe de verificación (Fase 4, sesión 1), nil si
    /// aún no se verificó nada en esta ronda.
    @Published private(set) var lastVerification: JeslyVerificationReport?
    /// Último resultado de publicación (Fase 4, sesión 1).
    @Published private(set) var lastPublish: JeslyPublishRecord?

    /// Reglas "Siempre", guardadas en UserDefaults (solo agente+tipo).
    @Published var alwaysRules: [AlwaysRule] = [] {
        didSet { saveAlwaysRules() }
    }

    /// Aprobaciones automáticas por regla, para el registro.
    @Published private(set) var autoApprovedLog: [String] = []

    private var cancellables = Set<AnyCancellable>()
    private var started = false
    /// Ids ya decididos por JC en esta ronda: no vuelven a la tarjeta
    /// aunque el poller conserve la lista vieja con la API apagada.
    /// Se limpian en cada sondeo que llega bien a la API.
    private var decidedIds: Set<String> = []
    /// Ids con una auto-aprobación en vuelo: no se aprueban dos veces.
    private var autoApprovingIds: Set<String> = []
    private let alwaysRulesKey = "com.jesly.island.alwaysRules"

    private init() {
        if let data = UserDefaults.standard.data(forKey: alwaysRulesKey),
           let rules = try? JSONDecoder().decode([AlwaysRule].self, from: data) {
            self.alwaysRules = rules
        }
    }

    private func saveAlwaysRules() {
        if let data = try? JSONEncoder().encode(alwaysRules) {
            UserDefaults.standard.set(data, forKey: alwaysRulesKey)
        }
    }

    /// Empieza a observar el poller (y si la pill se desactiva).
    /// Lo llama `AppDelegate.setupIsland`, junto al poller.
    func start() {
        guard !started else { return }
        started = true
        let poller = JeslyProposalsPoller.shared
        Publishers.CombineLatest3(poller.$proposals, poller.$plannedProposals, poller.$appliedProposals)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in self?.refresh() }
            }
            .store(in: &cancellables)
        AppState.shared.$activeIntegrations
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in self?.refresh() }
            }
            .store(in: &cancellables)
    }

    /// Recalcula `current` desde las listas del poller y abre/cierra
    /// la tarjeta. También aplica las reglas "Siempre" a lo que está
    /// esperando (cada aprobación pasa por el endpoint real).
    private func refresh() {
        let poller = JeslyProposalsPoller.shared
        let pillActive = AppState.shared.activeIntegrations.contains(JeslyProposalsPoller.pillId)
        if poller.apiReachable {
            // El sondeo llegó bien: la lista es fresca, se puede olvidar
            // lo decidido en rondas anteriores.
            decidedIds.removeAll()
        }
        let all = pillActive
            ? (poller.proposals + poller.plannedProposals + poller.appliedProposals)
                .filter { !decidedIds.contains($0.id) }
            : []
        current = all.first
        totalCount = all.count
        if !all.isEmpty {
            applyAlwaysRules(to: poller.proposals)
        }
        syncIsland()
    }

    /// Abre la tarjeta que toca según lo que hay: permiso esperando →
    /// `.jeslyProposal` (sesión 2, intacta); trabajo en curso
    /// (planificada/aplicada) → `.jeslySession` (sesión 3), que lleva
    /// los mismos botones de esa tarea (Aplicar/Ejecutar/Descartar/
    /// Revertir). Nunca roba la isla de un permiso o una pregunta de
    /// Coucou que JC esté respondiendo, ni de una vista en la que esté
    /// trabajando (chat, ajustes…): en ese caso la tarjeta espera a
    /// que vuelva al home.
    private func syncIsland() {
        let state = AppState.shared
        if let task = current {
            guard state.pendingApproval == nil, state.pendingQuestion == nil else { return }
            // Lo que espera permiso manda; lo demás es sesión en vivo.
            let target: IslandView = task.status == "esperando_aprobacion" ? .jeslyProposal : .jeslySession
            guard state.view != target else { return }
            if state.mode == .expanded {
                switch state.view {
                case .overview, .empty, .finished, .error, .jeslyProposal, .jeslySession:
                    state.view = target
                default:
                    return
                }
            } else {
                // Como las alertas de Coucou: fuerza la apertura.
                NotificationCenter.default.post(name: .hookExpand, object: target)
            }
        } else if state.view == .jeslyProposal || state.view == .jeslySession {
            state.view = state.tasks.isEmpty ? .empty : .overview
        }
    }

    // MARK: - Acciones sobre una propuesta

    /// Una acción de `availableActions` sobre la propuesta exacta.
    /// `POST /v1/tasks/:id/<acción>`; la decisión solo vale para
    /// ese `task id` — JESLY no tiene hook, no hay fd que mantener
    /// abierto hasta el clic como hace Coucou.
    func act(_ action: ProposalAction, on task: JeslyTask) async {
        do {
            let client = JeslyAPIClient()
            _ = try await client.proposalAction(action, taskId: task.id)
            lastError = nil
            decidedIds.insert(task.id)
            JeslyProposalsPoller.shared.refreshNow()
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - Verificación y publicación (Fase 4, sesión 1)

    /// Verificar una tarea `aplicada` contra el sistema VIVO.
    /// `POST /v1/tasks/:id/verify`. Solo `aplicada` (409 si no).
    /// Un veredicto con fallos responde 200: no es excepción, queda
    /// en `lastVerification` y la tarjeta muestra qué falló.
    func verify(task: JeslyTask) async {
        do {
            let client = JeslyAPIClient()
            let (_, report) = try await client.verify(taskId: task.id)
            lastVerification = report
            lastError = nil
            JeslyProposalsPoller.shared.refreshNow()
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Publicar una tarea `aplicada`: push + deploy si toca `cloud/`
    /// + verificación contra lo desplegado. `POST /v1/tasks/:id/publish`.
    /// Solo `aplicada` (409 si no). Nunca fusiona a main.
    func publish(task: JeslyTask) async {
        do {
            let client = JeslyAPIClient()
            let (_, record) = try await client.publish(taskId: task.id)
            lastPublish = record
            lastError = nil
            JeslyProposalsPoller.shared.refreshNow()
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Permitir / Denegar / Siempre sobre una propuesta en espera.
    /// "Siempre" crea la regla Y aprueba ESTA propuesta; la regla
    /// solo se aplica a propuestas futuras del mismo agente y tipo.
    func answerPermission(_ answer: PermissionAnswer, for task: JeslyTask) async {        switch answer {
        case .allow:
            await act(.approve, on: task)
        case .deny:
            await act(.reject, on: task)
        case .always:
            let rule = AlwaysRule(agentId: task.agentId ?? "", kind: task.kind)
            if !alwaysRules.contains(rule) { alwaysRules.append(rule) }
            await act(.approve, on: task)
        }
    }

    enum PermissionAnswer {
        case allow
        case deny
        case always
    }

    func revokeAlwaysRule(_ rule: AlwaysRule) {
        alwaysRules.removeAll { $0 == rule }
    }

    private func applyAlwaysRules(to pending: [JeslyTask]) {
        for task in pending {
            let agentId = task.agentId ?? ""
            guard alwaysRules.contains(where: { $0.agentId == agentId && $0.kind == task.kind }) else {
                continue
            }
            guard !autoApprovingIds.contains(task.id) else { continue }
            autoApprovingIds.insert(task.id)
            Task {
                do {
                    let client = JeslyAPIClient()
                    _ = try await client.proposalAction(.approve, taskId: task.id)
                    autoApprovedLog.append("Aprobada sola por regla Siempre: \(task.title)")
                    decidedIds.insert(task.id)
                } catch {
                    lastError = error.localizedDescription
                }
                autoApprovingIds.remove(task.id)
                JeslyProposalsPoller.shared.refreshNow()
            }
        }
        // Las aprobadas en vuelo ya no están esperando: que no se
        // vuelvan a intentar en el próximo sondeo.
        autoApprovingIds = autoApprovingIds.intersection(pending.map(\.id))
    }
}
