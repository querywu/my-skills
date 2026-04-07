# 公用接口参考

这份文件用于沉淀 `templates/new-template/Dev/js/` 中反复出现的接口与调用模式。

目标不是按页面服务类命名，而是按“接口用途”和“调用链”归档，便于跨页面复用。

## 基础判断规则

### 1. `httpClient` 不是全项目默认模式

从当前仓库来看，`httpClient` 更接近 Gen 页面里的调用方式，不应默认推广到所有普通页面。

### 2. 普通页面先看 `common.js`

在普通页面中，优先检查：

- `templates/new-template/Dev/js/common.js`

当前已确认这里存在常用请求基础设施：

- `interHost`
- `toolsHost`
- `jqAjaxPromise(...)`
- `jqAjaxPromiseJson(...)`
- `jqAjaxPromiseFile(...)`
- 部分直接 `fetch(...)`

因此，分析普通页面接口时，先判断它是：

- 走 `common.js` 里的 jQuery Promise 封装
- 走直接 `fetch`
- 还是走 Gen 场景下的 `httpClient`

不要先入为主地假设页面一定使用 `httpClient`。

## 已识别的公用接口用途

来源样本：

- `templates/new-template/Dev/js/ai-baby-generator.js`

以下内容按接口用途整理，不按页面服务类归类。

### 创建任务

接口：

- `/ai/ai-tool/add-task`

当前样本调用方式：

- `httpClient.post(toolsHost + "/ai/ai-tool/add-task", { param, action })`

用途：

- 创建 AI 工具任务
- `action` 用于区分工具类型
- `param` 存放任务参数

可复用认知：

- 这是典型的“创建任务型接口”
- 后续通常会接任务轮询接口

### 查询任务状态

接口：

- `/ai/tool/get-task`

当前样本调用方式：

- `httpClient.post(toolsHost + "/ai/tool/get-task", { id })`

用途：

- 查询任务当前状态
- 获取任务完成结果或失败状态

可复用认知：

- 这是典型的“任务轮询型接口”

### 获取页面公共选项或配置

接口：

- `/ai/public/options`

当前样本调用方式：

- `httpClient.get(toolsHost + "/ai/public/options", { type })`

用途：

- 根据工具类型获取页面公共配置、模板选项、展示参数

可复用认知：

- 这是典型的“按类型取配置”接口

### 申请上传地址

普通页面优先参考：

- `templates/new-template/Dev/js/common.js`
- `apiGetUploadUrl(options)`

优先调用方式：

- `apiGetUploadUrl({ file_name, file_type, permanent_file: false })`

常见旧调用来源：

- `/ai/source/temp-upload-url`
- `/ai/source/get-upload-url`
- `$LIB().tempUploadUrl(...)`
- `$LIB().getUploadUrl(...)`
- `$LIB().uploadAssets(...)`

用途：

- 获取上传地址
- 上传前生成资源文件名和资源 key
- 返回后续直传所需的 `upload_url`、`access_url`、`key`、`static_url`

可复用认知：

- 对普通页面，这是典型的“上传前置接口”
- 在本 skill 中，如果需求未明确说明永久文件，默认按临时文件语义，显式传 `permanent_file: false`
- 不要依赖 `apiGetUploadUrl` 在 `common.js` 里的默认 `permanent_file` 值，因为代码默认值当前是 `true`
- 若页面或需求明确要求永久文件，再显式传 `permanent_file: true`
- 若旧页面还在直接请求旧上传接口，优先按 `vidnoz-upload-api-migration` 的规则迁移到公共方法

### 二进制直传

当前样本调用方式：

- `httpClient.put(uploadUrl, fileOrBlob)`

用途：

- 使用临时上传地址直接上传文件或 Blob

可复用认知：

- 这是“申请上传地址 -> PUT 上传”链路中的第二段

### 通过资源 key 获取访问地址或下载地址

接口：

- `/ai/source/get-access-url`

当前样本调用方式：

- `httpClient.post(toolsHost + "/ai/source/get-access-url", { key, action, file_name })`

用途：

- 把资源 key 转成访问地址或下载地址

当前样本特征：

- 常见 `action` 为 `"download"`
- 有时传 `file_name`

可复用认知：

- 这是典型的“资源 key 转 URL”接口
- 既可用于下载，也可能用于访问资源

### 获取国家或地区类型

接口：

- `/ai/public/get-country-type`

当前状态：

- 在样本文件中已声明
- 在已检查片段中未发现实际调用链

处理方式：

- 先标记为“待确认用途”
- 后续在其他页面中若出现使用，再补充用途与参数

## 已识别的调用链模式

### 上传链路

当前样本稳定体现出的链路：

1. 本地文件预处理
2. 对普通页面优先调用 `apiGetUploadUrl({ permanent_file: false, ... })`
3. 处理图片尺寸或格式
4. 通过临时地址执行 PUT 上传
5. 将上传后的资源 key 作为任务参数传入 `/ai/ai-tool/add-task`

补充说明：

- Gen 页面里仍可能看到 `httpClient.post(toolsHost + "/ai/source/temp-upload-url", ...)` 这类旧模式，分析时可以记录现状，但对普通页面的归纳应优先沉淀到 `apiGetUploadUrl`
- 如果需求只是“获取上传地址”且没有永久文件语义，默认归纳为临时文件上传链路

这是一套稳定的“预处理 -> 申请上传地址 -> 直传 -> 拿 key 创建任务”模式。

### 任务轮询链路

当前样本体现出的链路：

1. 调用 `/ai/ai-tool/add-task`
2. 使用任务 id 调用 `/ai/tool/get-task`
3. 按状态轮询，直到完成或失败

当前样本中的状态认知：

- `-1`: analyzing
- `-2`: generating
- `0`: done

可复用认知：

- 创建任务与查询任务通常成对出现
- 页面往往会有超时、失败重试和轮询间隔控制

### 下载链路

当前样本体现出的链路：

1. 页面已经拿到资源 key
2. 调用 `/ai/source/get-access-url`
3. 返回下载或访问 URL

可复用认知：

- 这个接口是下载、预览、资源外链能力的关键转换点

## 对 skill 的使用建议

后续继续沉淀接口时，按下面顺序记录：

1. 接口路径
2. 用途
3. 请求方法
4. 关键参数
5. 所属 host 类型
   - `interHost`
   - `toolsHost`
   - 直接上传 URL
   - 其他
6. 常见调用链
7. 当前适用范围
   - 普通页面
   - Gen 页面
   - 待确认

后续你继续提供其他页面后，这份文件应持续补全，而不是按单页服务类拆散记录。
