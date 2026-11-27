import SwiftUI

/// Tarjeta Propuesta/Permiso de JESLY en la isla (Fase 3, sesión 2).
///
/// Reutiliza la UI de la tarjeta de permisos de Coucou
/// (`ApprovalView` en `IslandViewContent.swift`): el mismo fondo
/// ámbar, la misma cabecera con la pill que pregunta, el contador
/// "1/N" y los mismos botones píldora. Lo que cambia es el backend:
/// Coucou mantiene un fd de `nb-hook` abierto hasta el clic y
/// responde por el socket; JESLY no tiene hook — cada botón llama a
/// `JeslyAPIClient.proposalAction(_:taskId:)` con el `task id`
/// exacto de la propuesta que está en pantalla (capturado al
/// dibujar la tarjeta, como hace `ApprovalView` con `shownId`).
///
/// Botones por estado (`JeslyTask.availableActions`, igual que la
/// isla actual):
///   esperando_aprobacion → Permitir / Denegar / Siempre;
///   planificada con parche → Aplicar / Descartar;
///   planificada sin parche → Ejecutar / Descartar;
///   aplicada → Revertir.
/// "Siempre" solo aparece en espera: crea la regla y aprueba ESTA
/// propuesta. Sin regla no hay nada automático.
///
/// Con la API apagada la tarjeta no aparece (el poller no trae
/// nada nuevo y la pill muestra 0 propuestas, sesión 1).
struct JeslyProposalView: View {
    @ObservedObject private var store = JeslyProposalStore.shared

    @State private var working: Bool = false
    @State private var feedback: String?
    @State private var feedbackIsError: Bool = false
    /// La propuesta a la que pertenece el feedback: si la tarjeta
    /// ya pasó a la siguiente, el texto viejo no se muestra.
    @State private var feedbackForId: String?

    /// La pill que pregunta, como la ve `AgentWho`.
    private var asker: AgentTask {
        AgentTask(id: JeslyProposalsPoller.pillId, name: "JESLY", color: "#E8E0D0",
                  state: .approval, steps: [], source: .agent)
    }

    var body: some View {
        // Capturado al dibujar: un clic responde a la propuesta que
        // estaba en pantalla, y se ignora si la tarjeta ya pasó a
        // la siguiente (igual que `shownId` en `ApprovalView`).
        let task = store.current
        let shownId = task?.id
        ZStack {
            CardBackground(wash: .amber)
            if let task {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 7) {
                        AgentWho(task: asker, label: task.status == "esperando_aprobacion" ? "needs permission" : "Propuesta nueva")
                        // Otras propuestas esperando detrás de esta: "1/3".
                        if store.totalCount > 1 {
                            Text(verbatim: "1/\(store.totalCount)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(hex: "#8E939C"))
                                .monospacedDigit()
                        }
                    }
                    Text(bodyText(for: task))
                        .font(.system(size: 13.5))
                        .foregroundColor(Color(hex: "#F5F6F8"))
                        .lineLimit(6)
                    if let sub = subText(for: task) {
                        Text(sub)
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#8E939C"))
                            .lineLimit(1)
                    }
                    HStack(spacing: 8) {
                        if task.status == "esperando_aprobacion" {
                            PrimaryButton(verbatim: "Permitir") {
                                Task { await answer(.allow, shownId: shownId, feedback: "Permitido. JESLY sigue.") }
                            }
                            SecondaryButton(verbatim: "Denegar") {
                                Task { await answer(.deny, shownId: shownId, feedback: "Denegado. JESLY se detiene.") }
                            }
                            SecondaryButton(verbatim: "Siempre") {
                                Task { await answer(.always, shownId: shownId, feedback: "Siempre: este agente y tipo ya no pedirán permiso.") }
                            }
                        } else {
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
                    }
                    .padding(.top, 4)
                    .disabled(working)
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
    }

    private func bodyText(for task: JeslyTask) -> String {
        if let proposal = task.proposal, !proposal.isEmpty { return proposal }
        if let plan = task.plan, !plan.isEmpty { return plan }
        return task.title
    }

    private func subText(for task: JeslyTask) -> String? {
        var parts: [String] = []
        if let branch = task.branch, !branch.isEmpty { parts.append("Rama: \(branch)") }
        if task.hasPatch { parts.append("Diff listo") }
        if parts.isEmpty { return nil }
        return parts.joined(separator: " · ")
    }

    /// La primera acción no destructiva es la primaria (hueso).
    private func primaryAction(for task: JeslyTask) -> ProposalAction? {
        task.availableActions.first { !$0.isDestructive }
    }

    private func run(_ action: ProposalAction, shownId: String?) async {
        guard let task = store.current, task.id == shownId else { return }
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

    private func answer(_ answer: JeslyProposalStore.PermissionAnswer, shownId: String?, feedback: String) async {
        guard let task = store.current, task.id == shownId else { return }
        working = true
        defer { working = false }
        await store.answerPermission(answer, for: task)
        if store.lastError == nil {
            self.feedback = feedback
            feedbackIsError = false
        } else {
            self.feedback = store.lastError
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
}
