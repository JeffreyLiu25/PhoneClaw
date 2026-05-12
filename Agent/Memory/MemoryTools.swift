import Foundation

class MemoryTools {
    static func register(into registry: ToolRegistry) {
        registry.register(RegisteredTool(
            name: "memory-store",
            description: "保存信息到长期记忆",
            parameters: #"{"type":"object","properties":{"content":{"type":"string","description":"要保存的内容"},"summary":{"type":"string","description":"简短摘要（可选）"},"category":{"type":"string","enum":["conversation","task","fact","preference","document","note"],"description":"记忆分类"},"tags":{"type":"array","items":{"type":"string"},"description":"标签列表"},"importance":{"type":"number","minimum":0,"maximum":1,"description":"重要性，0-1之间"}},"required":["content"]}"#,
            requiredParameters: ["content"],
            isParameterless: false,
            execute: { args in
                let content = args["content"] as? String ?? ""
                let summary = args["summary"] as? String
                let categoryStr = args["category"] as? String ?? "fact"
                let tags = args["tags"] as? [String] ?? []
                let importance = args["importance"] as? Double ?? 0.5
                
                let category = MemoryItem.MemoryCategory(rawValue: categoryStr) ?? .fact
                LongTermMemoryStore.shared.store(
                    content: content,
                    summary: summary,
                    category: category,
                    tags: tags,
                    source: .toolResult,
                    importance: importance
                )
                
                return "{\"success\":true,\"message\":\"记忆已保存\"}"
            },
            executeCanonical: { args in
                let content = args["content"] as? String ?? ""
                let result = """
                    {
                        "success": true,
                        "summary": "已保存信息到记忆",
                        "detail": "已保存内容：\(content.prefix(100))"
                    }
                """
                return CanonicalToolResult(success: true, summary: "已保存信息到记忆", detail: result)
            }
        ))
        
        registry.register(RegisteredTool(
            name: "memory-search",
            description: "从长期记忆中搜索相关信息",
            parameters: #"{"type":"object","properties":{"query":{"type":"string","description":"搜索关键词"},"limit":{"type":"integer","minimum":1,"maximum":50,"description":"返回结果数量"}},"required":["query"]}"#,
            requiredParameters: ["query"],
            isParameterless: false,
            execute: { args in
                let query = args["query"] as? String ?? ""
                let limit = args["limit"] as? Int ?? 10
                
                let results = LongTermMemoryStore.shared.search(query: query, limit: limit)
                let items = results.map { result in
                    [
                        "id": result.item.id.uuidString,
                        "content": result.item.content,
                        "summary": result.item.summary ?? "",
                        "category": result.item.category.rawValue,
                        "tags": result.item.tags,
                        "relevance": result.relevanceScore
                    ]
                }
                
                if let jsonData = try? JSONSerialization.data(withJSONObject: ["items": items], options: []),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    return jsonString
                }
                
                return "{\"items\":[]}"
            },
            executeCanonical: { args in
                let query = args["query"] as? String ?? ""
                let results = LongTermMemoryStore.shared.search(query: query, limit: 5)
                
                let summary = results.isEmpty 
                    ? "没有找到相关记忆" 
                    : "找到 \(results.count) 条相关记忆"
                
                let detail = results.map { result in
                    "- \(result.item.summary ?? result.item.content.prefix(100))"
                }.joined(separator: "\n")
                
                return CanonicalToolResult(
                    success: true,
                    summary: summary,
                    detail: detail
                )
            }
        ))
        
        registry.register(RegisteredTool(
            name: "memory-get-profile",
            description: "获取用户基本信息和偏好设置",
            parameters: "{}",
            requiredParameters: [],
            isParameterless: true,
            skipFollowUp: false,
            execute: { _ in
                let profile = UserProfileManager.shared.loadProfile()
                let dict: [String: Any] = [
                    "name": profile.name,
                    "email": profile.email,
                    "preferences": profile.preferences.map { ["key": $0.key, "value": $0.value] },
                    "contacts": profile.contacts.map { ["name": $0.name, "email": $0.email ?? "", "role": $0.role ?? ""] }
                ]
                if let data = try? JSONSerialization.data(withJSONObject: dict, options: []),
                   let json = String(data: data, encoding: .utf8) {
                    return json
                }
                return "{}"
            },
            executeCanonical: { _ in
                let profile = UserProfileManager.shared.loadProfile()
                return CanonicalToolResult(
                    success: true,
                    summary: "用户：\(profile.name)",
                    detail: "用户信息已获取"
                )
            }
        ))
        
        registry.register(RegisteredTool(
            name: "memory-set-preference",
            description: "设置用户偏好",
            parameters: #"{"type":"object","properties":{"key":{"type":"string","description":"偏好键名"},"value":{"type":"string","description":"偏好值"}},"required":["key","value"]}"#,
            requiredParameters: ["key", "value"],
            isParameterless: false,
            skipFollowUp: true,
            execute: { args in
                let key = args["key"] as? String ?? ""
                let value = args["value"] as? String ?? ""
                
                guard !key.isEmpty else {
                    return "{\"success\":false,\"error\":\"缺少 key 参数\"}"
                }
                
                UserProfileManager.shared.updateProfile { $0.setPreference(key: key, value: value) }
                return "{\"success\":true,\"message\":\"偏好已设置\"}"
            },
            executeCanonical: { args in
                let key = args["key"] as? String ?? ""
                let value = args["value"] as? String ?? ""
                return CanonicalToolResult(
                    success: true,
                    summary: "已设置偏好：\(key)=\(value)",
                    detail: "用户偏好已保存"
                )
            }
        ))
    }
}
