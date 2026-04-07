# My Claude Code Skills

个人 Claude Code 自定义 Skill 仓库，收录日常开发中沉淀的专项 Agent 能力。

## Skills 列表

| Skill | 描述 |
| --- | --- |
| [vidnoz-new-template-builder](skills/vidnoz-new-template-builder/SKILL.md) | Vidnoz `templates/new-template` 前端页面实现、修改与优化（tpl / Dev/js / Dev/scss / lan） |
| [vidnoz-upload-api-migration](skills/vidnoz-upload-api-migration/SKILL.md) | Vidnoz 上传链路接口迁移，将旧 `ai/source/*` 调用规范化为 `apiGetUploadUrl` / `apiUploadFileWithSign` |
| [tools-templates-builder](skills/tools-templates-builder/SKILL.md) | `tools-templates` 多品牌前端仓库（vidqu / vidnoz / ismartta / vidmud）的页面开发与统一构建 |

## 目录结构

```
my-skills/
├── <skill-name>/
│   ├── SKILL.md              # Skill 主描述文件（触发条件、工作流程、规则）
│   ├── agents/
│   │   └── openai.yaml       # Agent 配置（模型、工具等）
│   ├── references/           # 参考资料（项目结构、接口文档、编辑规则等）
│   └── scripts/              # 辅助脚本（文件定位、批量搜索等）
└── README.md
```

## 使用方式

在 Claude Code `settings.json` 的 `skillsDirectories` 中添加本仓库路径：

```json
{
  "skillsDirectories": [
    "/path/to/my-skills"
  ]
}
```

配置后，对应项目中直接使用 `/skill-name` 即可触发。

## 新增 Skill

1. 在仓库根目录新建 `<skill-name>/` 目录。
2. 创建 `SKILL.md`，写明触发场景、工作流程和核心规则。
3. 按需补充 `references/` 文档和 `scripts/` 辅助脚本。
4. 更新本 README 的 Skills 列表。