---
name: Memory
name-zh: 记忆系统
description: 管理长期记忆、用户偏好和个人信息
version: "1.0.0"
icon: brain
disabled: false
type: device
requires-time-anchor: false
chip_prompt: "记住我的信息"
chip_label: "记忆管理"

triggers:
  - 记住
  - 记忆
  - 保存
  - 偏好
  - 设置
  - 我的信息
  - 搜索记忆
  - memory
  - remember
  - preference
  - profile

allowed-tools:
  - memory-store
  - memory-search
  - memory-get-profile
  - memory-set-preference

examples:
  - query: "记住我的邮箱是 hello@example.com"
    scenario: "保存用户邮箱到偏好设置"
  - query: "搜索关于项目的记忆"
    scenario: "从长期记忆中检索相关信息"
---

# 记忆系统使用说明

## 功能说明

这个 Skill 帮助管理用户的长期记忆、偏好设置和个人信息。

## 何时使用

1. **保存重要信息**：当用户说"记住..."、"保存..."时，使用 `memory-store`
2. **检索过往信息**：当用户询问之前的对话或信息时，使用 `memory-search`
3. **获取用户信息**：在需要知道用户姓名、邮箱等信息时，使用 `memory-get-profile`
4. **设置用户偏好**：当用户表达偏好或习惯时，使用 `memory-set-preference`

## 使用建议

- 优先保存用户明确要求记住的信息
- 保存时尽量添加摘要和标签，方便后续检索
- 重要性分数：0 最低，1 最高，通常使用 0.5-0.8
- 分类使用：fact（事实）、preference（偏好）、task（任务）、conversation（对话）
