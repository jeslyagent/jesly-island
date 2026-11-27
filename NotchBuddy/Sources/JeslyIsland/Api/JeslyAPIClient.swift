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
}
