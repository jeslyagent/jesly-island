import Foundation

/// Modelos Codable de la API local de JESLY (http://127.0.0.1:3000).
///
/// Cada campo se verificó contra `apps/api/src/routes/` el 2026-11-21.
/// Los campos que la API no devuelve son opcionales: si el servidor
/// añade o quita uno, la isla sigue decodificando en vez de romperse.
///
/// Origen: `jeslyagent/Jesly-agent-ai`, `apps/island/Sources/JeslyIsland/Api/JeslyModels.swift`,
/// HEAD `3e2a59db`. Porte de la Fase 3, sesión 1.
///
/// UNA diferencia con el origen, deliberada: el `ChatProvider` struct
/// de la isla NO se porta con ese nombre. Coucou ya tiene un
/// `enum ChatProvider` (`CoucouKit/IslandTypes.swift:115`) y dos tipos
/// con el mismo nombre en el mismo módulo no compilan. En la Fase 4,
/// sesión 1, se porta como `JeslyChatProvider` (abajo en este
/// archivo). Ningún método del cliente de la sesión 1 lo usaba; el
/// `chat()` del cliente llega en la Fase 4, sesión 1.

/// Una tarea/propuesta del ledger (`GET /v1/tasks`, `routes/tasks.ts`).
/// Columnas: id, title, status, plan, result, agent_id, kind,
/// proposal, patch, branch, commit_sha, created_at, updated_at.
public struct JeslyTask: Codable, Identifiable, Equatable {
    public var id: String
    public var title: String
    public var status: String
    public var plan: String?
    public var result: String?
    public var agentId: String?
    public var kind: String
    public var proposal: String?
    /// Parche unified diff (nil = la propuesta no tiene nada que aplicar).
    public var patch: String?
    public var branch: String?
    public var commitSha: String?
    public var createdAt: String?
    public var updatedAt: String?

    /// Decodificación tolerante del `plan` (corrección Fase 6,
    /// verificación en vivo 2026-11-27): el servidor lo devuelve
    /// como LISTA JSON (`routes/tasks.ts:210`:
    /// `Array.isArray(req.body?.plan) ? req.body.plan : []`,
    /// guardado con `JSON.stringify`), mientras este modelo lo
    /// declaraba `String?`. JSONDecoder no decodifica un array
    /// como `String?`: fallaba TODA la respuesta `TasksResponse`,
    /// el poller marcaba `apiReachable=false`, las listas quedaban
    /// vacías, la pill marcaba 0 y la tarjeta de permiso nunca
    /// aparecía aunque la API tuviera propuestas. `plan` sigue
    /// siendo `String?` por fuera: texto directo → tal cual;
    /// lista de textos → unidos por líneas; cualquier otra forma
    /// (lista de objetos, null, ausente) → nil, sin fallar.
    /// El resto de campos se decodifica igual que antes.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        status = try container.decode(String.self, forKey: .status)
        plan = Self.decodePlan(from: container)
        result = try container.decodeIfPresent(String.self, forKey: .result)
        agentId = try container.decodeIfPresent(String.self, forKey: .agentId)
        kind = try container.decode(String.self, forKey: .kind)
        proposal = try container.decodeIfPresent(String.self, forKey: .proposal)
        patch = try container.decodeIfPresent(String.self, forKey: .patch)
        branch = try container.decodeIfPresent(String.self, forKey: .branch)
        commitSha = try container.decodeIfPresent(String.self, forKey: .commitSha)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
    }

    private static func decodePlan(from container: KeyedDecodingContainer<CodingKeys>) -> String? {
        if let text = try? container.decode(String.self, forKey: .plan) {
            return text
        }
        if let steps = try? container.decode([String].self, forKey: .plan) {
            let joined = steps.filter { !$0.isEmpty }.joined(separator: "\n")
            return joined.isEmpty ? nil : joined
        }
        return nil
    }

    /// true solo si hay un parche que aplicar en rama de prueba.
    public var hasPatch: Bool { (patch ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }

    /// Acciones que la isla puede ofrecer para esta propuesta, según su
    /// estado real en el servidor (máx. 4, como las preguntas de Coucou).
    /// La máquina de transiciones vive en `routes/tasks.ts`.
    public var availableActions: [ProposalAction] {
        switch status {
        case "esperando_aprobacion":
            return [.approve, .reject, .discard]
        case "planificada":
            if hasPatch { return [.apply, .discard] }
            return [.execute, .discard]
        case "aplicada":
            return [.revert]
        default:
            return []
        }
    }
}

/// Acción sobre una propuesta y su endpoint real.
public enum ProposalAction: String, CaseIterable, Equatable, Sendable {
    case approve  // esperando_aprobacion -> planificada
    case reject   // esperando_aprobacion -> cancelada
    case discard  // esperando_aprobacion/planificada -> cancelada
    case apply    // planificada con parche -> aplicada (rama jesly-test/*)
    case revert   // aplicada -> revertida (borra rama + worktree)
    case execute  // planificada sin parche -> el agente `mac` escribe en rama de prueba

    public var endpoint: String { rawValue }

    public var title: String {
        switch self {
        case .approve: return "Aprobar"
        case .reject: return "Rechazar"
        case .discard: return "Descartar"
        case .apply: return "Aplicar en rama de prueba"
        case .revert: return "Revertir"
        case .execute: return "Ejecutar"
        }
    }

    /// Texto corto para el botón de la isla.
    public var shortTitle: String {
        switch self {
        case .approve: return "Aprobar"
        case .reject: return "Rechazar"
        case .discard: return "Descartar"
        case .apply: return "Aplicar"
        case .revert: return "Revertir"
        case .execute: return "Ejecutar"
        }
    }

    public var isDestructive: Bool {
        switch self {
        case .reject, .discard, .revert: return true
        default: return false
        }
    }
}

/// Respuesta de `POST /v1/chat` (`routes/chat.ts`).
/// La usa `JeslyAPIClient.chat` desde la Fase 4, sesión 1 (la vista
/// de chat con el selector de proveedor llega en la sesión 2).
public struct ChatResponse: Codable, Equatable {    public var text: String
    public var provider: String
    public var model: String
    public var latencyMs: Int?
    public var cached: Bool?
    public var vision: VisionInfo?

    public struct VisionInfo: Codable, Equatable {
        public var provider: String
        public var model: String
        public var images: Int?
        public var frames: Int?
        public var transcribed: Bool?
        public var framesAvailable: Bool?
        public var note: String?
    }
}

/// Adjunto para los ojos (§6): imagen o video en base64.
/// Límites del servidor (`vision/attachments.ts`): imágenes
/// png/jpg/webp/gif máx. 10 MB; videos mp4/mov/webm máx. 50 MB;
/// máx. 4 adjuntos y 1 video por mensaje.
/// (Sin uso en esta sesión; los ojos llegan en la Fase 4.)
public struct ChatAttachment: Codable, Equatable, Sendable {
    public var kind: String  // "image" | "video"
    public var mediaType: String
    public var data: String  // base64, nunca se guarda en disco

    public init(kind: String, mediaType: String, data: String) {
        self.kind = kind
        self.mediaType = mediaType
        self.data = data
    }
}

/// Workflow (`GET /v1/workflows`, `routes/workflows.ts`).
/// (Fase 5, sesión 1: los workflows llegan aquí.)
public struct JeslyWorkflow: Codable, Identifiable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var task: String?
    public var schedule: String?
    public var agentId: String?
    public var provider: String?
    public var enabled: Bool?
    public var createdAt: String?
    public var updatedAt: String?

    public var isEnabled: Bool { enabled ?? true }
}

/// Habilidad (`GET /v1/skills`, `routes/skills.ts`).
/// Estados: en_revision, instalada, rechazada, desinstalada.
/// (Fase 5, sesión 1: las habilidades llegan aquí.)
public struct JeslySkill: Codable, Identifiable, Equatable {
    public var id: String
    public var name: String
    public var version: String?
    public var description: String?
    public var status: String
    public var createdAt: String?
    public var updatedAt: String?
}

/// Recordatorio (`GET /v1/reminders`, `routes/reminders.ts`,
/// forma exacta de `ReminderView` en `personal/reminders.ts`).
/// Un recordatorio ES un workflow programado de un solo disparo
/// con el marcador `[recordatorio]`; `id` es el id del workflow.
/// `estado`: pendiente | disparado | silenciado. `at` es el instante
/// UTC al que suena. (Fase 5, sesión 1.)
public struct JeslyReminder: Codable, Identifiable, Equatable {
    public var id: String
    public var text: String
    public var at: String
    public var schedule: String
    public var estado: String
    public var workflowId: String
    public var createdAt: String

    /// Fecha legible para la fila: la API ya manda `at` en ISO8601.
    public var atDate: Date? {
        ISO8601DateFormatter().date(from: at)
    }
}

/// Estado del demonio "Oye JESLY" (`GET /v1/voice/wake/status`,
/// `voice/wake.ts`). Demonio caído = listening false con 200, nunca 500.
/// (Sin uso en esta sesión; la voz llega en la Fase 4.)
public struct WakeStatus: Codable, Equatable, Sendable {
    public var listening: Bool
    public var state: String?
    public var engine: String?
    public var uptimeSeconds: Int?
    public var wakeCount: Int?
    public var error: String?

    public static let down = WakeStatus(
        listening: false, state: nil, engine: nil,
        uptimeSeconds: nil, wakeCount: 0, error: "demonio no responde"
    )

    /// Texto para la isla, en español y sin jerga.
    public var displayText: String {
        if listening {
            switch state {
            case "heard": return "Te escuchó — pensando…"
            case "thinking": return "Pensando…"
            case "speaking": return "Hablando…"
            default: return "Escuchando «Oye JESLY»"
            }
        }
        return "Escucha en pausa"
    }
}

// MARK: - Chat: proveedor JESLY (Fase 4, sesión 1)

/// Proveedor del router (`router/providers.ts`). El chat acepta
/// `provider`, NO `model`: el modelo lo elige el router por llamada
/// y vuelve en la respuesta (`ChatResponse.model`). La isla muestra
/// el modelo real de la última respuesta, nunca uno inventado.
///
/// Porte verbatim del `ChatProvider` struct de la isla actual
/// (`JeslyModels.swift`, HEAD `3e2a59db`), renombrado a
/// `JeslyChatProvider`: Coucou ya tiene un `enum ChatProvider`
/// (`CoucouKit/IslandTypes.swift:115`) y dos tipos con el mismo
/// nombre en el mismo módulo no compilan. La elección del proveedor
/// (selector en la vista de chat) llega en la Fase 4, sesión 2; este
/// struct es solo la lista y la búsqueda por id.
public struct JeslyChatProvider: Identifiable, Equatable, Sendable {
    public var id: String
    public var displayName: String
    /// Modelo por defecto que configura el router para este proveedor.
    public var defaultModel: String
    public var supportsVision: Bool

    public static let all: [JeslyChatProvider] = [
        JeslyChatProvider(id: "ollama-local", displayName: "Local (Ollama)", defaultModel: "qwen3:8b", supportsVision: false),
        JeslyChatProvider(id: "freellmapi", displayName: "FreeLLMAPI", defaultModel: "auto", supportsVision: true),
        JeslyChatProvider(id: "groq", displayName: "Groq", defaultModel: "openai/gpt-oss-20b", supportsVision: false),
        JeslyChatProvider(id: "gemini", displayName: "Gemini", defaultModel: "gemini-3.5-flash-lite", supportsVision: true),
        JeslyChatProvider(id: "openrouter", displayName: "OpenRouter", defaultModel: "openrouter/free", supportsVision: true),
    ]

    public static func byId(_ id: String) -> JeslyChatProvider? {
        all.first { $0.id == id }
    }
}

// MARK: - Verificación y publicación (Fase 4, sesión 1)

/// Una comprobación del informe de verificación
/// (`verify/verifier.ts`: `CheckResult`). `detail` es el motivo
/// exacto cuando falla; vacío cuando pasa.
public struct JeslyVerificationCheck: Codable, Equatable, Sendable {
    public var name: String
    public var type: String
    public var ok: Bool
    public var detail: String?

    public init(name: String = "", type: String = "", ok: Bool = false, detail: String? = nil) {
        self.name = name
        self.type = type
        self.ok = ok
        self.detail = detail
    }
}

/// Informe de `POST /v1/tasks/:id/verify` (`verify/verifier.ts`:
/// `VerificationReport`). Un veredicto con fallos NO es un error
/// HTTP: la ruta responde 200 con el informe, para que JC vea
/// exactamente qué falló y dónde. `passed` false no es excepción.
public struct JeslyVerificationReport: Codable, Equatable, Sendable {
    public var passed: Bool
    public var verifiedBy: String?
    public var verifiedAt: String?
    /// Contra qué se verificó (URL, commit o rama).
    public var target: String
    public var checks: [JeslyVerificationCheck]

    public init(passed: Bool = false, verifiedBy: String? = nil, verifiedAt: String? = nil, target: String = "", checks: [JeslyVerificationCheck] = []) {
        self.passed = passed
        self.verifiedBy = verifiedBy
        self.verifiedAt = verifiedAt
        self.target = target
        self.checks = checks
    }

    /// Resumen para la tarjeta: "en verde (2/2)" o "1 fallo: health".
    public var summary: String {
        let ok = checks.filter(\.ok).count
        if checks.isEmpty { return passed ? "en verde" : "sin comprobaciones" }
        if passed { return "en verde (\(ok)/\(checks.count))" }
        let firstFailed = checks.first { !$0.ok }
        return "\(checks.count - ok) fallo\(checks.count - ok == 1 ? "" : "s"): \(firstFailed?.name ?? "")"
    }
}

/// Resultado de `POST /v1/tasks/:id/publish`
/// (`publish/publish.ts`: `PublishRecord`). `status` es
/// "publicada" (push + deploy si tocaba + verificación en verde),
/// "parcial" (se publicó algo pero el deploy o la verificación
/// falló) o "fallida" (ni siquiera se pudo pushear). Nunca se
/// fusiona a main: eso lo decide JC.
public struct JeslyPublishRecord: Codable, Equatable, Sendable {
    public var status: String
    public var pushed: Bool
    public var branch: String
    public var commit: String
    public var deployed: Bool
    public var deployUrl: String?
    public var touchesCloud: Bool
    /// Dónde se verificó: la URL desplegada o la API/web local.
    public var target: String?
    public var verification: JeslyVerificationReport?
    /// Dónde falló: "push" | "deploy" | "verify" | nil.
    public var failedAt: String?
    public var error: String?
    public var publishedAt: String?

    public init(
        status: String = "", pushed: Bool = false, branch: String = "", commit: String = "",
        deployed: Bool = false, deployUrl: String? = nil, touchesCloud: Bool = false,
        target: String? = nil, verification: JeslyVerificationReport? = nil,
        failedAt: String? = nil, error: String? = nil, publishedAt: String? = nil
    ) {
        self.status = status
        self.pushed = pushed
        self.branch = branch
        self.commit = commit
        self.deployed = deployed
        self.deployUrl = deployUrl
        self.touchesCloud = touchesCloud
        self.target = target
        self.verification = verification
        self.failedAt = failedAt
        self.error = error
        self.publishedAt = publishedAt
    }

    /// Resumen para la tarjeta: "Publicada" / "Parcial: falló en
    /// deploy" / "Fallida: git push falló…".
    public var summary: String {
        switch status {
        case "publicada": return "Publicada"
        case "parcial": return "Parcial: falló en \(failedAt ?? "verificación")"
        case "fallida": return "Fallida: \(error ?? "sin motivo")"
        default: return status.isEmpty ? "Sin resultado" : status
        }
    }
}

// MARK: - Investigación profunda, cuentas conectadas y resumen diario (Fase 5, sesión 2)

/// Una fuente de `POST /v1/investigar` (`research/deep-research.ts`:
/// `ResearchSource`). `fecha` es la fecha de publicación si la
/// página la trae; si no, la fecha de consulta. `fechaPublicacion`
/// es null cuando la página no trae fecha. `verificada` es true
/// solo si la página se descargó y se leyó; si no, solo se tiene
/// el fragmento del buscador.
public struct JeslyResearchSource: Codable, Equatable, Sendable {
    public var titulo: String
    public var url: String
    public var fecha: String
    public var fechaPublicacion: String?
    public var verificada: Bool
    public var fragmento: String
}

/// Una página que no se pudo leer durante la investigación
/// (`research/deep-research.ts`: `FailedPage`).
public struct JeslyFailedPage: Codable, Equatable, Sendable {
    public var url: String
    public var motivo: String
}

/// Respuesta de `POST /v1/investigar` (`routes/investigar.ts`).
/// Exactamente lo que devuelve la ruta: `respuesta, fuentes,
/// fechaConsulta, consultas, paginasFallidas, fuente` y, solo
/// cuando el router sintetizó, `provider` y `model`. `fuente` es
/// "modelo" (el router sintetizó desde los hallazgos, con el
/// formato fijo) o "extractiva" (la composición determinista de
/// los fragmentos, cuando no hay router o el modelo falló).
public struct JeslyResearchResult: Codable, Equatable, Sendable {
    public var respuesta: String
    public var fuentes: [JeslyResearchSource]
    public var fechaConsulta: String
    public var consultas: [String]
    public var paginasFallidas: [JeslyFailedPage]
    public var fuente: String
    public var provider: String?
    public var model: String?

    /// "2 fuentes · 1 verificada" para la fila del chat.
    public var sourcesSummary: String {
        let verified = fuentes.filter(\.verificada).count
        return "\(fuentes.count) fuente\(fuentes.count == 1 ? "" : "s") · \(verified) verificada\(verified == 1 ? "" : "s")"
    }

    /// Día de la consulta (YYYY-MM-DD) para la fila del chat.
    public var consultationDay: String {
        String(fechaConsulta.prefix(10))
    }
}

/// Una cuenta conectada (`GET /v1/cuentas`, `accounts/store.ts`:
/// `PublicAccount`). Identidad y vigencia, NUNCA tokens: es lo
/// único que sale por las rutas. `proveedor` es "google" | "github".
/// Solo lectura en esta sesión: conectar una cuenta no se hace
/// desde la isla (Google es OAuth con redirect y GitHub pide un
/// token fine-grained de solo lectura).
public struct JeslyConnectedAccount: Codable, Identifiable, Equatable {
    public var proveedor: String
    public var cuenta: String
    public var scopes: [String]
    public var expira: String?
    public var conectado: String
    public var actualizado: String

    public var id: String { "\(proveedor):\(cuenta)" }

    /// "Google" / "GitHub" para la fila.
    public var providerDisplayName: String {
        proveedor == "github" ? "GitHub" : "Google"
    }
}

/// Un workflow programado para hoy, del resumen diario
/// (`personal/digest.ts`: `DigestWorkflowToday`). `at` es la
/// primera hora local a la que dispara hoy ("08:00").
public struct JeslyDigestWorkflowToday: Codable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var schedule: String
    public var at: String
}

/// Respuesta de `GET /v1/resumen-diario` (`routes/digest.ts`).
/// `digest` es el texto compuesto ("Buenos días, JC…"); los
/// contadores son lo mismo que el texto ya resume, para la fila.
/// `errores` nombra las fuentes que no se pudieron leer
/// ("propuestas", "tareas"…): una fuente caída no tumba el resumen.
public struct JeslyDailyDigest: Codable, Equatable, Sendable {
    public var digest: String
    public var propuestas: Int
    public var pendientes: Int
    public var workflowsHoy: [JeslyDigestWorkflowToday]
    public var recuerdos: Int
    public var errores: [String]
}

/// Respuesta de `POST /v1/resumen-diario` (`routes/digest.ts`).
/// `workflow` es el workflow programado (nombre "Resumen diario —
/// buenos días", la misma forma de `JeslyWorkflow`); `hora` es
/// "H:MM" y `pushConfigured` dice si las push están configuradas.
public struct JeslyDigestScheduleResponse: Codable, Equatable, Sendable {
    public var workflow: JeslyWorkflow
    public var hora: String
    public var pushConfigured: Bool?
}
