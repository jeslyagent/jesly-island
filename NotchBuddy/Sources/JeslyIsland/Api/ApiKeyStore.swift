import Foundation
import Security

/// Dónde vive la clave de la API local (JESLY_API_KEY).
///
/// Orden de lectura (nunca hardcodeada, nunca en logs):
///   1. Llavero de macOS (servicio `com.jesly.island`, cuenta
///      `jesly-api-key`) — lo escribe la isla la primera vez que
///      JC la pega en Ajustes, o `security add-generic-password`.
///   2. Variable de entorno `JESLY_API_KEY` (solo en la Mac de JC).
///
/// Sin clave, la API local acepta igual en local (avisa en el log del
/// servidor); la isla lo indica como "sin clave" y sigue funcionando.
///
/// Origen: `jeslyagent/Jesly-agent-ai`, `apps/island/Sources/JeslyIsland/Api/ApiKeyStore.swift`,
/// HEAD `3e2a59db`. Copia verbatim (Fase 3, sesión 1).
///
/// NOTA DE LLAVERO: el servicio es `com.jesly.island`, el bundle id
/// propuesto para el fork (hoy el build sigue con
/// `fr.louisraille.NotchBuddy`, ver README-FASE2 §8). El servicio de
/// llavero es solo un nombre de clave, no depende del bundle id del
/// build, así que la clave guardada por la isla actual se lee igual
/// desde el fork. Si en la Fase 6 cambia el grupo de acceso del
/// llavero, hay que revisar esto.
public enum ApiKeyStore {
    public static let service = "com.jesly.island"
    public static let account = "jesly-api-key"

    public static func read() -> String? {
        if let fromKeychain = readFromKeychain(), !fromKeychain.isEmpty {
            return fromKeychain
        }
        let fromEnv = ProcessInfo.processInfo.environment["JESLY_API_KEY"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (fromEnv?.isEmpty == false) ? fromEnv : nil
    }

    public static func save(_ key: String) -> Bool {
        let data = Data(key.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked
        return SecItemAdd(attributes as CFDictionary, nil) == errSecSuccess
    }

    public static func delete() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }

    private static func readFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8)
        else { return nil }
        return key
    }
}
