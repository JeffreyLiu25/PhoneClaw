import Foundation

struct UserPreference: Codable {
    let key: String
    let value: String
    let updatedAt: Date
}

struct UserContact: Codable, Identifiable {
    let id: UUID
    let name: String
    let email: String?
    let phone: String?
    let role: String?
    let tags: [String]
}

struct UserProfile: Codable {
    let id: UUID
    var name: String
    var email: String
    var avatarURL: String?
    var timezone: String
    var language: String
    var preferences: [UserPreference]
    var contacts: [UserContact]
    var createdAt: Date
    var updatedAt: Date
    
    static let defaultProfile = UserProfile(
        id: UUID(),
        name: "用户",
        email: "",
        timezone: TimeZone.current.identifier,
        language: Locale.current.identifier,
        preferences: [],
        contacts: [],
        createdAt: Date(),
        updatedAt: Date()
    )
    
    func getPreference(forKey key: String) -> String? {
        preferences.first { $0.key == key }?.value
    }
    
    mutating func setPreference(key: String, value: String) {
        if let index = preferences.firstIndex(where: { $0.key == key }) {
            preferences[index] = UserPreference(key: key, value: value, updatedAt: Date())
        } else {
            preferences.append(UserPreference(key: key, value: value, updatedAt: Date()))
        }
        updatedAt = Date()
    }
    
    mutating func addContact(_ contact: UserContact) {
        contacts.append(contact)
        updatedAt = Date()
    }
    
    mutating func removeContact(id: UUID) {
        contacts.removeAll { $0.id == id }
        updatedAt = Date()
    }
    
    func findContacts(byTag tag: String) -> [UserContact] {
        contacts.filter { $0.tags.contains(tag) }
    }
}

class UserProfileManager {
    static let shared = UserProfileManager()
    
    private let fileManager = FileManager.default
    private let profileFileName = "user_profile.json"
    private var currentProfile: UserProfile?
    
    private var profileURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let phoneClawDir = appSupport.appendingPathComponent("PhoneClaw", isDirectory: true)
        try? fileManager.createDirectory(at: phoneClawDir, withIntermediateDirectories: true)
        return phoneClawDir.appendingPathComponent(profileFileName)
    }
    
    private init() {}
    
    func loadProfile() -> UserProfile {
        if let profile = currentProfile {
            return profile
        }
        
        if let data = try? Data(contentsOf: profileURL),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            currentProfile = profile
            return profile
        }
        
        let profile = UserProfile.defaultProfile
        currentProfile = profile
        saveProfile(profile)
        return profile
    }
    
    func saveProfile(_ profile: UserProfile) {
        currentProfile = profile
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(profile) {
            try? data.write(to: profileURL)
        }
    }
    
    func updateProfile(_ update: (inout UserProfile) -> Void) {
        var profile = loadProfile()
        update(&profile)
        saveProfile(profile)
    }
    
    func buildProfilePrompt() -> String {
        let profile = loadProfile()
        var prompt = """
        # 用户信息
        
        姓名：\(profile.name)
        """
        
        if !profile.email.isEmpty {
            prompt += "\n邮箱：\(profile.email)"
        }
        
        if !profile.preferences.isEmpty {
            prompt += "\n\n## 用户偏好\n"
            for pref in profile.preferences {
                prompt += "- \(pref.key)：\(pref.value)\n"
            }
        }
        
        if !profile.contacts.isEmpty {
            prompt += "\n## 常用联系人\n"
            for contact in profile.contacts.prefix(10) {
                prompt += "- \(contact.name)"
                if let role = contact.role {
                    prompt += " (\(role))"
                }
                if let email = contact.email {
                    prompt += " - \(email)"
                }
                prompt += "\n"
            }
            if profile.contacts.count > 10 {
                prompt += "... 还有 \(profile.contacts.count - 10) 个联系人\n"
            }
        }
        
        return prompt
    }
}
