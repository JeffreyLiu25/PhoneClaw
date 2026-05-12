import Foundation

struct DocumentTemplate {
    let name: String
    let generate: (String, [String: Any]) -> String
}

class DocumentTools {
    private static let templates: [String: DocumentTemplate] = [
        "project-proposal": DocumentTemplate(name: "项目提案", generate: { title, params in
            let description = params["description"] as? String ?? ""
            let goals = params["goals"] as? [String] ?? []
            let timeline = params["timeline"] as? String ?? ""
            
            return """
            # \(title)
            
            ## 项目概述
            \(description)
            
            ## 项目目标
            \(goals.map { "- \($0)" }.joined(separator: "\n"))
            
            ## 时间线
            \(timeline)
            
            ## 风险评估
            - [ ] 风险 1
            - [ ] 风险 2
            
            ## 资源需求
            - [ ] 资源 1
            - [ ] 资源 2
            """
        }),
        
        "meeting-notes": DocumentTemplate(name: "会议纪要", generate: { title, params in
            let date = params["date"] as? String ?? Date().formatted()
            let attendees = params["attendees"] as? [String] ?? []
            let agenda = params["agenda"] as? String ?? ""
            let decisions = params["decisions"] as? [String] ?? []
            let actionItems = params["actionItems"] as? [String] ?? []
            
            return """
            # \(title)
            
            **日期**: \(date)
            **参会人员**: \(attendees.joined(separator: ", "))
            
            ## 议题
            \(agenda)
            
            ## 决议
            \(decisions.map { "- \($0)" }.joined(separator: "\n"))
            
            ## 行动项
            \(actionItems.map { "- [ ] \($0)" }.joined(separator: "\n"))
            
            ## 下次会议
            """
        }),
        
        "simple-markdown": DocumentTemplate(name: "简单 Markdown", generate: { title, params in
            let content = params["content"] as? String ?? ""
            return "# \(title)\n\n\(content)"
        })
    ]
    
    private static func documentsDirectory() throws -> URL {
        let fm = FileManager.default
        let documentsDir = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let phoneClawDocs = documentsDir.appendingPathComponent("PhoneClaw", isDirectory: true)
        try fm.createDirectory(at: phoneClawDocs, withIntermediateDirectories: true)
        return phoneClawDocs
    }
    
    static func register(into registry: ToolRegistry) {
        registry.register(RegisteredTool(
            name: "doc-generate-markdown",
            description: "生成 Markdown 文档",
            parameters: #"{"type":"object","properties":{"title":{"type":"string","description":"文档标题"},"template":{"type":"string","enum":["project-proposal","meeting-notes","simple-markdown"],"description":"文档模板"},"params":{"type":"object","description":"模板参数"}},"required":["title","template"]}"#,
            requiredParameters: ["title", "template"],
            isParameterless: false,
            execute: { args -> String in
                let title = args["title"] as? String ?? "未命名文档"
                let templateName = args["template"] as? String ?? "simple-markdown"
                let params = args["params"] as? [String: Any] ?? [:]
                
                guard let template = templates[templateName] else {
                    return "{\"success\":false,\"error\":\"未知模板\"}"
                }
                
                let content = template.generate(title, params)
                
                let fileName = "\(title.replacingOccurrences(of: " ", with: "_")).md"
                let fileURL = try! documentsDirectory().appendingPathComponent(fileName)
                try! content.write(to: fileURL, atomically: true, encoding: .utf8)
                
                let result: [String: Any] = [
                    "success": true,
                    "fileName": fileName,
                    "path": fileURL.path,
                    "content": content
                ]
                
                if let jsonData = try? JSONSerialization.data(withJSONObject: result, options: []),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    return jsonString
                }
                
                return "{\"success\":true}"
            },
            executeCanonical: { args in
                let title = args["title"] as? String ?? "文档"
                return CanonicalToolResult(
                    success: true,
                    summary: "已生成文档：\(title)",
                    detail: "文档已保存到文件"
                )
            }
        ))
        
        registry.register(RegisteredTool(
            name: "doc-save-content",
            description: "保存文本内容到文件",
            parameters: #"{"type":"object","properties":{"fileName":{"type":"string","description":"文件名"},"content":{"type":"string","description":"文件内容"},"extension":{"type":"string","description":"文件扩展名，默认 md"}},"required":["fileName","content"]}"#,
            requiredParameters: ["fileName", "content"],
            isParameterless: false,
            skipFollowUp: true,
            execute: { args -> String in
                let fileName = args["fileName"] as? String ?? "document"
                let content = args["content"] as? String ?? ""
                let ext = args["extension"] as? String ?? "md"
                
                let fullFileName = "\(fileName).\(ext)"
                let fileURL = try! documentsDirectory().appendingPathComponent(fullFileName)
                try! content.write(to: fileURL, atomically: true, encoding: .utf8)
                
                return "{\"success\":true,\"fileName\":\"\(fullFileName)\",\"path\":\"\(fileURL.path)\"}"
            },
            executeCanonical: { args in
                let fileName = args["fileName"] as? String ?? "文档"
                return CanonicalToolResult(
                    success: true,
                    summary: "已保存：\(fileName)",
                    detail: "文件已保存"
                )
            }
        ))
        
        registry.register(RegisteredTool(
            name: "doc-list-files",
            description: "列出已保存的文档",
            parameters: "{}",
            requiredParameters: [],
            isParameterless: true,
            execute: { _ in
                let docsDir = try! documentsDirectory()
                let fm = FileManager.default
                let files = (try? fm.contentsOfDirectory(atPath: docsDir.path)) ?? []
                
                let result: [String: Any] = [
                    "success": true,
                    "files": files,
                    "path": docsDir.path
                ]
                
                if let jsonData = try? JSONSerialization.data(withJSONObject: result, options: []),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    return jsonString
                }
                
                return "{\"success\":true,\"files\":[]}"
            },
            executeCanonical: { _ in
                CanonicalToolResult(
                    success: true,
                    summary: "已获取文档列表",
                    detail: "文件查询完成"
                )
            }
        ))
    }
}
