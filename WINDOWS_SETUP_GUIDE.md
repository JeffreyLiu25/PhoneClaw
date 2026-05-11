# Windows 用户安装和测试指南

## 💡 两种方案

### 方案一：使用 GitHub Actions 在线构建（推荐，可测试新功能）

这个方案可以让你在 Windows 上也能测试我们添加的新功能（记忆系统、GitHub 集成、文档生成）。

#### 步骤：

1. **先将代码推送到你的 GitHub 仓库**

   ```bash
   git add .
   git commit -m "Add memory system, GitHub integration, document generation"
   git push
   ```

2. **在 GitHub 上触发构建**
   - 打开你的 GitHub 仓库
   - 点击 **Actions** 标签
   - 点击左侧 **Build PhoneClaw IPA** 工作流
   - 点击 **Run workflow** 按钮
   - 选择 `trae/solo-agent-ZhlEuX` 分支，点击 **Run workflow**

3. **等待构建完成**（约 10-15 分钟）
   - 构建成功后，在工作流页面底部会有 **Artifacts**
   - 下载 `PhoneClaw-IPA.zip`

4. **用 Sideloadly 安装到 iPhone**
   - 下载并安装 [Sideloadly](https://sideloadly.io/)
   - 打开 Sideloadly
   - 将下载的 `PhoneClaw.ipa` 拖入 Sideloadly
   - 输入你的 Apple ID 和密码（或使用专用密码）
   - 点击 **Start**
   - 在 iPhone 上信任证书：设置 → 通用 → VPN 与设备管理 → 信任

5. **开始使用！**

---

### 方案二：使用官方发布的 IPA（简单，但无法测试新功能）

如果你只是想体验原版 PhoneClaw：

1. 访问 [GitHub Releases](https://github.com/kellyvv/PhoneClaw/releases)
2. 下载最新的未签名 IPA
3. 用 Sideloadly 签名安装（同上）

---

## ⚠️ 重要提示

### 关于签名限制

- Sideloadly 签名的 App **7 天后会过期**，需要重新签名
- 免费 Apple ID 同时只能签名 3 个 App
- 建议使用 Apple ID 专用密码（安全）

### 关于模型和内存

- **E4B 模型只能用 CPU 推理**（受签名软件内存限制）
- **推荐使用 E2B 模型**，功能完整且更稳定

---

## 📱 测试新功能

安装成功后，可以测试以下新功能：

### 1. 记忆系统
```
记住我的名字是张三
记住我的邮箱是 test@example.com
搜索关于我的信息
```

### 2. 文档生成
```
生成一份会议纪要，标题是项目周会
生成一份项目提案
```

### 3. GitHub 集成（需先启用网络）
```
启用网络功能
设置我的 GitHub Token 是 ghp_xxx
在 myorg/myrepo 创建 Issue，标题是测试
```

---

## 🔧 故障排除

### Sideloadly 常见问题

**问题：证书不受信任**
> 解决：在 iPhone 设置 → 通用 → VPN 与设备管理 → 信任你的 Apple ID

**问题：安装失败，提示内存限制**
> 解决：正常现象，E4B 模型在签名版上只能用 CPU，推荐用 E2B

**问题：7 天后 App 不能用了**
> 解决：用 Sideloadly 重新签名安装一次

### GitHub Actions 常见问题

**问题：构建失败**
> 解决：查看 Actions 日志，确认我们新增的文件是否正确添加到 Xcode 项目（可能需要手动在 Mac 上添加一次）

---

## 📖 更多帮助

- 改造完整指南：[PHONECLAW_TO_OPENCLAW_GUIDE.md](PHONECLAW_TO_OPENCLAW_GUIDE.md)
- 改造路线图：[doc/phoneclaw-to-openclaw-roadmap.md](doc/phoneclaw-to-openclaw-roadmap.md)
- 原版项目：[kellyvv/PhoneClaw](https://github.com/kellyvv/PhoneClaw)
