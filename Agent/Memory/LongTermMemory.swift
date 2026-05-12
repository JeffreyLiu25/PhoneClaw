import Foundation

struct MemoryItem: Codable, Identifiable {
    let id: UUID
    let content: String
    let summary: String?
    let category: MemoryCategory
    let tags: [String]
    let source: MemorySource
    let importance: Double
    let createdAt: Date
    let lastAccessedAt: Date?
    let accessCount: Int
    
    enum MemoryCategory: String, Codable {
        case conversation
        case task
        case fact
        case preference
        case document
        case note
    }
    
    enum MemorySource: String, Codable {
        case userInput
        case toolResult
        case system
        case userEdited
        case importSource
    }
}

struct MemorySearchResult {
    let item: MemoryItem
    let relevanceScore: Double
}

class LongTermMemoryStore {
    static let shared = LongTermMemoryStore()
    
    private let fileManager = FileManager.default
    private let memoryFileName = "long_term_memory.json"
    private var memoryIndex: [UUID: MemoryItem] = [:]
    private var tagIndex: [String: Set<UUID>] = [:]
    private var categoryIndex: [MemoryItem.MemoryCategory: Set<UUID>] = [:]
    
    private var memoryURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let phoneClawDir = appSupport.appendingPathComponent("PhoneClaw", isDirectory: true)
        try? fileManager.createDirectory(at: phoneClawDir, withIntermediateDirectories: true)
        return phoneClawDir.appendingPathComponent(memoryFileName)
    }
    
    private init() {
        loadFromDisk()
    }
    
    func store(
        content: String,
        summary: String? = nil,
        category: MemoryItem.MemoryCategory = .fact,
        tags: [String] = [],
        source: MemoryItem.MemorySource = .system,
        importance: Double = 0.5
    ) {
        let item = MemoryItem(
            id: UUID(),
            content: content,
            summary: summary,
            category: category,
            tags: tags,
            source: source,
            importance: importance,
            createdAt: Date(),
            lastAccessedAt: nil,
            accessCount: 0
        )
        
        addToIndices(item)
        saveToDisk()
    }
    
    func retrieve(byId id: UUID) -> MemoryItem? {
        guard var item = memoryIndex[id] else { return nil }
        memoryIndex[id] = accessed(item)
        return item
    }
    
    func search(query: String, limit: Int = 10) -> [MemorySearchResult] {
        let results = memoryIndex.values.map { item in
            let score = calculateRelevance(query: query, item: item)
            return MemorySearchResult(item: item, relevanceScore: score)
        }.filter { $0.relevanceScore > 0 }
            .sorted { $0.relevanceScore > $1.relevanceScore }
            .prefix(limit)
            .map { result in
                var item = result.item
                item = accessed(item)
                return MemorySearchResult(item: item, relevanceScore: result.relevanceScore)
            }
        
        saveToDisk()
        return results
    }
    
    func search(byCategory category: MemoryItem.MemoryCategory, limit: Int = 50) -> [MemoryItem] {
        let ids = categoryIndex[category] ?? []
        return ids.compactMap { memoryIndex[$0] }
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(limit)
            .map { accessed($0) }
    }
    
    func search(byTag tag: String, limit: Int = 50) -> [MemoryItem] {
        let ids = tagIndex[tag.lowercased()] ?? []
        return ids.compactMap { memoryIndex[$0] }
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(limit)
            .map { accessed($0) }
    }
    
    func recent(limit: Int = 20) -> [MemoryItem] {
        Array(memoryIndex.values.sorted { $0.createdAt > $1.createdAt }.prefix(limit))
    }
    
    func updateImportance(id: UUID, importance: Double) {
        guard var item = memoryIndex[id] else { return }
        memoryIndex[id] = MemoryItem(
            id: item.id,
            content: item.content,
            summary: item.summary,
            category: item.category,
            tags: item.tags,
            source: item.source,
            importance: importance,
            createdAt: item.createdAt,
            lastAccessedAt: item.lastAccessedAt,
            accessCount: item.accessCount
        )
        saveToDisk()
    }
    
    func delete(id: UUID) {
        guard let item = memoryIndex.removeValue(forKey: id) else { return }
        removeFromIndices(item)
        saveToDisk()
    }
    
    private func addToIndices(_ item: MemoryItem) {
        memoryIndex[item.id] = item
        
        categoryIndex[item.category, default: []].insert(item.id)
        
        for tag in item.tags {
            tagIndex[tag.lowercased(), default: []].insert(item.id)
        }
    }
    
    private func removeFromIndices(_ item: MemoryItem) {
        categoryIndex[item.category]?.remove(item.id)
        
        for tag in item.tags {
            tagIndex[tag.lowercased()]?.remove(item.id)
        }
    }
    
    private func accessed(_ item: MemoryItem) -> MemoryItem {
        let updated = MemoryItem(
            id: item.id,
            content: item.content,
            summary: item.summary,
            category: item.category,
            tags: item.tags,
            source: item.source,
            importance: item.importance,
            createdAt: item.createdAt,
            lastAccessedAt: Date(),
            accessCount: item.accessCount + 1
        )
        memoryIndex[item.id] = updated
        return updated
    }
    
    private func calculateRelevance(query: String, item: MemoryItem) -> Double {
        let queryLower = query.lowercased()
        var score = 0.0
        
        if item.content.lowercased().contains(queryLower) {
            score += 1.0
        }
        
        if let summary = item.summary, summary.lowercased().contains(queryLower) {
            score += 0.8
        }
        
        let tagMatchCount = item.tags.filter { queryLower.contains($0.lowercased()) }.count
        score += Double(tagMatchCount) * 0.5
        
        score += item.importance * 0.3
        
        if let lastAccess = item.lastAccessedAt {
            let daysSinceAccess = Date().timeIntervalSince(lastAccess) / (60 * 60 * 24)
            let recencyBoost = max(0, 1.0 - daysSinceAccess / 30.0)
            score += recencyBoost * 0.2
        }
        
        let accessBoost = min(Double(item.accessCount) / 10.0, 1.0)
        score += accessBoost * 0.1
        
        return score
    }
    
    private func saveToDisk() {
        let items = Array(memoryIndex.values)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(items) {
            try? data.write(to: memoryURL)
        }
    }
    
    private func loadFromDisk() {
        guard let data = try? Data(contentsOf: memoryURL),
              let items = try? JSONDecoder().decode([MemoryItem].self, from: data) else {
            return
        }
        
        for item in items {
            addToIndices(item)
        }
    }
    
    func buildMemoryPrompt(query: String? = nil) -> String {
        var prompt = ""
        
        let recentItems = recent(limit: 5)
        if !recentItems.isEmpty {
            prompt += "## 最近的记忆\n\n"
            for item in recentItems {
                prompt += "- [\(item.createdAt.formatted())] \(item.summary ?? item.content.prefix(100))\n"
            }
            prompt += "\n"
        }
        
        if let query = query {
            let searchResults = search(query: query, limit: 5)
            if !searchResults.isEmpty {
                prompt += "## 相关记忆\n\n"
                for result in searchResults {
                    prompt += "- \(result.item.summary ?? result.item.content.prefix(150))\n"
                }
                prompt += "\n"
            }
        }
        
        return prompt
    }
}
