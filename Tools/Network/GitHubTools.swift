import Foundation

struct GitHubIssue: Codable {
    let id: Int?
    let number: Int?
    let title: String
    let body: String?
    let state: String?
    let htmlUrl: String?
    let createdAt: String?
}

struct GitHubRepo: Codable {
    let name: String
    let fullName: String?
}

class GitHubTools {
    private static let baseURL = "https://api.github.com"
    
    private static func authHeaders() -> [String: String] {
        var headers: [String: String] = [
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28"
        ]
        if let token = KeychainManager.shared.getToken(for: "github") {
            headers["Authorization"] = "Bearer \(token)"
        }
        return headers
    }
    
    static func register(into registry: ToolRegistry) {
        registry.register(RegisteredTool(
            name: "github-set-token",
            description: "设置 GitHub API Token（需要时使用",
            parameters: #"{"type":"object","properties":{"token":{"type":"string","description":"GitHub Personal Access Token"}},"required":["token"]}"#,
            requiredParameters: ["token"],
            isParameterless: false,
            skipFollowUp: true,
            execute: { args in
                let token = args["token"] as? String ?? ""
                guard !token.isEmpty else {
                    return "{\"success\":false,\"error\":\"token不能为空\"}"
                }
                
                KeychainManager.shared.save(token: token, for: "github")
                return "{\"success\":true,\"message\":\"GitHub Token 已保存\"}"
            },
            executeCanonical: { args in
                CanonicalToolResult(
                    success: true,
                    summary: "GitHub Token 已保存",
                    detail: "Token 已安全存储"
                )
            }
        ))
        
        registry.register(RegisteredTool(
            name: "github-create-issue",
            description: "在 GitHub 仓库创建 Issue",
            parameters: #"{"type":"object","properties":{"owner":{"type":"string","description":"仓库所有者"},"repo":{"type":"string","description":"仓库名称"},"title":{"type":"string","description":"Issue 标题"},"body":{"type":"string","description":"Issue 内容"}},"required":["owner","repo","title"]}"#,
            requiredParameters: ["owner", "repo", "title"],
            isParameterless: false,
            execute: { args async throws -> String in
                let owner = args["owner"] as? String ?? ""
                let repo = args["repo"] as? String ?? ""
                let title = args["title"] as? String ?? ""
                let body = args["body"] as? String ?? ""
                
                guard !owner.isEmpty && !repo.isEmpty && !title.isEmpty else {
                    return "{\"success\":false,\"error\":\"缺少必要参数\"}"
                }
                
                let url = "\(baseURL)/repos/\(owner)/\(repo)/issues"
                let requestBody: [String: Any] = [
                    "title": title,
                    "body": body
                ]
                
                do {
                    let issue: GitHubIssue = try await NetworkClient.shared.postJSON(
                        url: url,
                        body: requestBody,
                        headers: authHeaders()
                    )
                    
                    let result: [String: Any] = [
                        "success": true,
                        "number": issue.number ?? 0,
                        "title": issue.title,
                        "url": issue.htmlUrl ?? ""
                    ]
                    
                    if let jsonData = try? JSONSerialization.data(withJSONObject: result, options: []),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        return jsonString
                    }
                    
                    return "{\"success\":true}"
                } catch {
                    return "{\"success\":false,\"error\":\"\(error.localizedDescription)\"}"
                }
            },
            executeCanonical: { args async throws -> CanonicalToolResult in
                let title = args["title"] as? String ?? ""
                return CanonicalToolResult(
                    success: true,
                    summary: "已创建 Issue：\(title)",
                    detail: "Issue 创建成功"
                )
            }
        ))
        
        registry.register(RegisteredTool(
            name: "github-list-issues",
            description: "列出仓库的 Issues",
            parameters: #"{"type":"object","properties":{"owner":{"type":"string","description":"仓库所有者"},"repo":{"type":"string","description":"仓库名称"},"state":{"type":"string","enum":["open","closed","all"],"description":"状态，默认 open"},"required":["owner","repo"]}"#,
            requiredParameters: ["owner", "repo"],
            isParameterless: false,
            execute: { args async throws -> String in
                let owner = args["owner"] as? String ?? ""
                let repo = args["repo"] as? String ?? ""
                let state = args["state"] as? String ?? "open"
                
                guard !owner.isEmpty && !repo.isEmpty else {
                    return "{\"success\":false,\"error\":\"缺少必要参数\"}"
                }
                
                let url = "\(baseURL)/repos/\(owner)/\(repo)/issues?state=\(state)"
                
                do {
                    let issues: [GitHubIssue] = try await NetworkClient.shared.getJSON(
                        url: url,
                        headers: authHeaders()
                    )
                    
                    let simplified = issues.prefix(20).map { issue in
                        [
                            "number": issue.number ?? 0,
                            "title": issue.title,
                            "state": issue.state ?? "",
                            "url": issue.htmlUrl ?? ""
                        ]
                    }
                    
                    let result: [String: Any] = [
                        "success": true,
                        "issues": simplified,
                        "totalCount": issues.count
                    ]
                    
                    if let jsonData = try? JSONSerialization.data(withJSONObject: result, options: []),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        return jsonString
                    }
                    
                    return "{\"success\":true,\"issues\":[]}"
                } catch {
                    return "{\"success\":false,\"error\":\"\(error.localizedDescription)\"}"
                }
            },
            executeCanonical: { args in
                CanonicalToolResult(
                    success: true,
                    summary: "已获取 Issues 列表",
                    detail: "Issues 查询完成"
                )
            }
        ))
        
        registry.register(RegisteredTool(
            name: "network-enable",
            description: "启用网络功能（隐私提示：此操作将允许应用访问互联网",
            parameters: "{}",
            requiredParameters: [],
            isParameterless: true,
            skipFollowUp: true,
            execute: { _ in
                NetworkSettings.shared.enableNetwork()
                return "{\"success\":true,\"message\":\"网络功能已启用\"}"
            },
            executeCanonical: { _ in
                CanonicalToolResult(
                    success: true,
                    summary: "网络功能已启用",
                    detail: "现在可以使用需要网络的功能了"
                )
            }
        ))
        
        registry.register(RegisteredTool(
            name: "network-disable",
            description: "禁用网络功能",
            parameters: "{}",
            requiredParameters: [],
            isParameterless: true,
            skipFollowUp: true,
            execute: { _ in
                NetworkSettings.shared.disableNetwork()
                return "{\"success\":true,\"message\":\"网络功能已禁用\"}"
            },
            executeCanonical: { _ in
                CanonicalToolResult(
                    success: true,
                    summary: "网络功能已禁用",
                    detail: "已恢复完全离线模式"
                )
            }
        ))
    }
}
