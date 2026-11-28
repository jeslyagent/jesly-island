import SwiftUI

/// Tarjeta de sesión en vivo de JESLY en la isla (Fase 3, sesión 3).
///
/// Porte de la cabecera + pasos de `IslandHomeView` de la isla actual
/// (`jeslyagent/Jesly-agent-ai`, `apps/island/Sources/JeslyIsland/Views/IslandHomeView.swift`,
/// HEAD `3e2a59db`): la "sesión" de JESLY es la tarea en curso — no
/// hay sesiones de terminal ni hook, así que cada dato sale de las
/// tres listas que ya sondea `JeslyProposalsPoller` (sesión 1):
/// `GET /v1/tasks?status=...&kind=propuesta`. NO se usa
/// `GET /v1/tasks/:id`: la isla actual tampoco lo usa para esto.
///
/// Lo que muestra, todo real y nada inventado:
///   cabecera "Sesión en vivo" + rama de la primera tarea activa
///     ("rama X"; sin sesión: "Sin sesión activa" o
///     "API local sin responder");
///   contador de diff del primer parche (archivo +N −M), contado
///     de verdad por `JeslyPatchStats` (líneas `+`/`-` sin contar
///     las cabeceras `+++`/`---`, igual que la isla);
///   pasos: las aplicadas arriba (✓) y las planificadas + en espera
///     abajo (anillo hueco estático), máx. 4, con la hora HH:mm de `updatedAt`.
///   Sin tareas: "Nada en curso. Cuando un agente proponga algo,
///     aparece aquí."
///   Debajo, los botones de la tarea en curso (Aplicar / Ejecutar /
///     Descartar / Revertir), los mismos de la tarjeta de la sesión 2:
///     la tarjeta de Propuesta/Permiso solo se abre ya para lo que
///     espera permiso; lo planificado/aplicado vive aquí.
///   Fase 4, sesión 1: si la tarea está en `aplicada`, dos botones
///     más — Verificar (`POST /v1/tasks/:id/verify`, contra el
///     sistema VIVO) y Publicar (`POST /v1/tasks/:id/publish`,
///     push + deploy si toca `cloud/`). En cualquier otro estado el
///     servidor responde 409, así que no se muestran.
///
/// Con la API apagada no aparece la tarjeta (el poller no trae nada
/// nuevo y la pill muestra 0 propuestas, sesiones 1–2).
struct JeslySessionView: View {
    @ObservedObject private var poller = JeslyProposalsPoller.shared
    @ObservedObject private var store = JeslyProposalStore.shared

    @State private var working: Bool = false
    @State private var feedback: String?
    @State private var feedbackIsError: Bool = false
    /// La tarea a la que pertenece el feedback: si la tarjeta ya pasó
    /// a la siguiente, el texto viejo no se muestra.
    @State private var feedbackForId: String?

    /// La tarea en curso que muestra la tarjeta: la primera
    /// planificada o aplicada. Lo que espera permiso no vive aquí:
    /// eso lo muestra `JeslyProposalView` (sesión 2).
    private var sessionTask: JeslyTask? {
        guard let task = store.current, task.status != "esperando_aprobacion" else { return nil }
        return task
    }

    var body: some View {
        // Capturado al dibujar: un clic actúa sobre la tarea que
        // estaba en pantalla, y se ignora si la tarjeta ya pasó a
        // la siguiente (igual que `shownId` en `JeslyProposalView`).
        let task = sessionTask
        let shownId = task?.id
        ZStack {
            CardBackground(wash: nil)
            VStack(alignment: .leading, spacing: 8) {
                // Cabecera: punto vivo + "Sesión en vivo" + rama + diff.
                HStack(spacing: 8) {
                    Circle()
                        .fill(poller.apiReachable ? Color(hex: "#E8E0D0") : Color(hex: "#8E939C"))
                        .frame(width: 8, height: 8)
                    Text("Sesión en vivo")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "#F5F6F8"))
                    Text(sessionBranchText)
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#8E939C"))
                        .lineLimit(1)
                    Spacer()
                    if let ticker = diffTicker {
                        HStack(spacing: 6) {
                            Text(ticker.file)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(hex: "#F5F6F8"))
                            Text("+\(ticker.add)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(hex: "#F5F6F8"))
                            Text("−\(ticker.del)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(hex: "#8E939C"))
                        }
                    }
                }
                // Pasos de la sesión, derivados de las listas reales.
                ForEach(sessionSteps) { step in
                    HStack(spacing: 10) {
                        JeslyStepIcon(state: step.state)
                        Text(step.label)
                            .font(.system(size: 13))
                            .foregroundColor(step.state == .running ? Color(hex: "#F5F6F8") : Color(hex: "#8E939C"))
                            .lineLimit(1)
                        Spacer()
                        if !step.time.isEmpty {
                            Text(step.time)
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: "#8E939C"))
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 5)
                    .background(step.state == .running ? Color.white.opacity(0.05) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                if sessionSteps.isEmpty {
                    Text("Nada en curso. Cuando un agente proponga algo, aparece aquí.")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#8E939C"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 5)
                }
                // Botones de la tarea en curso (sesión 2, mismo backend).
                if let task {
                    HStack(spacing: 8) {
                        ForEach(task.availableActions, id: \.self) { action in
                            if action == primaryAction(for: task) {
                                PrimaryButton(verbatim: action.shortTitle) {
                                    Task { await run(action, shownId: shownId) }
                                }
                            } else {
                                SecondaryButton(verbatim: action.shortTitle) {
                                    Task { await run(action, shownId: shownId) }
                                }
                            }
                        }
                    }
                    .padding(.top, 4)
                    .disabled(working)
                    // Verificación y publicación (Fase 4, sesión 1):
                    // solo tareas en `aplicada` — el servidor responde
                    // 409 en cualquier otro estado. Verificar corre el
                    // verificador contra el sistema VIVO con las
                    // comprobaciones locales por defecto; Publicar hace
                    // push + deploy si toca `cloud/` + verificación
                    // contra lo desplegado. Nunca fusionan a main.
                    if task.status == "aplicada" {
                        HStack(spacing: 8) {
                            PrimaryButton(verbatim: "Verificar") {
                                Task { await runVerify(shownId: shownId) }
                            }
                            SecondaryButton(verbatim: "Publicar") {
                                Task { await runPublish(shownId: shownId) }
                            }
                        }
                        .padding(.top, 4)
                        .disabled(working)
                    }
                }
                if let feedback, feedbackForId == shownId {
                    Text(feedback)
                        .font(.system(size: 12.5))
                        .foregroundColor(feedbackIsError ? .orange : Color(hex: "#E8E0D0"))
                        .padding(.top, 4)
                }
                if working {
                    ProgressView().controlSize(.small).padding(.top, 4)
                }
            }
            .padding(.leading, 116)
            .padding(.trailing, 16)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// La rama de la primera tarea activa; sin sesión, el estado real.
    /// (Igual que la isla: `store.allProposals` en el mismo orden
    /// esperando → planificada → aplicada.)
    private var sessionBranchText: String {
        let all = poller.proposals + poller.plannedProposals + poller.appliedProposals
        if let branch = all.first(where: { $0.branch != nil })?.branch {
            return "rama \(branch)"
        }
        return poller.apiReachable ? "Sin sesión activa" : "API local sin responder"
    }

    /// El diff de la primera tarea con parche, contado de verdad.
    private var diffTicker: JeslyPatchTicker? {
        let all = poller.proposals + poller.plannedProposals + poller.appliedProposals
        guard let patch = all.first(where: { $0.hasPatch })?.patch else { return nil }
        return JeslyPatchStats.ticker(from: patch)
    }

    /// Los pasos de la sesión en vivo, derivados de las tareas
    /// reales: aplicadas arriba, la que está en curso abajo. La hora
    /// es la de la última actualización de la tarea.
    private var sessionSteps: [JeslySessionStep] {
        let done = poller.appliedProposals.map {
            JeslySessionStep(id: $0.id, label: $0.title, state: .done, time: shortTime($0.updatedAt))
        }
        let running = (poller.plannedProposals + poller.proposals).map {
            JeslySessionStep(id: $0.id, label: $0.title, state: .running, time: shortTime($0.updatedAt))
        }
        return Array((done + running).prefix(4))
    }

    /// La primera acción no destructiva es la primaria (hueso).
    private func primaryAction(for task: JeslyTask) -> ProposalAction? {
        task.availableActions.first { !$0.isDestructive }
    }

    private func run(_ action: ProposalAction, shownId: String?) async {
        guard let task = sessionTask, task.id == shownId else { return }
        working = true
        defer { working = false }
        await store.act(action, on: task)
        if store.lastError == nil {
            feedback = feedbackFor(action)
            feedbackIsError = false
        } else {
            feedback = store.lastError
            feedbackIsError = true
        }
        feedbackForId = shownId
    }

    /// Verificar la tarea aplicada en curso (Fase 4, sesión 1).
    /// Un veredicto con fallos es 200, no excepción: la tarjeta
    /// muestra el resumen ("en verde (2/2)" o "1 fallo: health").
    private func runVerify(shownId: String?) async {
        guard let task = sessionTask, task.id == shownId else { return }
        working = true
        defer { working = false }
        await store.verify(task: task)
        if let report = store.lastVerification, store.lastError == nil {
            feedback = "Verificación: \(report.summary)"
            feedbackIsError = !report.passed
        } else {
            feedback = store.lastError
            feedbackIsError = true
        }
        feedbackForId = shownId
    }

    /// Publicar la tarea aplicada en curso (Fase 4, sesión 1).
    /// "Publicada" / "Parcial: falló en deploy" / "Fallida: …".
    private func runPublish(shownId: String?) async {
        guard let task = sessionTask, task.id == shownId else { return }
        working = true
        defer { working = false }
        await store.publish(task: task)
        if let record = store.lastPublish, store.lastError == nil {
            feedback = record.summary
            feedbackIsError = record.status == "fallida"
        } else {
            feedback = store.lastError
            feedbackIsError = true
        }
        feedbackForId = shownId
    }

    private func feedbackFor(_ action: ProposalAction) -> String {
        switch action {
        case .approve: return "Aprobada. Queda lista para aplicarse."
        case .reject: return "Rechazada."
        case .discard: return "Descartada, sin dejar rastro."
        case .apply: return "Aplicada en la rama de prueba."
        case .execute: return "Ejecutando en la rama de prueba."
        case .revert: return "Cambios revertidos."
        }
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    private static let isoFormatterPlain = ISO8601DateFormatter()
    private static let clockFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private func shortTime(_ iso: String?) -> String {
        guard let iso,
              let date = Self.isoFormatter.date(from: iso)
                ?? Self.isoFormatterPlain.date(from: iso)
        else { return "" }
        return Self.clockFormatter.string(from: date)
    }
}

// MARK: - Pasos y diff (porte de la isla actual)

private enum JeslySessionStepState {
    case done, running
}

private struct JeslySessionStep: Identifiable {
    var id: String
    var label: String
    var state: JeslySessionStepState
    var time: String
}

private struct JeslyStepIcon: View {
    var state: JeslySessionStepState

    var body: some View {
        ZStack {
            Circle()
                .fill(state == .done ? Color(hex: "#E8E0D0") : Color.clear)
                .frame(width: 20, height: 20)
                .overlay(Circle().stroke(Color(hex: "#6B7079"), lineWidth: 1))
            if state == .done {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(hex: "#141310"))
            }
            // En curso: anillo hueco ESTÁTICO — el círculo del ZStack,
            // sin nada dentro. Antes había un ProgressView girando en
            // cada paso en curso y, como esos pasos pueden estar así
            // minutos, JC lo leía como "se queda cargando"
            // (verificación en vivo 2026-11-27). La carga real vive
            // en `working` (el ProgressView de JeslySessionView),
            // no aquí: ese sí es carga real y se queda.
        }
    }
}

/// Estadística real de un parche unified diff, para el contador del
/// encabezado (como la maqueta: archivo +48 −12). Cuenta las líneas
/// que empiezan por `+`/`-` sin contar las cabeceras `+++`/`---`,
/// y toma el archivo de la primera cabecera `+++` (o `---` si el
/// archivo se borró). Porte verbatim de `PatchStats` de la isla.
struct JeslyPatchTicker: Equatable {
    var file: String
    var add: Int
    var del: Int
}

enum JeslyPatchStats {
    static func ticker(from patch: String) -> JeslyPatchTicker? {
        var plusFile: String?
        var minusFile: String?
        var add = 0
        var del = 0
        for line in patch.split(separator: "\n", omittingEmptySubsequences: false) {
            if line.hasPrefix("+++ ") {
                plusFile = String(line.dropFirst(4))
            } else if line.hasPrefix("--- ") {
                minusFile = String(line.dropFirst(4))
            } else if line.hasPrefix("+") {
                add += 1
            } else if line.hasPrefix("-") {
                del += 1
            }
        }
        guard add > 0 || del > 0 else { return nil }
        let raw = (plusFile != "/dev/null" ? plusFile : minusFile) ?? "diff"
        let file = raw.split(separator: "/").last.map(String.init) ?? raw
        return JeslyPatchTicker(file: file, add: add, del: del)
    }
}
