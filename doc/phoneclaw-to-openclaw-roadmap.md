# PhoneClaw → iPhone OpenClaw 改造路线图

## 📋 现状分析

### 当前 PhoneClaw 架构

```
User Input → Router → Planner/Agent → Tools → Response
           ↓
    Session History
```

- ✅ 优秀：完全离线、隐私保护
- ✅ 优秀：Skill 系统设计（基于 Markdown）
- ✅ 优秀：内存管理优化
- ❌ 缺失：用户画像/长期记忆
- ❌ 缺失：网络访问能力（API/GitHub）
- ❌ 缺失：文档/PPT 生成
- ❌ 缺失：真正的 RAG 知识库

---

## 🎯 改造目标：iPhone 上的 OpenClaw

### 功能对比表

| 功能 | OpenClaw (服务器) | 改造后的 PhoneClaw |
|-----|-------------------|-------------------|
| 长期记忆 | ✅ 完整 UserProfile + RAG | ✅ 实现 |
| Skill 调用 | ✅ 完整生态 | ✅ 扩展支持网络 |
| 文档生成 | ✅ Markdown/PPT/PDF | ✅ 实现 |
| GitHub 操作 | ✅ Issues/PR/Code | ✅ 实现 |
| 会议预定 | ✅ Google/Outlook/Zoom | ✅ 增强 iOS 日历+集成 |
| 日程管理 | ✅ 完整 | ✅ 已有基础 + 增强 |
| 网络访问 | ✅ 完全 | ⚠️ 可控网络（可开关） |
| 完全离线 | ❌ 依赖网络 | ✅ 可切换 |

---

## 📐 架构改造设计

### 新架构图

```
┌─────────────────────────────────────────────────────────────┐
│                        User Interface                        │
└────────────────────────────┬────────────────────────────────┘
                             │
         ┌───────────────────┴───────────────────┐
         │             AgentEngine              │
         │  (现有 + 新增 Profile/Memory 层)    │
         └───────────────────┬───────────────────┘
                             │
    ┌────────────────────────┼────────────────────────┐
    │                        │                        │
┌───▼──────┐         ┌──────▼───────┐        ┌──────▼──────┐
│ Memory   │         │  SkillRouter │        │   Planner   │
│ System   │         │   (扩展)     │        │  (增强)     │
└───┬──────┘         └──────┬───────┘        └──────┬──────┘
    │                       │                       │
    ▼                       ▼                       ▼
┌─────────┐   ┌───────────────────────────┐  ┌─────────┐
│ Profile │   │     Skill Registry        │  │  Tools  │
│ Memory  │   │  (支持网络/文档Skill)    │  │ Registry│
└─────────┘   └───────────────────────────┘  └────┬────┘
                                                  │
         ┌────────────────────────────────────────┼─────────────────┐
         │                                        │                 │
    ┌────▼────┐    ┌─────────┐    ┌─────────┐   ┌──▼─────────┐    │
    │  iOS    │    │ Network │    │  Docs   │   │   GitHub   │    │
    │ Native  │    │  Tools  │    │ Builder │   │   Tools    │    │
    └─────────┘    └─────────┘    └─────────┘   └────────────┘    │
         │                │                 │              │         │
         └────────────────┴─────────────────┴──────────────┴─────────┘
```

---

## 🛠️ 核心改造模块

### 1. 记忆系统增强 (新增)

**位置**：`Agent/Memory/`

```
Agent/Memory/
├── UserProfile.swift       # 用户画像
├── LongTermMemory.swift    # 长期记忆存储
├── MemoryRetrieval.swift   # RAG 检索
└── MemoryEmbedding.swift   # 向量嵌入 (可选)
```

**功能**：
- 用户基本信息（姓名、邮箱、常用会议室）
- 历史交互摘要
- 偏好设置
- RAG 知识库（本地文件索引）

---

### 2. 网络层 (新增)

**位置**：`Tools/Network/`

```
Tools/Network/
├── NetworkClient.swift      # HTTP 客户端
├── NetworkTools.swift       # 工具注册
├── GitHubTools.swift        # GitHub API 封装
└── GoogleCalendarTools.swift # Google 日历集成
```

**安全设计**：
- 默认完全关闭（保持隐私优先）
- 可手动开启网络访问
- API Token 加密存储在 Keychain

---

### 3. 文档生成 (新增)

**位置**：`Tools/Documentation/`

```
Tools/Documentation/
├── MarkdownBuilder.swift    # Markdown 生成
├── PPTXBuilder.swift        # PPTX 生成 (使用开源库)
└── DocumentTools.swift      # 工具注册
```

---

### 4. Skill 系统扩展 (修改)

**位置**：`Skills/Library/`

新增 Skills：
- `github/` - GitHub 操作
- `document-generator/` - 文档/PPT 生成
- `meeting-scheduler/` - 增强会议预定
- `knowledge-base/` - 知识库管理

---

## 📝 详细实现计划

### Phase 1: 记忆系统 (2-3 天)
1. UserProfile 模型
2. LongTermMemory 存储
3. MemoryRetrieval 检索
4. 集成到 AgentEngine

### Phase 2: 网络能力 (3-4 天)
1. NetworkClient 基础框架
2. Keychain 安全存储
3. GitHub API 工具
4. 可开关网络设置

### Phase 3: 文档生成 (2-3 天)
1. Markdown 生成工具
2. PPTX 生成（使用第三方库）
3. Skill 集成

### Phase 4: 增强会议/日程 (2 天)
1. 扩展日历工具（支持查找可用时间）
2. Zoom/Teams 链接生成
3. 会议纪要模板

### Phase 5: 优化 & 测试 (2 天)

---

## 🔑 关键技术决策

### 1. 隐私开关设计

保留完全离线优先：
- 默认：网络禁用
- 用户可手动开启
- 每次网络调用前确认（可选）
- 网络权限状态可视化

### 2. 文档生成选择

- PPTX：使用开源 Swift 库 (如 [SwiftOffice](https://github.com/...) 或自己写)
- PDF：使用 iOS 原生 PDFKit
- Markdown：直接生成

### 3. 记忆存储

- UserProfile：Core Data + iCloud 同步（可选）
- 对话历史：现有 SessionStore
- RAG 索引：向量数据库（可选本地轻量级）

---

## 📚 新增 Skill 示例

### GitHub Skill

```yaml
---
name: GitHub
name-zh: GitHub
description: 管理 GitHub Issues, PRs, 推送代码
type: device
requires-network: true
triggers:
  - github
  - issue
  - pull request
  - 推送代码
  - 提交代码
allowed-tools:
  - github-create-issue
  - github-list-issues
  - github-create-pr
  - github-push-code
---
```

### Document Generator Skill

```yaml
---
name: Document Generator
name-zh: 文档生成
description: 生成 Markdown 文档、PPT 演示文稿
type: content
triggers:
  - 生成文档
  - 写 PPT
  - 制作演示文稿
  - create document
  - make ppt
allowed-tools:
  - doc-generate-markdown
  - doc-generate-pptx
  - doc-save-to-files
---
```

---

## ⚠️ 重要注意事项

1. **隐私原则不变**：默认完全离线，网络功能需要手动开启
2. **向后兼容**：现有功能不受影响
3. **用户控制**：所有新增功能都可独立开关
4. **性能优先**：保持 iPhone 上的流畅体验

---

## 🎉 最终效果

改造后的 PhoneClaw 将能够：

```
用户："帮我生成一个项目提案的 PPT，然后创建一个 GitHub Issue 跟踪它"

→ PPT 生成 Skill 制作演示文稿
→ GitHub Skill 创建 Issue
→ 保存到文件 + 发送通知
```

```
用户："明天下午 3 点帮我约个会，叫上产品和技术负责人"

→ 查找可用会议室
→ 查询相关人员日程
→ 创建日历事件 + 生成会议议程
→ 发送邀请
```
