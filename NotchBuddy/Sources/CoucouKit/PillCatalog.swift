import Foundation

// MARK: - Pill category

enum PillCategory: String, CaseIterable {
    case workspace
    case agent
    case ai
    case service

    var title: String {
        switch self {
        case .workspace: return String(localized: "Where you code")
        case .agent:     return String(localized: "Agents")
        case .ai:        return String(localized: "AI for the chat")
        case .service:   return String(localized: "Services")
        }
    }
}

// MARK: - Pill definition

struct PillDefinition {
    let id:         String
    let name:       String
    /// The catalog's colour for this pill, whatever the user picked.
    let defaultColor: String
    let category:   PillCategory
    /// Label shown next to the task name in the idle card header.
    let subtitle:   String
    let source:     AgentSource
    var comingSoon: Bool = false
    var githubOnly: Bool = false

    /// The colour the pill is painted with: the user's own if they picked one
    /// (Settings → Active pills), else the catalog's.
    var color: String {
        PillColors.color(for: id, catalogColor: defaultColor, in: PillColors.stored)
    }

    init(id: String, name: String, color: String, category: PillCategory, subtitle: String,
         source: AgentSource, comingSoon: Bool = false, githubOnly: Bool = false) {
        self.id = id
        self.name = name
        self.defaultColor = color
        self.category = category
        self.subtitle = subtitle
        self.source = source
        self.comingSoon = comingSoon
        self.githubOnly = githubOnly
    }

    /// Label shown in the active-session card header (workspace/agent pills only).
    var sessionSubtitle: String {
        switch id {
        case "integration_claude": return "Claude Code"
        case "agent_cursor":       return "Cursor"
        case "agent_codex":        return "Codex"
        default:                   return String(localized: "Agent")
        }
    }
}

// MARK: - Catalog

enum PillCatalog {
    // All declared pills in display order.
    static let all: [PillDefinition] = [
        // ── Where you code ───────────────────────────────────────────────────
        .init(id: "integration_claude",  name: "VS Code",     color: "#F5F6F8",
              category: .workspace, subtitle: String(localized: "Integration"),  source: .claudeCode),
        .init(id: "agent_cursor",        name: "Cursor",      color: "#C0C4CC",
              category: .workspace, subtitle: String(localized: "Integration"),  source: .agent),
        .init(id: "agent_codex",         name: "Codex",       color: "#2DD4BF",
              category: .workspace, subtitle: String(localized: "Integration"),  source: .agent,  githubOnly: true),
        // ── Agents ───────────────────────────────────────────────────────────
        .init(id: "agent_gemini",        name: "Gemini CLI",  color: "#8AB4F8",
              category: .agent,     subtitle: String(localized: "Agent"),        source: .agent,  githubOnly: true),
        // ── JESLY (Fase 3) ───────────────────────────────────────────────────
        // Propuestas de JESLY esperando aprobación de JC: las trae
        // `JeslyProposalsPoller` de la API local (127.0.0.1:3000), cada 5 s.
        // `source: .agent` es solo el metadato de origen del catálogo: los
        // datos NO vienen de un hook (`nb-hook`), sino del sondeo a la API.
        // La tarjeta de Propuesta/Permiso llega en la sesión 2; hasta
        // entonces la pill solo aparece en Ajustes → Active pills (hay que
        // activar una pill a la vez: el máximo es 4 y por defecto ya hay 4).
        .init(id: "jesly_propuestas", name: "JESLY", color: "#E8E0D0",
              category: .agent,     subtitle: String(localized: "Agent"),        source: .agent),
        // ── JESLY voz (Fase 4, sesión 3) ─────────────────────────────────────
        // La voz "Oye JESLY" no es un spotter propio: el demonio Vosk
        // local (`services/wake-word/daemon.py`) escucha por su cuenta
        // y hace el ciclo STT → chat → TTS del lado del servidor; la
        // app solo sondea su estado (`GET /v1/voice/wake/status`,
        // `JeslyVoiceStore`) y ofrece el micrófono manual
        // (`VoiceTalker`). La pill solo registra la voz en Ajustes →
        // Active pills; sin demonio ni API, muestra "Escucha en pausa".
        .init(id: "jesly_voz",           name: "JESLY Voz",   color: "#E8E0D0",
              category: .agent,     subtitle: String(localized: "Agent"),        source: .agent),
        // ── AI for the chat ──────────────────────────────────────────────────
        // ── JESLY chat (Fase 4, sesión 1) ────────────────────────────────────
        // El chat de JESLY no habla con Anthropic/OpenAI directo: va
        // por la API local (`POST /v1/chat`, `JeslyAPIClient.chat`),
        // con la misma clave del llavero que las propuestas y sin
        // fijar modelo — el router elige y la respuesta trae el
        // modelo real. La vista de chat con el selector de proveedor
        // (`JeslyChatProvider`) llega en la Fase 4, sesión 2; esta
        // pill solo registra el chat en Ajustes → Active pills.
        // `source: .agent` (no `.n8n` como las demás de chat): los
        // datos vienen de la API local, no de n8n.
        .init(id: "jesly_chat",          name: "JESLY Chat",  color: "#E8E0D0",
              category: .ai,        subtitle: String(localized: "Chat"),         source: .agent),
        // ── Services ─────────────────────────────────────────────────────────
        .init(id: "integration_vercel",  name: "Vercel",      color: "#7C5CFF",
              category: .service,   subtitle: String(localized: "Integration"),  source: .n8n),
        .init(id: "integration_github",  name: "GitHub",      color: "#F4505E",
              category: .service,   subtitle: String(localized: "Integration"),  source: .n8n),
    ]

    /// Pills available in the current build target.
    static var available: [PillDefinition] {
        #if APPSTORE
        all.filter { !$0.githubOnly }
        #else
        all
        #endif
    }

    /// Default ID for the always-on main workspace pill.
    static let defaultMainPillId = "integration_claude"

    /// The catalog pill an ID stands for. A second session's own pill ("integration_claude#2",
    /// SessionPillMap) and the iPhone record of a second question behind a pill
    /// ("integration_claude#q2", QueuedQuestion.phoneRecordId) read as that pill; pill IDs
    /// themselves never contain "#".
    static func basePillId(_ id: String) -> String {
        id.firstIndex(of: "#").map { String(id[..<$0]) } ?? id
    }

    /// Looks up a definition by task ID (nil if not in catalog), see `basePillId`.
    static func definition(for id: String) -> PillDefinition? {
        let pill = basePillId(id)
        return all.first { $0.id == pill }
    }
}
