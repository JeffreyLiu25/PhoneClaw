---
name: GitHub
name-zh: GitHub
description: 管理 GitHub Issues、PRs、仓库等
version: "1.0.0"
icon: github
disabled: false
type: device
requires-network: true
requires-time-anchor: false
chip_prompt: "创建 GitHub Issue"
chip_label: "GitHub"

triggers:
  - github
  - issue
  - issues
  - pr
  - pull request
  - 仓库
  - repo
  - 提交
  - commit

allowed-tools:
  - github-set-token
  - github-create-issue
  - github-list-issues
  - network-enable
  - network-disable

examples:
  - query: "设置我的 GitHub Token 是 ghp_xxx"
    scenario: "配置 GitHub API 访问凭证"
  - query: "在 myorg/myrepo 创建一个 Issue，标题是 Bug 修复"
    scenario: "创建 GitHub Issue"
  - query: "列出 myorg/myrepo 的 Issues"
    scenario: "查看仓库的 Issues 列表"
---

# GitHub 使用说明

## 功能说明

这个 Skill 提供 GitHub 相关操作，包括创建和查看 Issues。

## 使用前准备

1. **启用网络**：先使用 `network-enable` 开启网络功能（默认关闭）
2. **设置 Token**：设置 GitHub Personal Access Token，使用 `github-set-token`

## 可用工具

- `github-set-token`: 保存 GitHub API Token
- `github-create-issue`: 在指定仓库创建 Issue
- `github-list-issues`: 列出仓库的 Issues
- `network-enable/disable`: 控制网络开关

## 隐私提示

- Token 安全存储在设备 Keychain 中
- 网络功能默认关闭，需要时手动开启
- 所有网络请求都需要用户明确授权
