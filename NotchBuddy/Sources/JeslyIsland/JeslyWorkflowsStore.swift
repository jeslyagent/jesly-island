import Combine
import Foundation

/// Estado de workflows, habilidades y recordatorios de JESLY en el
/// fork (Fase 5, sesión 1).
///
/// Porte de la lógica de la isla actual (`IslandStore.swift`,
/// HEAD `3e2a59db`): refresca las tres listas cada 15 s y cada
/// acción vuelve a refrescar. Todo best-effort: si la API no
/// responde se mantiene lo último y no hay errores en la interfaz.
///
/// Endpoints reales, nada inventado:
/// - Workflows: `GET /v1/workflows`, `POST /v1/workflows/:id/run`,
///   `PATCH /v1/workflows/:id { enabled }`, `DELETE /v1/workflows/:id`
///   (`routes/workflows.ts`).
/// - Habilidades: `GET /v1/skills`,
///   `POST /v1/skills/:id/test|approve|reject|uninstall`
///   (`routes/skills.ts`).
/// - Recordatorios: `GET /v1/reminders`, `POST /v1/reminders { text }`,
///   `POST /v1/reminders/:id/silence`, `DELETE /v1/reminders/:id`
///   (`routes/reminders.ts`). No hay endpoint "hecho": un
///   recordatorio es un workflow y silenciarlo lo desactiva para
///   que no suene más; el botón "Hecho" llama a silence.
///
/// Con la API apagada las tres listas quedan vacías y `lastError`
/// guarda el motivo, igual que el resto de JESLY.
@MainActor
final class JeslyWorkflowsStore: ObservableObject {
    static let shared = JeslyWorkflowsStore()

    @Published private(set) var workflows: [JeslyWorkflow] = []
    @Published private(set) var skills: [JeslySkill] = []
    @Published private(set) var reminders: [JeslyReminder] = []
    /// ¿La última carga llegó bien a la API?
    @Published private(set) var apiReachable: Bool = false
    /// Motivo del último fallo, nil cuando fue bien.
    @Published private(set) var lastError: String?
    /// Confirmación del último recordatorio creado (fecha y hora
    /// completas, para que JC vea si el parser entendió otro día).
    @Published private(set) var lastReminderConfirmation: String?

    private var started = false
    private var timer: Timer?

    private init() {}

    /// Empieza el sondeo cada 15 s, como la isla actual.
    /// Lo llama `AppDelegate.setupIsland`, junto al poller de
    /// propuestas y al store de voz.
    func start() {
        guard !started else { return }
        started = true
        Task { await refreshAll() }
        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in await self?.refreshAll() }
        }
    }

    /// Recarga las tres listas. Best-effort: si la API no responde
    /// se mantiene lo último.
    func refreshAll() async {
        await refreshWorkflows()
        await refreshSkills()
        await refreshReminders()
    }

    func refreshWorkflows() async {
        do {
            workflows = try await JeslyAPIClient().workflows()
            apiReachable = true
            lastError = nil
        } catch {
            apiReachable = false
            lastError = error.localizedDescription
        }
    }

    func refreshSkills() async {
        do {
            skills = try await JeslyAPIClient().skills()
            apiReachable = true
            lastError = nil
        } catch {
            apiReachable = false
            lastError = error.localizedDescription
        }
    }

    func refreshReminders() async {
        do {
            reminders = try await JeslyAPIClient().reminders()
            apiReachable = true
            lastError = nil
        } catch {
            apiReachable = false
            lastError = error.localizedDescription
        }
    }

    // MARK: - Workflows

    /// Ejecutar ahora. `POST /v1/workflows/:id/run` → 202. El run
    /// crea una tarea que el poller de propuestas ya trae, así que
    /// su progreso se ve como una tarea en curso en la tarjeta de
    /// sesión en vivo.
    func runWorkflow(_ workflow: JeslyWorkflow) async {
        do {
            try await JeslyAPIClient().runWorkflow(id: workflow.id)
            lastError = nil
            JeslyProposalsPoller.shared.refreshNow()
            await refreshWorkflows()
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Pausar / reanudar. `PATCH /v1/workflows/:id { enabled }`.
    func setWorkflowEnabled(_ workflow: JeslyWorkflow, enabled: Bool) async {
        do {
            try await JeslyAPIClient().setWorkflowEnabled(id: workflow.id, enabled: enabled)
            lastError = nil
            await refreshWorkflows()
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Borrar. `DELETE /v1/workflows/:id`.
    func deleteWorkflow(_ workflow: JeslyWorkflow) async {
        do {
            try await JeslyAPIClient().deleteWorkflow(id: workflow.id)
            lastError = nil
            await refreshWorkflows()
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - Habilidades

    /// Acción sobre una habilidad: test / approve / reject /
    /// uninstall. Cada una va por su endpoint real
    /// `POST /v1/skills/:id/<acción>`.
    func skillAction(_ action: JeslySkillAction, skill: JeslySkill) async {
        do {
            let client = JeslyAPIClient()
            switch action {
            case .test: try await client.testSkill(id: skill.id)
            case .approve: try await client.approveSkill(id: skill.id)
            case .reject: try await client.rejectSkill(id: skill.id)
            case .uninstall: try await client.uninstallSkill(id: skill.id)
            }
            lastError = nil
            await refreshSkills()
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - Recordatorios

    /// Crear desde lenguaje natural. `POST /v1/reminders { text }`.
    /// Si la fecha/hora no se entiende, el servidor responde 400
    /// con la pregunta: nunca se adivina una hora en Swift, el
    /// parser vive en la API. La confirmación queda en
    /// `lastReminderConfirmation` para que JC la vea.
    func createReminder(text: String) async {
        do {
            let client = JeslyAPIClient()
            let (_, confirmation) = try await client.createReminder(text: text)
            lastReminderConfirmation = confirmation
            lastError = nil
            await refreshReminders()
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Marcar hecho = silenciar. `POST /v1/reminders/:id/silence`.
    /// No hay endpoint "hecho" en el servidor: silenciar desactiva
    /// el workflow para que no suene más.
    func silenceReminder(_ reminder: JeslyReminder) async {
        do {
            try await JeslyAPIClient().silenceReminder(id: reminder.id)
            lastError = nil
            await refreshReminders()
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Borrar. `DELETE /v1/reminders/:id`.
    func deleteReminder(_ reminder: JeslyReminder) async {
        do {
            try await JeslyAPIClient().deleteReminder(id: reminder.id)
            lastError = nil
            await refreshReminders()
        } catch {
            lastError = error.localizedDescription
        }
    }
}

/// Acción sobre una habilidad, como `SkillAction` en
/// `IslandStore.swift` de la isla actual.
public enum JeslySkillAction: String {
    case test
    case approve
    case reject
    case uninstall
}
