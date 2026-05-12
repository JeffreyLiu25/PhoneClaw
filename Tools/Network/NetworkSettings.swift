import Foundation

class NetworkSettings {
    static let shared = NetworkSettings()
    
    private let userDefaults = UserDefaults.standard
    private let networkEnabledKey = "network_enabled"
    private let confirmBeforeRequestKey = "confirm_before_network_request"
    
    private init() {}
    
    var isNetworkEnabled: Bool {
        get { userDefaults.bool(forKey: networkEnabledKey) }
        set { userDefaults.set(newValue, forKey: networkEnabledKey) }
    }
    
    var shouldConfirmBeforeRequest: Bool {
        get { userDefaults.bool(forKey: confirmBeforeRequestKey) }
        set { userDefaults.set(newValue, forKey: confirmBeforeRequestKey) }
    }
    
    func enableNetwork() {
        isNetworkEnabled = true
    }
    
    func disableNetwork() {
        isNetworkEnabled = false
    }
}

class KeychainManager {
    static let shared = KeychainManager()
    
    private let service = "com.phoneclaw.tokens"
    
    private init() {}
    
    func save(token: String, for account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: token.data(using: .utf8)!
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func getToken(for account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var data: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &data)
        
        guard status == errSecSuccess,
              let tokenData = data as? Data,
              let token = String(data: tokenData, encoding: .utf8) else {
            return nil
        }
        
        return token
    }
    
    func deleteToken(for account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
