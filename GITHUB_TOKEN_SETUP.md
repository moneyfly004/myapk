# GitHub Token 设置指南

## 方法 1: 使用默认的 GITHUB_TOKEN（推荐）

GitHub Actions 会自动提供 `GITHUB_TOKEN`，无需额外设置。工作流已经配置了 `permissions: contents: write`，应该可以正常工作。

## 方法 2: 使用自定义 Personal Access Token (PAT)

如果需要更多权限或遇到权限问题，可以创建自定义 token：

### 步骤 1: 创建 Personal Access Token

1. 访问 GitHub: https://github.com/settings/tokens
2. 点击 "Generate new token" > "Generate new token (classic)"
3. 设置 Token 名称（例如：`NekoBox Release Token`）
4. 选择过期时间
5. 勾选以下权限：
   - ✅ `repo` (完整仓库访问权限)
     - ✅ `repo:status`
     - ✅ `repo_deployment`
     - ✅ `public_repo`
     - ✅ `repo:invite`
     - ✅ `security_events`
6. 点击 "Generate token"
7. **重要**: 复制生成的 token（只显示一次）

### 步骤 2: 在仓库中添加 Secret

1. 访问你的仓库: https://github.com/moneyfly004/myapk
2. 点击 "Settings" > "Secrets and variables" > "Actions"
3. 点击 "New repository secret"
4. 填写：
   - Name: `RELEASE_TOKEN` ⚠️ **重要：不能以 `GITHUB_` 开头**
   - Secret: 粘贴刚才复制的 token
5. 点击 "Add secret"

### 步骤 3: 验证

工作流会自动使用 `RELEASE_TOKEN`（如果存在），否则使用默认的 `GITHUB_TOKEN`。

**注意：** GitHub 不允许 secret 名称以 `GITHUB_` 开头，这是保留前缀。

## 注意事项

- Token 权限必须包含 `repo` 权限才能创建 Release
- 如果使用默认的 `GITHUB_TOKEN`，确保工作流有 `permissions: contents: write`
- 自定义 token 更安全，可以设置更细粒度的权限
