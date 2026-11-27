import SwiftUI

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
/// Sin zona para soltar archivos (ojos) ni micrófono (voz): eso
/// llega en sesiones posteriores de la Fase 4, no aquí.
///
/// Sin API no hay chat y no hay errores en la interfaz: antes del
/// primer envío la vista lo dice claro, y si el envío falla la
/// respuesta es el mensaje de error de la isla actual.
struct JeslyChatView: View {
    @ObservedObject private var store = JeslyChatStore.shared
    @State private var text: String = ""
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

                // Fila de entrada, como `PromptView`.
                HStack(spacing: 8) {
                    TextField(store.messages.isEmpty ? "Pregúntale algo a JESLY…" : "Continúa…", text: $text)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .focused($focused)
                        .writingToolsBehavior(.disabled)
                        .onSubmit { sendMessage() }

                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "#0B0C0E"))
                    }
                    .buttonStyle(SendButtonStyle())
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.sending)
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
    }

    private func sendMessage() {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty, !store.sending else { return }
        text = ""
        Task { await store.send(query) }
    }
}
