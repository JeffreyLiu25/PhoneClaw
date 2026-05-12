---
name: Document Generator
name-zh: 文档生成器
description: 生成 Markdown 文档、会议纪要、项目提案等
version: "1.0.0"
icon: file-text
disabled: false
type: content
requires-time-anchor: false
chip_prompt: "生成一份会议纪要"
chip_label: "文档生成"

triggers:
  - 生成文档
  - 写文档
  - 文档
  - 会议纪要
  - 会议记录
  - 项目提案
  - create document
  - write document
  - meeting notes
  - generate

allowed-tools:
  - doc-generate-markdown
  - doc-save-content
  - doc-list-files

examples:
  - query: "生成一份关于新功能的会议纪要"
    scenario: "使用会议纪要模板生成文档"
  - query: "写一份项目提案，标题是 AI 助手开发计划"
    scenario: "使用项目提案模板生成文档"
  - query: "保存这段内容到 my_notes.md"
    scenario: "直接保存文本内容到文件"
  - query: "列出我保存的文档"
    scenario: "查看已保存的所有文档"
---

# 文档生成器使用说明

## 功能说明

这个 Skill 帮助生成各种类型的文档，包括会议纪要、项目提案等，并保存到设备。

## 可用模板

1. **project-proposal**：项目提案模板
   - 参数：title, description, goals, timeline
2. **meeting-notes**：会议纪要模板
   - 参数：title, date, attendees, agenda, decisions, actionItems
3. **simple-markdown**：简单 Markdown
   - 参数：title, content

## 使用建议

- 对于简单内容，使用 simple-markdown 模板直接生成
- 对于会议，尽量收集参会者、决议和行动项
- 项目提案建议包含目标和时间线
- 所有文档都保存在手机的"文件"应用中，PhoneClaw 文件夹下
