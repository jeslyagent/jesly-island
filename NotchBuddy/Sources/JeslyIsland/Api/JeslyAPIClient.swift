import Foundation

/// Cliente de la API local de JESLY.
///
/// Base por defecto `http://127.0.0.1:3000` (la API que ya existe,
/// `apps/api`). Cada llamada se cableó contra la ruta real en
/// `apps/api/src/routes/` — si una ruta no existe, NO se inventa.
///
/// Autenticación: `Authorization: Bearer <JESLY_API_KEY>` cuando hay
/// clave (llavero o entorno); sin clave se llama sin cabecera, como
/// acepta la API en local. La clave nunca se registra en logs.
///
/// Origen: `jeslyagent/Jesly-agent-ai`, `apps/island/Sources/JeslyIsland/Api/JeslyAPIClient.swift`,
/// HEAD `3e2a59db`. Porte de la Fase 3, sesión 1: solo transporte +
/// propuestas. Chat, workflows, habilidades y voz llegan en las
/// Fases 4–5 con sus secciones del archivo original.
///
/// Fase 4, sesión 1: se portan el chat (`POST /v1/chat`) y la
/// verificación/publicación. OJO: `verify` y `publish` NO los usa el
/// cliente de la isla actual — existen en el SERVIDOR
/// (`apps/api/src/routes/tasks.ts`, HEAD `3e2a59db`: `verify` en la
/// línea 779, `publish` en la 868; plan v2 §8/§9) con esos nombres
/// exactos. Solo tareas en `aplicada` y de kind `propuesta` (409 si
/// no). `verify` exige `checks` no vacío en el cuerpo (400 si
/// falta): se mandan las comprobaciones locales por defecto del
/// propio servidor (`publish.ts: defaultChecks`, caso sin cloud:
/// health a la API local y a la web local). `publish` sin cuerpo usa
/// los defaults del servidor, que detectan si el cambio toca
/// `cloud/` y verifican contra lo desplegado.
public struct JeslyAPIClient: Sendable {
    public var baseURL: URL
    public var apiKey: String?
    public var session: URLSession

    public init(
        baseURL: URL = URL(string: "http://127.0.0.1:3000")!,
        apiKey: String? = ApiKeyStore.read(),
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.session = session
    }

    // MARK: - Errores

    public enum ClientError: LocalizedError, Equatable {
        case serverUnreachable
        case httpStatus(Int, String)
        case badResponse(String)

        public var errorDescription: String? {
            switch self {
            case .serverUnreachable:
                return "La API de JESLY no responde en 127.0.0.1:3000. ¿Está arrancada? (scripts/arrancar-todo.sh)"
            case .httpStatus(let code, let message):
                return "La API devolvió \(code): \(message)"
            case .badResponse(let message):
                return "Respuesta inesperada de la API: \(message)"
            }
        }
    }

    // MARK: - Transporte

    /// URL para una ruta como "/v1/tasks?status=...". Se construye
    /// con URLComponents: `appendingPathComponent` codificaría el `?`
    /// de la query y rompería la llamada.
    private func url(for path: String) -> URL {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
            ?? URLComponents(string: "http://127.0.0.1:3000")!
        let parts = path.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)
        components.path = String(parts[0])
        if parts.count > 1 {
            components.query = String(parts[1])
        }
        return components.url ?? baseURL
    }

    private func request(path: String, method: String = "GET", jsonBody: [String: Any]? = nil) -> URLRequest {
        var request = URLRequest(url: url(for: path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey, !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        if let jsonBody {
            request.httpBody = try? JSONSerialization.data(withJSONObject: jsonBody)
        }
        return request
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(type, from: data)
    }

    private func errorMessage(from data: Data) -> String {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = json["error"] as? String, !error.isEmpty {
            return error
        }
        return "sin detalle"
    }

    private func send<T: Decodable>(_ request: URLRequest, as type: T.Type) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw ClientError.serverUnreachable
        }
        guard let http = response as? HTTPURLResponse else {
            throw ClientError.badResponse("respuesta sin HTTP")
        }
        guard (200..<300).contains(http.statusCode) else {
            throw ClientError.httpStatus(http.statusCode, errorMessage(from: data))
        }
        do {
            return try decode(type, from: data)
        } catch {
            throw ClientError.badResponse(error.localizedDescription)
        }
    }

    /// Como `send`, pero para rutas que no devuelven cuerpo útil
    /// (run, patch, delete, acciones de habilidad): solo valida 2xx.
    /// Porte verbatim del cliente de la isla actual.
    private func sendVoid(_ request: URLRequest) async throws {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw ClientError.serverUnreachable
        }
        guard let http = response as? HTTPURLResponse else {
            throw ClientError.badResponse("respuesta sin HTTP")
        }
        guard (200..<300).contains(http.statusCode) else {
            throw ClientError.httpStatus(http.statusCode, errorMessage(from: data))
        }
    }

    // MARK: - Propuestas (`routes/tasks.ts`)

    private struct TasksResponse: Decodable {
        var tasks: [JeslyTask]
    }

    private struct TaskResponse: Decodable {
        var task: JeslyTask
    }

    /// Propuestas esperando aprobación de JC.
    /// `GET /v1/tasks?status=esperando_aprobacion&kind=propuesta`.
    public func pendingProposals(limit: Int = 50) async throws -> [JeslyTask] {
        let response: TasksResponse = try await send(
            request(path: "/v1/tasks?status=esperando_aprobacion&kind=propuesta&limit=\(limit)"),
            as: TasksResponse.self
        )
        return response.tasks
    }

    /// Propuestas ya aprobadas (planificadas): ahí viven Aplicar,
    /// Ejecutar y Descartar. `GET /v1/tasks?status=planificada&kind=propuesta`.
    public func plannedProposals(limit: Int = 20) async throws -> [JeslyTask] {
        let response: TasksResponse = try await send(
            request(path: "/v1/tasks?status=planificada&kind=propuesta&limit=\(limit)"),
            as: TasksResponse.self
        )
        return response.tasks
    }

    /// Propuestas aplicadas (para Revertir). `GET /v1/tasks?status=aplicada&kind=propuesta`.
    public func appliedProposals(limit: Int = 20) async throws -> [JeslyTask] {
        let response: TasksResponse = try await send(
            request(path: "/v1/tasks?status=aplicada&kind=propuesta&limit=\(limit)"),
            as: TasksResponse.self
        )
        return response.tasks
    }

    /// Acción sobre una propuesta: approve / reject / discard /
    /// apply / revert / execute. Cada una va por su endpoint real
    /// `POST /v1/tasks/:id/<acción>` y solo vale para la propuesta
    /// que está esperando (puerta de la fase 2). La decisión vale
    /// para el `task id` exacto: JESLY no tiene hook, así que no hay
    /// fd de `nb-hook` que mantener abierto hasta el clic, como hace
    /// Coucou con los permisos de Claude Code.
    public func proposalAction(_ action: ProposalAction, taskId: String) async throws -> JeslyTask {
        let response: TaskResponse = try await send(
            request(path: "/v1/tasks/\(taskId)/\(action.endpoint)", method: "POST", jsonBody: [:]),
            as: TaskResponse.self
        )
        return response.task
    }

    // MARK: - Chat (`routes/chat.ts`, Fase 4, sesión 1)

    /// `POST /v1/chat { message, provider?, attachments? }`.
    /// El modelo NO se puede fijar: lo elige el router y vuelve en
    /// la respuesta. `attachments` son los ojos (§6).
    /// Porte verbatim del cliente de la isla actual.
    public func chat(
        message: String,
        provider: String? = nil,
        attachments: [ChatAttachment] = []
    ) async throws -> ChatResponse {
        var body: [String: Any] = ["message": message]
        if let provider { body["provider"] = provider }
        if !attachments.isEmpty {
            body["attachments"] = attachments.map { attachment in
                ["kind": attachment.kind, "mediaType": attachment.mediaType, "data": attachment.data]
            }
        }
        return try await send(
            request(path: "/v1/chat", method: "POST", jsonBody: body),
            as: ChatResponse.self
        )
    }

    // MARK: - Verificación y publicación (Fase 4, sesión 1)

    private struct VerifyResponse: Decodable {
        var task: JeslyTask
        var verification: JeslyVerificationReport
    }

    private struct PublishResponse: Decodable {
        var task: JeslyTask
        var publish: JeslyPublishRecord
    }

    /// Comprobaciones locales por defecto para `verify`: las mismas
    /// que usa el servidor cuando el cambio no toca `cloud/`
    /// (`publish.ts: defaultChecks`): health a la API local
    /// (127.0.0.1:3000/health) y a la web local (127.0.0.1:3003).
    /// La ruta exige `checks` no vacío (400 si falta), así que no se
    /// puede llamar sin cuerpo. Si la tarea toca `cloud/`, el botón
    /// correcto es Publicar: el servidor calcula solo las
    /// comprobaciones contra lo desplegado.
    private static var defaultLocalChecks: [[String: Any]] {
        [
            ["type": "health", "url": "http://127.0.0.1:3000/health"],
            ["type": "health", "url": "http://127.0.0.1:3003"],
        ]
    }

    /// Verificar una tarea aplicada contra el sistema VIVO (health,
    /// contenido, build, log) con las comprobaciones por defecto.
    /// `POST /v1/tasks/:id/verify`. Solo `aplicada` (409 si no).
    /// Un veredicto con fallos responde 200 con el informe, NO es
    /// excepción: `report.passed` dice si pasó.
    public func verify(taskId: String) async throws -> (task: JeslyTask, verification: JeslyVerificationReport) {
        let response: VerifyResponse = try await send(
            request(path: "/v1/tasks/\(taskId)/verify", method: "POST", jsonBody: ["checks": Self.defaultLocalChecks]),
            as: VerifyResponse.self
        )
        return (response.task, response.verification)
    }

    /// Publicar una tarea aplicada: push de la rama de prueba a
    /// GitHub, deploy del Worker si toca `cloud/` y verificación
    /// contra lo desplegado (o en local si no toca `cloud/`).
    /// `POST /v1/tasks/:id/publish`. Solo `aplicada` (409 si no).
    /// Nunca fusiona a main: eso lo decide JC. El resultado queda
    /// en `record.status`: publicada / parcial / fallida.
    public func publish(taskId: String) async throws -> (task: JeslyTask, publish: JeslyPublishRecord) {
        let response: PublishResponse = try await send(
            request(path: "/v1/tasks/\(taskId)/publish", method: "POST", jsonBody: [:]),
            as: PublishResponse.self
        )
        return (response.task, response.publish)
    }

    // MARK: - Workflows (`routes/workflows.ts`, Fase 5, sesión 1)

    private struct WorkflowsResponse: Decodable {
        var workflows: [JeslyWorkflow]
    }

    /// `GET /v1/workflows` → `{ workflows }`.
    /// Porte verbatim del cliente de la isla actual.
    public func workflows() async throws -> [JeslyWorkflow] {
        let response: WorkflowsResponse = try await send(
            request(path: "/v1/workflows"),
            as: WorkflowsResponse.self
        )
        return response.workflows
    }

    /// Disparar ahora. `POST /v1/workflows/:id/run` → 202.
    /// El progreso se ve como una tarea en curso (el run crea una
    /// tarea que el poller de propuestas ya trae).
    public func runWorkflow(id: String) async throws {
        try await sendVoid(request(path: "/v1/workflows/\(id)/run", method: "POST", jsonBody: [:]))
    }

    /// Pausar / reanudar. `PATCH /v1/workflows/:id { enabled }`.
    public func setWorkflowEnabled(id: String, enabled: Bool) async throws {
        try await sendVoid(request(path: "/v1/workflows/\(id)", method: "PATCH", jsonBody: ["enabled": enabled]))
    }

    /// Borrar. `DELETE /v1/workflows/:id`.
    public func deleteWorkflow(id: String) async throws {
        try await sendVoid(request(path: "/v1/workflows/\(id)", method: "DELETE"))
    }

    // MARK: - Habilidades (`routes/skills.ts`, Fase 5, sesión 1)

    private struct SkillsResponse: Decodable {
        var skills: [JeslySkill]
    }

    /// `GET /v1/skills` → `{ skills }`.
    /// Porte verbatim del cliente de la isla actual.
    public func skills() async throws -> [JeslySkill] {
        let response: SkillsResponse = try await send(
            request(path: "/v1/skills"),
            as: SkillsResponse.self
        )
        return response.skills
    }

    /// Probar en aislado. `POST /v1/skills/:id/test`.
    /// Solo en_revision o instalada (la vista ya lo filtra).
    public func testSkill(id: String) async throws {
        try await sendVoid(request(path: "/v1/skills/\(id)/test", method: "POST", jsonBody: [:]))
    }

    /// Aprobar. `POST /v1/skills/:id/approve` (en_revision → instalada).
    public func approveSkill(id: String) async throws {
        try await sendVoid(request(path: "/v1/skills/\(id)/approve", method: "POST", jsonBody: [:]))
    }

    /// Rechazar. `POST /v1/skills/:id/reject` (en_revision → rechazada).
    public func rejectSkill(id: String) async throws {
        try await sendVoid(request(path: "/v1/skills/\(id)/reject", method: "POST", jsonBody: [:]))
    }

    /// Desinstalar. `POST /v1/skills/:id/uninstall` (instalada → desinstalada).
    public func uninstallSkill(id: String) async throws {
        try await sendVoid(request(path: "/v1/skills/\(id)/uninstall", method: "POST", jsonBody: [:]))
    }

    // MARK: - Recordatorios (`routes/reminders.ts`, Fase 5, sesión 1)

    private struct RemindersResponse: Decodable {
        var reminders: [JeslyReminder]
    }

    private struct CreateReminderResponse: Decodable {
        var reminder: JeslyReminder
        var confirmation: String?
        var pushConfigured: Bool?
    }

    private struct ReminderResponse: Decodable {
        var reminder: JeslyReminder
    }

    /// `GET /v1/reminders` → `{ reminders }` (pendiente/disparado/
    /// silenciado). Un recordatorio ES un workflow programado de un
    /// solo disparo con el marcador `[recordatorio]`.
    public func reminders() async throws -> [JeslyReminder] {
        let response: RemindersResponse = try await send(
            request(path: "/v1/reminders"),
            as: RemindersResponse.self
        )
        return response.reminders
    }

    /// Crear desde lenguaje natural. `POST /v1/reminders { text }`
    /// → 201 `{ reminder, confirmation, push_configured }`. Si la
    /// fecha/hora no se entiende, el servidor responde 400 con la
    /// pregunta: nunca se adivina una hora en Swift, el parser vive
    /// en la API. La confirmación lleva fecha y hora completas.
    public func createReminder(text: String) async throws -> (reminder: JeslyReminder, confirmation: String?) {
        let response: CreateReminderResponse = try await send(
            request(path: "/v1/reminders", method: "POST", jsonBody: ["text": text]),
            as: CreateReminderResponse.self
        )
        return (response.reminder, response.confirmation)
    }

    /// Marcar hecho: silenciar. `POST /v1/reminders/:id/silence` →
    /// `{ reminder }`. No hay endpoint "hecho" en el servidor: un
    /// recordatorio es un workflow y silenciarlo lo desactiva para
    /// que no suene más. Por eso el botón dice "Hecho" y llama a
    /// silence, nunca se inventa otra ruta.
    public func silenceReminder(id: String) async throws -> JeslyReminder {
        let response: ReminderResponse = try await send(
            request(path: "/v1/reminders/\(id)/silence", method: "POST", jsonBody: [:]),
            as: ReminderResponse.self
        )
        return response.reminder
    }

    /// Borrar. `DELETE /v1/reminders/:id` → `{ deleted: true }`.
    public func deleteReminder(id: String) async throws {
        try await sendVoid(request(path: "/v1/reminders/\(id)", method: "DELETE"))
    }

    // MARK: - Investigación profunda (`routes/investigar.ts`, Fase 5, sesión 2)

    /// Investigar en la web sin pasar por el chat.
    /// `POST /v1/investigar { pregunta, provider? }` → 200
    /// `{ respuesta, fuentes, fechaConsulta, consultas,
    /// paginasFallidas, fuente, provider?, model? }`.
    /// 400 sin pregunta o con más de 1000 caracteres; 503 sin
    /// acceso a la web (nunca una respuesta inventada). Sin router
    /// o si el modelo falla, la respuesta es la extractiva con las
    /// mismas fuentes (`fuente: "extractiva"`).
    public func investigate(pregunta: String, provider: String? = nil) async throws -> JeslyResearchResult {
        var body: [String: Any] = ["pregunta": pregunta]
        if let provider { body["provider"] = provider }
        return try await send(
            request(path: "/v1/investigar", method: "POST", jsonBody: body),
            as: JeslyResearchResult.self
        )
    }

    // MARK: - Cuentas conectadas (`routes/cuentas.ts`, Fase 5, sesión 2)

    private struct AccountsResponse: Decodable {
        var cuentas: [JeslyConnectedAccount]
    }

    /// `GET /v1/cuentas` → `{ cuentas }` (sin tokens).
    /// Proveedores reales: google y github. Sin cuentas conectadas
    /// devuelve la lista vacía; sin base de datos, 503.
    /// Solo lectura en esta sesión.
    public func connectedAccounts() async throws -> [JeslyConnectedAccount] {
        let response: AccountsResponse = try await send(
            request(path: "/v1/cuentas"),
            as: AccountsResponse.self
        )
        return response.cuentas
    }

    // MARK: - Resumen diario (`routes/digest.ts`, Fase 5, sesión 2)

    /// Vista previa del resumen de hoy, compuesto ahora mismo desde
    /// las fuentes reales. `GET /v1/resumen-diario` →
    /// `{ digest, propuestas, pendientes, workflows_hoy, recuerdos,
    /// errores }`. Sin base de datos, 503.
    public func dailyDigest() async throws -> JeslyDailyDigest {
        try await send(request(path: "/v1/resumen-diario"), as: JeslyDailyDigest.self)
    }

    /// Programar el resumen: crea o actualiza el workflow
    /// "Resumen diario — buenos días" (cron `M H * * *`, marcador
    /// `[resumen-diario]`). `POST /v1/resumen-diario { hora }` →
    /// 201/200 `{ workflow, hora, push_configured }`. 400 sin hora
    /// o con formato distinto de HH:MM; la hora la valida la API,
    /// nunca se adivina en Swift.
    public func scheduleDailyDigest(hour: String) async throws -> JeslyDigestScheduleResponse {
        try await send(
            request(path: "/v1/resumen-diario", method: "POST", jsonBody: ["hora": hour]),
            as: JeslyDigestScheduleResponse.self
        )
    }

    /// Apagar el resumen programado. `DELETE /v1/resumen-diario` →
    /// `{ deleted: true }`. 404 si no hay ninguno programado.
    public func deleteDailyDigest() async throws {
        try await sendVoid(request(path: "/v1/resumen-diario", method: "DELETE"))
    }

    // MARK: - Voz y escucha (`routes/voice.ts`, `voice/wake.ts`, Fase 4, sesión 3)

    /// Estado del demonio "Oye JESLY".
    /// `GET /v1/voice/wake/status` (`routes/voice.ts:57` → `voice/wake.ts`:
    /// el demonio vive aparte en `services/wake-word/daemon.py` y
    /// expone su estado en `127.0.0.1:3004/status`, con timeout de
    /// 2 s). Demonio caído = listening false con 200, nunca 500.
    /// Porte verbatim del cliente de la isla actual.
    public func wakeStatus() async throws -> WakeStatus {
        try await send(request(path: "/v1/voice/wake/status"), as: WakeStatus.self)
    }

    /// `POST /v1/voice/transcribe` — multipart `file` + `language=es`.
    /// Devuelve `{ text, language, ... }` (el resto de campos se ignoran).
    /// Porte verbatim del cliente de la isla actual.
    public func transcribe(audioData: Data, filename: String, language: String = "es") async throws -> String {
        struct TranscribeResponse: Decodable {
            var text: String
        }
        let boundary = "jesly-island-\(UUID().uuidString)"
        var request = request(path: "/v1/voice/transcribe", method: "POST")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(language)\r\n".data(using: .utf8)!)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        let response: TranscribeResponse = try await send(request, as: TranscribeResponse.self)
        return response.text
    }

    /// `POST /v1/voice/synthesize { text }` → audio WAV.
    /// Máx. 2000 caracteres (el llamador recorta a 1800).
    /// Porte verbatim del cliente de la isla actual.
    public func synthesize(text: String) async throws -> Data {
        let request = request(path: "/v1/voice/synthesize", method: "POST", jsonBody: ["text": text])
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw ClientError.serverUnreachable
        }
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw ClientError.httpStatus(code, errorMessage(from: data))
        }
        return data
    }
}
