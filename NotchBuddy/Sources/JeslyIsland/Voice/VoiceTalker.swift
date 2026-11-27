import AVFoundation
import Foundation

/// Modo voz desde la isla: hablar y escuchar, con interrupción.
///
/// Ciclo (reutiliza las rutas que ya existen, como el demonio de
/// escucha — `services/wake-word/cycle.py` — que hace este mismo
/// ciclo del lado del servidor cuando oye "Oye JESLY"):
///   grabar (micrófono) → `POST /v1/voice/transcribe`
///   → `POST /v1/chat` (texto, sin herramientas)
///   → `POST /v1/voice/synthesize` (recortado a 1800 caracteres)
///   → reproducir el WAV.
/// El audio vive solo en memoria y se descarta al terminar.
///
/// Interrupción: `interrupt()` para la reproducción y la grabación
/// a la vez — JC puede cortar a JESLY en mitad de una frase, como
/// pide el plan (§1, voz completa con interrupción).
///
/// Porte verbatim de la isla actual
/// (`apps/island/Sources/JeslyIsland/Voice/VoiceTalker.swift`,
/// HEAD `3e2a59db`), sin `public`: en el fork todo JESLY es
/// interno al módulo. Sin sonidos de Mochi: la nube no suena
/// (decisión JC); aquí solo suena la voz sintetizada de JESLY.
///
/// El permiso de micrófono ya existe en el fork
/// (`NotchBuddy/project.yml`: `NSMicrophoneUsageDescription` en
/// los targets; lo pide macOS al empezar a grabar, igual que el
/// dictado Flow de Coucou). Sin permisos nuevos.
@MainActor
final class VoiceTalker: NSObject, ObservableObject {
    enum Phase: Equatable {
        case idle
        case recording
        case thinking
        case speaking
        case error(String)
    }

    @Published var phase: Phase = .idle
    @Published var lastHeard: String = ""
    @Published var lastReply: String = ""

    private var client: JeslyAPIClient
    private var provider: String?
    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var recordingURL: URL?

    init(client: JeslyAPIClient, provider: String? = nil) {
        self.client = client
        self.provider = provider
        super.init()
    }

    func updateClient(_ client: JeslyAPIClient, provider: String?) {
        self.client = client
        self.provider = provider
    }

    /// Empezar a grabar. Pide el permiso de micrófono de macOS la
    /// primera vez (NSMicrophoneUsageDescription en Info.plist).
    func startListening() {
        guard phase != .recording else { return }
        interrupt()
        // El permiso de micrófono lo pide macOS al empezar a grabar
        // (NSMicrophoneUsageDescription en Info.plist).
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("jesly-island-\(UUID().uuidString).wav")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
        ]
        do {
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.delegate = self
            recorder?.record()
            recordingURL = url
            phase = .recording
        } catch {
            phase = .error("No se pudo abrir el micrófono: \(error.localizedDescription)")
        }
    }

    /// Parar de grabar y procesar lo dicho.
    func stopListeningAndAnswer() async {
        guard phase == .recording else { return }
        recorder?.stop()
        recorder = nil
        guard let url = recordingURL else {
            phase = .error("No quedó audio grabado.")
            return
        }
        recordingURL = nil
        phase = .thinking
        defer { try? FileManager.default.removeItem(at: url) }
        do {
            let audio = try Data(contentsOf: url)
            let text = try await client.transcribe(audioData: audio, filename: "isla.wav", language: "es")
            lastHeard = text
            let reply = try await client.chat(message: text, provider: provider)
            lastReply = reply.text
            let spoken = String(reply.text.prefix(1800))
            let wav = try await client.synthesize(text: spoken)
            try play(wav: wav)
        } catch {
            phase = .error(error.localizedDescription)
        }
    }

    /// Interrupción: corta la voz de JESLY y la grabación.
    func interrupt() {
        player?.stop()
        player = nil
        if recorder?.isRecording == true { recorder?.stop() }
        recorder = nil
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
            recordingURL = nil
        }
        if phase == .speaking || phase == .recording || phase == .thinking {
            phase = .idle
        }
    }

    private func play(wav: Data) throws {
        player = try AVAudioPlayer(data: wav)
        player?.delegate = self
        player?.play()
        phase = .speaking
    }
}

extension VoiceTalker: @preconcurrency AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag, phase == .recording {
            phase = .error("La grabación se cortó.")
        }
    }
}

extension VoiceTalker: @preconcurrency AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if phase == .speaking { phase = .idle }
    }
}
