# 混沌 Skill 测试包（hd_skill）

用于验证混沌 Skill 平台接口的演示 Skill。

## 环境要求

- **Windows**：PowerShell（系统自带），直接执行 .ps1 脚本，无需 Git Bash
- **Linux / Mac / Git Bash**：Bash、curl
- **jq 或 python**（可选）：.sh 脚本中 intent_collect 需要；.ps1 无此依赖

**双脚本**：每个能力均有 .sh 和 .ps1 两套，Windows 优先用 .ps1 原生执行。

## 快速开始

### 1. 获取 API Key

访问 https://tools.hundun.cn/h5Bin/aia/#/keys 登录并新建密钥。

### 2. 配置（自动创建）

首次运行需鉴权的脚本（如 `search_courses.sh`）时，若 `~/.hdxy_config` 不存在会**自动创建**，已预填 base_url 等默认值。用户只需：

- 打开 `~/.hdxy_config`（Git Bash 下为 `/c/Users/你的用户名/.hdxy_config`）
- 将 `api_key=` 后填入真实密钥

### 3. 接口域名

默认使用线上环境 `https://hddrapi.hundun.cn`，已内置，无需额外配置。

### 4. 运行脚本

**Windows**：用 PowerShell 执行 `run.ps1`（优先执行 .ps1 原生脚本，无需 Git Bash）：
```powershell
cd skill_demo\hd_skill
powershell -ExecutionPolicy Bypass -File run.ps1 search_courses "关键词"
```

**Git Bash / Linux / Mac**：
```bash
# 版本检查（无需鉴权）
./scripts/version_check.sh

# 关键字搜课
./scripts/search_courses.sh "关键词"

# 课程体系树
./scripts/get_trees.sh

# 按体系查课程
./scripts/get_courses_by_tree.sh "体系ID"

# 获取文稿版本
./scripts/get_script_version.sh "课程ID"

# 获取文稿
./scripts/get_script.sh "课程ID"

# 用户意图收集
./scripts/intent_collect.sh "用户意图描述" "场景描述" "skill_search_keyword"
```

## 接口说明

| 接口 | 脚本 | 鉴权 |
|------|------|------|
| 版本检查 | version_check.sh | 否 |
| 关键字搜课 | search_courses.sh | API Key |
| 课程体系树 | get_trees.sh | API Key |
| 按体系查课程 | get_courses_by_tree.sh | API Key |
| 文稿版本 | get_script_version.sh | API Key |
| 获取文稿 | get_script.sh | API Key |
| 意图收集 | intent_collect.sh | API Key |

**暂不支持**：Skill 补全接口（`/aia/api/v1/skill/patch`）
