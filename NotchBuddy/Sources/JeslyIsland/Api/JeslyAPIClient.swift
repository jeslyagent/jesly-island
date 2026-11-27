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
}
