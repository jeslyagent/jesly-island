import SwiftUI

/// Workflows desde la isla: ejecutar, pausar y borrar.
///
/// Porte de `WorkflowsSkillsViews.swift` de la isla actual (HEAD
/// `3e2a59db`), adaptado al cromo de Ajustes del fork (tamaños de
/// sistema, como la sección JESLY). Endpoints reales
/// (`routes/workflows.ts`):
/// - `POST /v1/workflows/:id/run` (ejecutar ahora; el run crea una
///   tarea y su progreso se ve en la tarjeta de sesión en vivo)
/// - `PATCH /v1/workflows/:id { enabled: false }` (pausar)
/// - `DELETE /v1/workflows/:id` (borrar)
struct JeslyWorkflowsView: View {
    @ObservedObject var store: JeslyWorkflowsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Workflows")
                .font(.system(size: 12, weight: .semibold))
            if store.workflows.isEmpty {
                Text("No hay workflows. Se crean en la web o por la API.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            ForEach(store.workflows) { workflow in
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(workflow.name)
                            .font(.system(size: 12, weight: .semibold))
                        if let schedule = workflow.schedule {
                            Text(schedule)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    Button("Ejecutar") {
                        Task { await store.runWorkflow(workflow) }
                    }
                    .buttonStyle(.bordered)
                    Button(workflow.isEnabled ? "Pausar" : "Reanudar") {
                        Task { await store.setWorkflowEnabled(workflow, enabled: !workflow.isEnabled) }
                    }
                    .buttonStyle(.bordered)
                    Button("Borrar") {
                        Task { await store.deleteWorkflow(workflow) }
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
                .font(.system(size: 12))
                .padding(8)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

/// Habilidades desde la isla: probar, aprobar, rechazar, desinstalar.
///
/// Porte de `WorkflowsSkillsViews.swift` de la isla actual.
/// Endpoints reales (`routes/skills.ts`):
/// - `POST /v1/skills/:id/test` (en_revision o instalada)
/// - `POST /v1/skills/:id/approve` (en_revision → instalada)
/// - `POST /v1/skills/:id/reject` (en_revision → rechazada)
/// - `POST /v1/skills/:id/uninstall` (instalada → desinstalada)
/// Instalar desde un manifiesto es follow-up (ver README de la
/// isla): la ruta `POST /v1/skills/install` existe, pero la isla
/// aún no sube manifiestos.
struct JeslySkillsView: View {
    @ObservedObject var store: JeslyWorkflowsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Habilidades")
                .font(.system(size: 12, weight: .semibold))
            if store.skills.isEmpty {
                Text("No hay habilidades instaladas.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            ForEach(store.skills) { skill in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(skill.name)
                            .font(.system(size: 12, weight: .semibold))
                        Text(skill.status)
                            .font(.system(size: 10))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(Capsule())
                        Spacer()
                        if let version = skill.version {
                            Text(version)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    if let description = skill.description, !description.isEmpty {
                        Text(description)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    HStack(spacing: 8) {
                        if skill.status == "en_revision" || skill.status == "instalada" {
                            Button("Probar") {
                                Task { await store.skillAction(.test, skill: skill) }
                            }
                            .buttonStyle(.bordered)
                        }
                        if skill.status == "en_revision" {
                            Button("Aprobar") {
                                Task { await store.skillAction(.approve, skill: skill) }
                            }
                            .buttonStyle(.borderedProminent)
                            Button("Rechazar") {
                                Task { await store.skillAction(.reject, skill: skill) }
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }
                        if skill.status == "instalada" {
                            Button("Desinstalar") {
                                Task { await store.skillAction(.uninstall, skill: skill) }
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }
                    }
                    .font(.system(size: 12))
                }
                .padding(8)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

/// Recordatorios desde la isla: crear en lenguaje natural, listar
/// y marcar hecho.
///
/// La isla actual no tiene vista propia de recordatorios (llegan
/// por chat); esta vista sigue el mismo estilo de
/// `WorkflowsSkillsViews.swift` y usa solo endpoints reales
/// (`routes/reminders.ts`):
/// - `POST /v1/reminders { text }` (crear; el parser de fechas vive
///   en la API, nunca se adivina una hora en Swift)
/// - `GET /v1/reminders` (listar: pendiente/disparado/silenciado)
/// - `POST /v1/reminders/:id/silence` (marcar hecho: no hay
///   endpoint "hecho", silenciar desactiva el workflow para que no
///   suene más)
/// - `DELETE /v1/reminders/:id` (borrar)
struct JeslyRemindersView: View {
    @ObservedObject var store: JeslyWorkflowsStore
    @State private var newReminderText: String = ""

    private static let atFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recordatorios")
                .font(.system(size: 12, weight: .semibold))
            Text("En lenguaje natural, por ejemplo «Recuérdame mañana a las 9 que pague el Popular». Si la fecha no se entiende, la API pregunta y no se crea nada.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            HStack(spacing: 8) {
                TextField("Recuérdame…", text: $newReminderText)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))
                Button("Crear") {
                    let text = newReminderText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else { return }
                    newReminderText = ""
                    Task { await store.createReminder(text: text) }
                }
                .buttonStyle(.borderedProminent)
                .disabled(newReminderText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            if let confirmation = store.lastReminderConfirmation {
                Text(confirmation)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            if store.reminders.isEmpty {
                Text("No hay recordatorios.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            ForEach(store.reminders) { reminder in
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(reminder.text)
                            .font(.system(size: 12, weight: .semibold))
                        Text(Self.atFormatter.string(from: reminder.atDate ?? Date()))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(reminder.estado)
                        .font(.system(size: 10))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(Capsule())
                    if reminder.estado == "pendiente" {
                        Button("Hecho") {
                            Task { await store.silenceReminder(reminder) }
                        }
                        .buttonStyle(.bordered)
                    }
                    Button("Borrar") {
                        Task { await store.deleteReminder(reminder) }
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
                .font(.system(size: 12))
                .padding(8)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}
