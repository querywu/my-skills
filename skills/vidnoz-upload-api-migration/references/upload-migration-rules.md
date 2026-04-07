# 上传迁移速查

## 先脚本化，再读大文件

优先运行：

```powershell
powershell -ExecutionPolicy Bypass -File tools/skills/vidnoz-upload-api-migration/scripts/find-upload-migration-context.ps1 -ChangedOnly
```

按单页或关键词缩小范围时运行：

```powershell
powershell -ExecutionPolicy Bypass -File tools/skills/vidnoz-upload-api-migration/scripts/find-upload-migration-context.ps1 -Page video-translate
```

这个脚本已经把最容易浪费 token 的步骤自动化了：

- 从 `en-upload-migration-test-checklist.txt` 提取 EN 已改页面基线
- 反查 `tpl -> runtime js -> 实际源文件`
- 标记旧接口 / 新接口 / `uploadAssets` / `getUploadUrl` / `tempUploadUrl` 命中情况
- 检查入口 `tpl` 是否已带 Turnstile
- 输出当前改动集里没有直接 `tpl` 映射的 helper 文件

优先靠脚本拿清单和映射，再决定读哪几个页面文件。

## 公共能力入口

先在 `templates/new-template/Dev/js/common.js` 中搜索：

- `function apiGetUploadUrl`
- `async function apiUploadFileWithSign`
- `function getTurnstileToken`

这些方法已经统一处理了：

- `permanent_file`
- Turnstile token
- `X-Sign`
- `/ai/source/get-upload-url-web`
- `/ai/source/upload`

迁移页面脚本时，默认复用这些能力，不再在页面局部重复封装。
如果页面里有 `$LIB().uploadAssets(...)`、`$LIB().getUploadUrl(...)` 或 `$LIB().tempUploadUrl(...)`，先读 `templates/new-template/js/lib-vd.min.js` 理解它的旧行为，再直接改页面调用点；不要默认去改 `lib-vd.min.js`。

不要把 `getHeaders()`、通用 `Authorization`、`Request-Language`、`Content-Type` 这类公共 headers 透传给 `apiGetUploadUrl` / `apiUploadFileWithSign`。

- 这些 helper 内部已经补齐通用鉴权、语言、Turnstile、`X-Sign`
- `apiGetUploadUrl` 当前走的是普通对象数据提交，不是页面侧 `Content-Type: application/json` 的 JSON body 语义
- 如果把整包通用 headers 带进去，容易出现 header 和真实请求体结构不一致
- 如确实有页面级额外头，只保留业务自定义头，例如 `X-From-Page`

如果旧逻辑明确走的是 `toolsHost`、`TOOL_API`、`tool_api` 等工具域名语义，迁移到公共方法时要显式传：

```js
tools: true
```

只有站内默认接口语义才保持 `tools: false` 或省略该参数。

## 多语言与非一对一映射

多语言迁移时，不要默认认为 JS 和 `tpl` 同名。

当前仓库里已经确认存在这些非一对一映射：

- `ai-anime-kissing.js -> anime-kissing.tpl`
- `gen-face-swap-auth.js -> face-swap.tpl`
- `music-video.js -> ai-music-video-generator.tpl`
- `vidnoz-gen-photo-dance.js -> magic-animate.tpl`
- `vidnoz-gen-clothesChanger.js -> ai-clothes-changer.tpl`
- `vidnoz-gen-outfit.js -> ai-clothes-changer.tpl`

另外还有特殊入口页：

- `ai-headshot-generator.tpl` 当前入口上传逻辑位于 `templates/new-template/js/ai-headshot-generator/index.js`

所以迁移顺序应当是：

1. 先看 `tpl` 真实引入的 runtime js
2. 再回溯它对应的 `Dev/js` 源文件或实际 runtime 入口
3. 最后把相同 runtime js 覆盖到的其他语言 `tpl` 一起核对

完整 EN 已改页面基线见：

- `tools/skills/vidnoz-upload-api-migration/references/en-upload-migrated-pages.md`

## 旧接口到新方法的映射

### 1. 申请永久文件上传地址

旧模式：

- `POST /ai/source/get-upload-url`

新模式：

```js
apiGetUploadUrl({
  file_name,
  file_type,
  key,
  permanent_file: true,
  tools: false
})
```

### 2. 申请临时文件上传地址

旧模式：

- `POST /ai/source/temp-upload-url`

新模式：

```js
apiGetUploadUrl({
  file_name,
  file_type,
  key,
  permanent_file: false,
  tools: false
})
```

### 3. 直接上传文件

旧模式：

- `POST /ai/source/upload`

新模式：

```js
apiUploadFileWithSign({
  file,
  file_name,
  file_type,
  permanent_file,
  key,
  signal,
  tools: false
})
```

### 4. 页面里调用 `$LIB().uploadAssets()`

当前 `templates/new-template/js/lib-vd.min.js` 中的旧签名是：

```js
uploadAssets({ fileName, file, permanent = false })
```

它当前做的事是：

1. `permanent === true` 时走 `getUploadUrl`
2. `permanent === false` 时走 `tempUploadUrl`
3. 拿到 `upload_url` 后手动 `PUT`
4. 成功时返回 `{ code: 200, key }`

迁移时遵守：

- 用它来推断页面原本需要的是永久上传还是临时上传
- 直接修改页面 JS 中的 `uploadAssets(...)` 调用，不继续依赖这个代理
- 页面里改成 `apiGetUploadUrl({ file_name, file_type, permanent_file })`
- 保留页面后续手动 `PUT upload_url`、成功判断和 `key` 使用逻辑
- 除非用户明确要求，不改 `templates/new-template/js/lib-vd.min.js`

### 5. 页面里直接调用 `$LIB().getUploadUrl()` / `$LIB().tempUploadUrl()`

这两类调用也视为旧上传入口，迁移时同样直接改页面调用点，不继续依赖 `$LIB()` 代理。

- `$LIB().getUploadUrl(...)` 迁移为 `apiGetUploadUrl(...)`，并显式传 `permanent_file: true`
- `$LIB().tempUploadUrl(...)` 迁移为 `apiGetUploadUrl(...)`，并显式传 `permanent_file: false`
- 如果旧逻辑拿到返回值后还会继续手动上传到 `upload_url`，保留后续上传逻辑，只替换“申请上传地址”这一步
- 除非用户明确要求，不改 `templates/new-template/js/lib-vd.min.js`

### 6. 当前已确认的页面调用点

- `templates/new-template/Dev/js/ai-video-compressor.js`

该文件当前是：

```js
const uploadUrlRes = await this.iobit.uploadAssets({
  fileName: this.metadata.name,
  file: this.metadata.file,
})
```

迁移目标是把这一调用改成页面内直接 `apiGetUploadUrl(...)`，而不是去改 `this.iobit.uploadAssets` 的内部实现。

## 迁移守则

- 迁移时始终显式传 `permanent_file`，不要依赖默认值。
- 如果旧代码拿到上传地址后还会自己 `PUT` 或 `POST` 到 `upload_url`，保留这段上传实现，只替换“申请上传地址”的接口调用。
- 如果旧代码本来就在自己维护取消上传的 `AbortSignal`，迁移到 `apiUploadFileWithSign` 时继续透传 `signal`。
- 如果旧逻辑依赖返回中的 `access_url`、`static_url`、`key`，迁移后保持同样字段使用方式。
- 如果页面通过 `$LIB().uploadAssets()`、`$LIB().getUploadUrl()` 或 `$LIB().tempUploadUrl()` 上传，改页面调用点，不改代理本身，除非用户明确要求。
- 检查公共上传 helper 调用时，避免继续透传页面级通用 headers 对象；只保留确有业务含义的自定义头。

## tpl 脚本要求

对应页面模板需要存在：

```html
<script src="https://challenges.cloudflare.com/turnstile/v0/api.js" async defer></script>
```

已有示例可搜索：

- `templates/new-template/tpl/talking-head.tpl`
- `templates/new-template/tpl/url-to-video.tpl`

添加前先搜索是否已存在，避免重复。

## 常用检索命令

查旧上传接口：

```powershell
rg -n "temp-upload-url|get-upload-url|ai/source/upload|\$LIB\(\)\.getUploadUrl|\$LIB\(\)\.tempUploadUrl" templates/new-template/Dev/js templates/new-template/js -g "*.js"
```

查页面里的 `$LIB()` 旧上传调用：

```powershell
rg -n "\$LIB\(\)\.(uploadAssets|getUploadUrl|tempUploadUrl)" templates/new-template/Dev/js templates/new-template/js templates/new-template/tpl -g "*.js" -g "*.tpl"
```

查 `$LIB()` 旧实现：

```powershell
Select-String -Path "templates/new-template/js/lib-vd.min.js" -Pattern "uploadAssets|getUploadUrl|tempUploadUrl|\$LIB"
```

查 Turnstile 脚本：

```powershell
rg -n "turnstile/v0/api.js" templates/new-template -g "*.tpl"
```

从页面 JS 反查模板引用：

```powershell
rg -n "page-name\\.js" templates/new-template/tpl -g "*.tpl"
```

按英文已改页面基线缩小范围：

```powershell
powershell -ExecutionPolicy Bypass -File tools/skills/vidnoz-upload-api-migration/scripts/find-upload-migration-context.ps1 -ChangedOnly
```
