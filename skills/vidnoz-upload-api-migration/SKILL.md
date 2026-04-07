---
name: vidnoz-upload-api-migration
description: 用于本仓库 templates/new-template 上传链路的接口迁移与规范化。当任务要求把 Dev/js 或实际运行时 js 中旧的 ai/source/get-upload-url、ai/source/temp-upload-url、ai/source/upload、$LIB().uploadAssets、$LIB().getUploadUrl、$LIB().tempUploadUrl 调用迁移到 common.js 的 apiGetUploadUrl 或 apiUploadFileWithSign，并同步在对应 tpl 补充 Cloudflare Turnstile 脚本时使用。也用于按英文已改页面基线，把同一 JS 覆盖的多语言 tpl 一并定位和迁移，特别适合处理“JS 名相同但 tpl 名不同”“一个 JS 对应多个 tpl”或入口脚本不在平级 Dev/js 的页面。
---

# Vidnoz Upload API Migration

## 概览

将 `templates/new-template/Dev/js/common.js` 视为上传能力的唯一公共实现来源。

处理 `templates/new-template` 里的上传需求时，优先迁移到现成的：

- `apiGetUploadUrl`
- `apiUploadFileWithSign`

不要在页面脚本里重新实现 Turnstile token、`X-Sign`、上传地址申请或 `/ai/source/upload` 包装逻辑。

## 工作流程

1. 先确认目标页面实际引入的 runtime js，再回溯对应的 `Dev/js` 源文件或真实入口文件，并补齐同一 JS 覆盖到的 `tpl` 范围。
2. 默认优先修改 `templates/new-template/Dev/js` 源文件；如果真实入口在 `templates/new-template/js/<subdir>/...` 且不存在平级 `Dev/js` 源文件，就改实际入口文件。
3. 搜索并替换旧上传调用：
   - `ai/source/get-upload-url`
   - `ai/source/temp-upload-url`
   - `ai/source/upload`
   - `$LIB().uploadAssets(...)`
   - `$LIB().getUploadUrl(...)`
   - `$LIB().tempUploadUrl(...)`
4. 在对应入口 `tpl` 或共享模板中补充 Turnstile 脚本，且只补一次。
5. 如果任务是多语言迁移，不要只改英文页。相同 JS 覆盖到的其他语言 `tpl` 也要一起检查 Turnstile 和入口引用。
6. 验证目标文件不再残留旧上传接口，且 `permanent_file`、`tools`、后续上传逻辑没有偏移。

## 固定映射

- 将 `ai/source/get-upload-url` 改为 `apiGetUploadUrl`，并显式传 `permanent_file: true`。
- 将 `ai/source/temp-upload-url` 改为 `apiGetUploadUrl`，并显式传 `permanent_file: false`。
- 将 `ai/source/upload` 改为 `apiUploadFileWithSign`。
- 将页面 JS 中的 `$LIB().uploadAssets(...)` 调用，直接改为页面内显式调用 `apiGetUploadUrl(...)`，并保留后续手动上传逻辑。
- 将页面 JS 中的 `$LIB().getUploadUrl(...)` 调用，直接改为 `apiGetUploadUrl(...)`，并显式传 `permanent_file: true`。
- 将页面 JS 中的 `$LIB().tempUploadUrl(...)` 调用，直接改为 `apiGetUploadUrl(...)`，并显式传 `permanent_file: false`。

不要依赖 `apiGetUploadUrl` 或 `apiUploadFileWithSign` 的默认 `permanent_file` 值来表达迁移语义；迁移时始终显式传值。

## 关键定位规则

- 不要默认假设 `foo.js -> foo.tpl` 一一对应。
- 先按 `tpl` 里实际引入的 runtime js 反查，再决定改哪个源文件。
- 多语言迁移时，JS 名通常保持一致，但 `tpl` 名未必一致，甚至一个 runtime js 会被多个 `tpl` 复用。
- 当前仓库里已确认存在这些非一对一映射：
  - `ai-anime-kissing.js -> anime-kissing.tpl`
  - `gen-face-swap-auth.js -> face-swap.tpl`
  - `music-video.js -> ai-music-video-generator.tpl`
  - `vidnoz-gen-photo-dance.js -> magic-animate.tpl`
  - `vidnoz-gen-clothesChanger.js` 与 `vidnoz-gen-outfit.js -> ai-clothes-changer.tpl`
- `ai-headshot-generator.tpl` 是特殊页：当前入口上传逻辑在 `templates/new-template/js/ai-headshot-generator/index.js`，不是平级 `Dev/js/<page>.js`。

## 参数与语义规则

- 旧逻辑如果走的是 `toolsHost`、`TOOL_API`、`tool_api` 等工具域名语义，迁移到公共方法时 `tools` 也传 `true`。
- 旧逻辑如果走的是站内默认接口语义，同样保持 `tools: false` 或省略该参数。
- 不要把 `getHeaders()`、通用 `Authorization`、`Request-Language`、`Content-Type` 这类公共请求头直接透传给 `apiGetUploadUrl` / `apiUploadFileWithSign`。
- 原因是公共上传方法内部已经补齐鉴权、语言、Turnstile、`X-Sign` 等通用头；重复透传容易把页面侧的通用头覆盖进来，尤其 `Content-Type: application/json` 会和 `apiGetUploadUrl` 当前的普通对象表单提交方式冲突。
- 如确实需要额外请求头，只传页面级自定义头，例如 `X-From-Page`，不要把整包通用 headers 对象透传进去。
- 保留原有的 `file_name`、`file_type`、`key`、`signal`、成功回调、失败回调和取消逻辑。
- 如果旧逻辑只是“申请上传地址，然后继续手动把二进制传到 `upload_url`”，只替换“申请上传地址”这一步为 `apiGetUploadUrl`，不要顺手重写后续上传流程。
- 如果旧逻辑直接请求 `/ai/source/upload` 完成文件上传，改为 `apiUploadFileWithSign`，并沿用它返回的数据结构。
- 如果页面通过 `$LIB()` 调 `uploadAssets`，按 `templates/new-template/js/lib-vd.min.js` 当前签名理解旧调用：入参是 `{ fileName, file, permanent }`。
- `uploadAssets` 的旧实现只是一个代理：根据 `permanent` 选择 `getUploadUrl` 或 `tempUploadUrl`，拿到 `upload_url` 后再手动 `PUT`。
- 迁移这类页面时，不要继续依赖 `uploadAssets`；直接在页面 JS 中调用 `apiGetUploadUrl({ file_name, file_type, permanent_file })`，然后复用页面原本的 `PUT upload_url`、成功判断和 `key` 使用方式。
- 除非用户明确要求，否则不要为了这类页面去改 `templates/new-template/js/lib-vd.min.js`。

## tpl 规则

在与改动 JS 对应的入口 `tpl` 文件中补充：

```html
<script src="https://challenges.cloudflare.com/turnstile/v0/api.js" async defer></script>
```

处理时遵守以下规则：

- 如果页面或共享 include 已经引入该脚本，不要重复添加。
- 优先加在页面底部脚本区，与当前页面其他外部脚本保持一致。
- 如果同一个 JS 被多个入口模板复用，补到真正承载上传能力的入口模板或共享模板，不要只改一个无效入口。

## 验证

- 确认目标 JS 不再直接请求旧的 `ai/source/get-upload-url`、`ai/source/temp-upload-url`、`ai/source/upload`。
- 确认页面里原本的 `uploadAssets(...)` 调用已经替换为 `apiGetUploadUrl(...)` 驱动的流程。
- 确认页面里原本的 `$LIB().getUploadUrl(...)`、`$LIB().tempUploadUrl(...)` 调用已经替换为 `apiGetUploadUrl(...)`。
- 确认 `apiGetUploadUrl` 调用都显式带上正确的 `permanent_file`。
- 确认工具域名语义的迁移调用显式传了 `tools: true`，站内默认接口语义没有误传 `tools: true`。
- 确认没有给 `apiGetUploadUrl` / `apiUploadFileWithSign` 误传 `getHeaders()`、通用鉴权语言头或 `Content-Type: application/json` 一类 headers。
- 确认对应 `tpl` 已存在 Turnstile 脚本，且没有重复引入。
- 确认没有在页面脚本里新增重复的 token、签名、上传封装。

## 参考资料

- 读取 `references/upload-migration-rules.md` 查看迁移速查和检索命令。
- 读取 `references/en-upload-migrated-pages.md` 查看当前英文已改页面基线、已知 JS/TPL 非一对一映射和特殊入口页。
- 如需 broader 的 `new-template` 文件定位规则，再读取 `tools/skills/vidnoz-new-template-builder/SKILL.md`。
