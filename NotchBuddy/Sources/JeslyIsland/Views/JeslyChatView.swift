import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// Vista de chat de JESLY en la isla (Fase 4, sesión 2).
///
/// Cromo reutilizado de la vista de chat de Coucou (`PromptView`):
/// fondo `CardBackground(wash: .indigo)`, lista con `ScrollViewReader`
/// que baja sola al último mensaje, fila de entrada con `TextField` y
/// botón de enviar (`SendButtonStyle`), mismo padding. Los mensajes
/// siguen el formato de la isla actual (`ChatView`, HEAD `3e2a59db`):
/// "Tú" / "JESLY" con el texto, y debajo de cada respuesta de JESLY
/// el modelo REAL que respondió (`ChatResponse.model`), nunca uno
/// inventado.
///
/// El chip de proveedor cicla como la isla: Automático → Ollama →
/// FreeLLMAPI → Groq → Gemini → OpenRouter. El modelo no se fija:
/// lo elige el router por llamada.
///
/// Voz y ojos (Fase 4, sesión 3), como la isla actual: el indicador
/// de "Oye JESLY" (punto hueso + texto del demonio, sondeado cada
/// 5 s por `JeslyVoiceStore`), el micrófono manual (`VoiceTalker`:
/// grabar → transcribir → chat → hablar, con interrupción) y la
/// zona para soltar archivos (imágenes 10 MB, videos 50 MB, máx.
/// 4 adjuntos y 1 video por mensaje) que van por `POST /v1/chat`
/// como `attachments`. Sin API no hay voz ni ojos y no hay errores
/// en la interfaz: antes del primer envío la vista lo dice claro,
/// y si el envío falla la respuesta es el mensaje de error de la
/// isla actual.
struct JeslyChatView: View {
    @ObservedObject private var store = JeslyChatStore.shared
    @ObservedObject private var voice = JeslyVoiceStore.shared
    // El talker se observa aparte: sus cambios de fase (grabando /
    // pensando / hablando) no llegan a la vista solo con observar
    // el store, que solo publica `wakeStatus` y `apiReachable`.
    @ObservedObject private var talker = JeslyVoiceStore.shared.talker
    @State private var text: String = ""
    @State private var pendingAttachments: [JeslyDroppedFile] = []
    @State private var dropNotice: String?
    @State private var answering: Bool = false
    @FocusState private var focused: Bool

    var body: some View {
        ZStack(alignment: .leading) {
            CardBackground(wash: .indigo)

            VStack(alignment: .leading, spacing: 6) {
                // Chip de proveedor (cicla al tocarlo) + estado de la API.
                HStack(spacing: 8) {
                    Button(action: { store.cycleProvider() }) {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(Color(hex: "#E8E0D0"))
                                .frame(width: 6, height: 6)
                            Text(store.providerLabel)
                                .font(.system(size: 10.5, weight: .medium))
                                .foregroundColor(Color(hex: "#7B8089"))
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 8))
                                .foregroundColor(Color(hex: "#5C6370"))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .help("Cambiar de proveedor (el router elige el modelo)")
                    // Indicador del demonio "Oye JESLY", como la isla
                    // actual: punto hueso cuando escucha, gris cuando
                    // no, con el texto del estado (`WakeStatus`).
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color(hex: voice.wakeStatus.listening ? "#E8E0D0" : "#6B7079"))
                            .frame(width: 5, height: 5)
                        Text("Oye JESLY")
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundColor(Color(hex: "#7B8089"))
                        Text(voice.wakeStatus.displayText)
                            .font(.system(size: 10.5))
                            .foregroundColor(Color(hex: "#5C6370"))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
                    Spacer()
                    if !store.messages.isEmpty {
                        Button("Limpiar") { store.clearHistory() }
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "#8E939C"))
                            .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)

                if !store.messages.isEmpty {
                    ScrollViewReader { proxy in
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(store.messages) { message in
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(message.role == .user ? "Tú" : "JESLY")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(Color(hex: "#8E939C"))
                                        Text(message.text)
                                            .font(.system(size: 13.5))
                                            .foregroundStyle(Color(hex: "#F5F6F8"))
                                            .textSelection(.enabled)
                                        // Modelo REAL de la respuesta, solo
                                        // en respuestas de JESLY y solo si
                                        // la API lo devolvió.
                                        if message.role == .jesly,
                                           let model = message.model, !model.isEmpty {
                                            let provider = message.provider ?? ""
                                            Text(provider.isEmpty ? model : "\(provider) · \(model)")
                                                .font(.system(size: 11))
                                                .foregroundStyle(Color(hex: "#8E939C"))
                                        }
                                        // Insignia de visión, solo cuando
                                        // la respuesta trae `vision` (ojos).
                                        if message.role == .jesly,
                                           let badge = message.visionBadge, !badge.isEmpty {
                                            Text(badge)
                                                .font(.system(size: 11))
                                                .foregroundStyle(Color(hex: "#8E939C"))
                                        }
                                        // Fuentes de la investigación
                                        // profunda (Fase 5, sesión 2):
                                        // la respuesta ya trae el
                                        // informe en formato fijo; aquí
                                        // las fuentes son enlaces que
                                        // se pueden abrir, con su fecha
                                        // y si se verificó o no.
                                        if message.role == .jesly,
                                           let research = message.research {
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text("Investigación · \(research.fuente) · \(research.sourcesSummary) · \(research.consultationDay)")
                                                    .font(.system(size: 11))
                                                    .foregroundStyle(Color(hex: "#8E939C"))
                                                ForEach(Array(research.fuentes.enumerated()), id: \.offset) { _, source in
                                                    if let url = URL(string: source.url) {
                                                        Link(destination: url) {
                                                            HStack(spacing: 4) {
                                                                Image(systemName: source.verificada ? "checkmark.circle" : "exclamationmark.circle")
                                                                    .font(.system(size: 10))
                                                                Text("\(source.titulo) — \(source.fecha)")
                                                                    .font(.system(size: 11))
                                                            }
                                                            .foregroundStyle(Color(hex: "#8AB4F8"))
                                                        }
                                                    }
                                                }
                                                if !research.paginasFallidas.isEmpty {
                                                    Text("\(research.paginasFallidas.count) página\(research.paginasFallidas.count == 1 ? "" : "s") no se \(research.paginasFallidas.count == 1 ? "pudo leer" : "pudieron leer") y \(research.paginasFallidas.count == 1 ? "quedó" : "quedaron") sin verificar.")
                                                        .font(.system(size: 11))
                                                        .foregroundStyle(Color(hex: "#8E939C"))
                                                }
                                            }
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(8)
                                    .background(message.role == .user
                                                ? Color.white.opacity(0.06) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .id(message.id)
                                }
                                if store.sending {
                                    HStack { TypingDotsView(); Spacer(minLength: 32) }
                                        .id("typing")
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        .onChange(of: store.messages) { _, _ in
                            if let last = store.messages.last {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                        .onChange(of: store.sending) { _, sending in
                            if sending {
                                withAnimation { proxy.scrollTo("typing", anchor: .bottom) }
                            } else if let last = store.messages.last {
                                withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                            }
                        }
                        .onAppear {
                            if let last = store.messages.last {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    Spacer()
                    Text(store.apiReachable
                         ? "Pregúntale algo a JESLY…"
                         : "La API de JESLY no responde en 127.0.0.1:3000. Arráncala con scripts/arrancar-todo.sh y vuelve a intentarlo.")
                        .font(.system(size: 12.5))
                        .foregroundStyle(Color(hex: "#8E939C"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10)
                    Spacer()
                }

                // Zona para soltar archivos (ojos), como la isla
                // actual: imágenes y videos que JESLY describe.
                dropZone

                if !pendingAttachments.isEmpty {
                    attachmentRow
                }

                if let notice = dropNotice {
                    Text(notice)
                        .font(.system(size: 11.5))
                        .foregroundStyle(Color(hex: "#F5A524"))
                        .padding(.horizontal, 10)
                }

                // Estado del modo voz manual, cuando está activo.
                if talker.phase != .idle {
                    Text(voiceStatusText)
                        .font(.system(size: 11.5))
                        .foregroundStyle(Color(hex: "#8E939C"))
                        .padding(.horizontal, 10)
                }

                // Estado de la investigación profunda, cuando está
                // en vuelo: tarda más que un chat normal (varias
                // búsquedas + descarga de páginas).
                if store.researching {
                    Text("Investigando en la web… puede tardar unos segundos.")
                        .font(.system(size: 11.5))
                        .foregroundStyle(Color(hex: "#8E939C"))
                        .padding(.horizontal, 10)
                }

                // Fila de entrada, como `PromptView`.
                HStack(spacing: 8) {
                    TextField(store.researchMode ? "Investiga en la web…" : (store.messages.isEmpty ? "Pregúntale algo a JESLY…" : "Continúa…"), text: $text)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .focused($focused)
                        .writingToolsBehavior(.disabled)
                        .onSubmit { sendMessage() }

                    researchButton

                    micButton

                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "#0B0C0E"))
                    }
                    .buttonStyle(SendButtonStyle())
                    .disabled((text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && pendingAttachments.isEmpty) || store.sending)
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Color.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .simultaneousGesture(TapGesture().onEnded { focused = true })

                if let error = store.lastError {
                    Text(error)
                        .font(.system(size: 11.5))
                        .foregroundStyle(Color(hex: "#F5A524"))
                        .padding(.horizontal, 10)
                }
            }
            .padding(.leading, 84)
            .padding(.trailing, 16)
            .padding(.top, 12)
            .padding(.bottom, 14)
        }
        .padding(.bottom, 10)
        .onAppear { focused = true }
        .onDrop(of: [.image, .movie], isTargeted: nil) { providers in
            handleDrop(providers: providers)
        }
    }

    private func sendMessage() {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty || !pendingAttachments.isEmpty, !store.sending else { return }
        text = ""
        // Modo investigar (Fase 5, sesión 2): sin adjuntos, el
        // envío va por `POST /v1/investigar` en vez de por el chat.
        // Con adjuntos no hay investigación: cae al chat normal.
        if store.researchMode, pendingAttachments.isEmpty {
            dropNotice = nil
            Task { await store.sendResearch(query) }
            return
        }
        let attachments = pendingAttachments.map { file in
            ChatAttachment(kind: file.kind, mediaType: file.mediaType, data: file.data.base64EncodedString())
        }
        pendingAttachments = []
        dropNotice = nil
        Task { await store.send(query, attachments: attachments) }
    }

    // MARK: - Ojos (soltar archivo)

    /// Zona para soltar archivos, como la isla actual: borde
    /// punteado y texto claro. Acepta imágenes y videos
    /// (`.onDrop(of: [.image, .movie])` en toda la vista).
    private var dropZone: some View {
        HStack(spacing: 10) {
            Image(systemName: "tray.and.arrow.up")
                .font(.system(size: 13))
            Text("Suelta un archivo aquí y JESLY te pregunta qué quieres hacer con él.")
                .font(.system(size: 11.5))
        }
        .foregroundStyle(Color(hex: "#8E939C"))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .padding(.horizontal, 2)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.white.opacity(0.25), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
        )
        .padding(.horizontal, 10)
    }

    private var attachmentRow: some View {
        HStack(spacing: 6) {
            ForEach(pendingAttachments) { file in
                Label(file.name, systemImage: file.kind == "video" ? "film" : "photo")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "#F5F6F8"))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
            }
            Spacer()
            Button("Quitar") { pendingAttachments = [] }
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "#8E939C"))
        }
        .padding(.horizontal, 10)
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var accepted = false
        for provider in providers {
            if pendingAttachments.count >= 4 { break }
            if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                load(provider: provider, kind: "video")
                accepted = true
            } else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                load(provider: provider, kind: "image")
                accepted = true
            }
        }
        return accepted
    }

    private func load(provider: NSItemProvider, kind: String) {
        let type = kind == "video" ? UTType.movie : UTType.image
        // El nombre se lee aquí, antes del cierre asíncrono: NSItemProvider
        // no es Sendable y no puede cruzarse a la tarea del actor principal.
        let suggestedName = provider.suggestedName
        provider.loadDataRepresentation(forTypeIdentifier: type.identifier) { data, error in
            guard let data, error == nil else { return }
            Task { @MainActor in
                // Límites del servidor, validados antes de enviar.
                let maxBytes = kind == "video" ? 50 * 1024 * 1024 : 10 * 1024 * 1024
                if data.count > maxBytes {
                    dropNotice = "Ese \(kind == "video" ? "video" : "imagen") pasa el límite (\(kind == "video" ? "50 MB" : "10 MB"))."
                    return
                }
                if kind == "video", pendingAttachments.contains(where: { $0.kind == "video" }) {
                    dropNotice = "Solo un video por mensaje."
                    return
                }
                let mediaType = kind == "video" ? "video/mp4" : "image/png"
                pendingAttachments.append(JeslyDroppedFile(
                    name: suggestedName ?? (kind == "video" ? "video" : "imagen"),
                    kind: kind,
                    mediaType: mediaType,
                    data: data
                ))
                dropNotice = nil
            }
        }
    }

    // MARK: - Investigación profunda (Fase 5, sesión 2)

    /// Botón de investigación: activa el modo investigar; el envío
    /// va por `POST /v1/investigar` en vez de por el chat. La isla
    /// actual no tiene este botón: su agente investiga con la
    /// herramienta interna (`investigar_profundo`); aquí la
    /// investigación se pide explícita desde el chat y el informe
    /// llega con sus fuentes.
    private var researchButton: some View {
        Button(action: { store.toggleResearchMode() }) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(store.researchMode ? Color(hex: "#0B0C0E") : Color(hex: "#F5F6F8"))
                .frame(width: 32, height: 32)
                .background(store.researchMode ? Color(hex: "#E8E0D0") : Color.white.opacity(0.07))
                .clipShape(Circle())
                .overlay(Circle().stroke(store.researchMode ? Color(hex: "#E8E0D0") : Color.white.opacity(0.22), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(store.sending)
        .help(store.researchMode ? "Investigando en la web: toca para volver al chat" : "Investigar en la web (con fuentes)")
    }

    // MARK: - Voz (micrófono manual)

    private var micIsRecording: Bool {
        if case .recording = talker.phase { return true }
        return false
    }

    /// Texto del estado del modo voz, en español y sin jerga.
    private var voiceStatusText: String {
        switch talker.phase {
        case .recording: return "Escuchando… toca el micrófono para terminar."
        case .thinking: return "Pensando…"
        case .speaking: return "Hablando… toca ■ para interrumpir."
        case .error(let message): return message
        case .idle: return ""
        }
    }

    /// Botón del micrófono, como la isla actual: micrófono en
    /// reposo, grabando en hueso, ■ mientras habla (interrumpe),
    /// spinner mientras piensa. Sin API, el error llega claro por
    /// `VoiceTalker.phase == .error`.
    private var micButton: some View {
        Button(action: micTapped) {
            Group {
                switch talker.phase {
                case .thinking:
                    ProgressView().controlSize(.small)
                case .speaking:
                    Image(systemName: "stop.fill").font(.system(size: 13))
                default:
                    Image(systemName: "mic.fill").font(.system(size: 14))
                }
            }
            .foregroundStyle(micIsRecording ? Color(hex: "#0B0C0E") : Color(hex: "#F5F6F8"))
            .frame(width: 32, height: 32)
            .background(micIsRecording ? Color(hex: "#E8E0D0") : Color.white.opacity(0.07))
            .clipShape(Circle())
            .overlay(Circle().stroke(micIsRecording ? Color(hex: "#E8E0D0") : Color.white.opacity(0.22), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(answering || talker.phase == .thinking)
        .help("Dictar por voz")
    }

    private func micTapped() {
        switch talker.phase {
        case .idle, .error:
            voice.prepareTalker()
            talker.startListening()
        case .recording:
            answering = true
            Task {
                await talker.stopListeningAndAnswer()
                answering = false
                // El intercambio de voz queda en el historial del
                // chat, como un mensaje normal (sin modelo: el
                // talker solo guarda el texto de la respuesta).
                store.appendVoiceExchange(heard: talker.lastHeard, reply: talker.lastReply)
            }
        case .thinking:
            break
        case .speaking:
            talker.interrupt()
        }
    }
}

/// Archivo soltado en el chat, listo para enviar como adjunto.
struct JeslyDroppedFile: Identifiable, Equatable {
    var id = UUID()
    var name: String
    var kind: String  // "image" | "video"
    var mediaType: String
    var data: Data
}
