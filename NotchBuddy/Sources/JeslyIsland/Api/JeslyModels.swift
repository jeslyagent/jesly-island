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
/// de la isla NO se porta aquí. Coucou ya tiene un `enum ChatProvider`
/// (`CoucouKit/IslandTypes.swift:115`) y dos tipos con el mismo nombre
/// en el mismo módulo no compilan. En la Fase 4, cuando llegue el
/// proveedor de chat JESLY, se porta como `JeslyChatProvider`.
/// Ningún método del cliente de esta sesión lo usa.

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
/// (Sin uso en esta sesión; el chat llega en la Fase 4.)
public struct ChatResponse: Codable, Equatable {
    public var text: String
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
/// (Sin uso en esta sesión; los workflows llegan en la Fase 5.)
public struct JeslyWorkflow: Codable, Identifiable, Equatable {
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
/// (Sin uso en esta sesión; las habilidades llegan en la Fase 5.)
public struct JeslySkill: Codable, Identifiable, Equatable {
    public var id: String
    public var name: String
    public var version: String?
    public var description: String?
    public var status: String
    public var createdAt: String?
    public var updatedAt: String?
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
