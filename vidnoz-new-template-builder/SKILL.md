---
name: vidnoz-new-template-builder
description: 用于本仓库 templates/new-template 区域的前端页面实现、修改与优化。当任务涉及 Smarty 的 tpl 页面模板、Dev/js 或 Dev/scss 源码、已编译的 js/css 产物、lan/lan.json 语言项，或共享的 header/footer/common 组件时使用。也用于根据需求定位正确页面文件、判断应修改源码还是编译产物，以及在不破坏预览与发布链路的前提下做局部前端优化。
---

# Vidnoz New Template Builder

## 概览

将 `templates/new-template/` 视为这个项目的前端页面源模板目录。

基于项目真实结构工作，不要套用泛化的前端假设：

- `tpl/` 存放页面入口模板和 Smarty include。
- `Dev/js/` 与 `Dev/scss/` 在存在时是优先编辑的源码层。
- `js/` 与 `css/` 是模板实际引用的运行时产物，通常由仓库外部编译器生成。
- `lan/lan.json` 同时存放页面私有文案与 `header`、`footer` 等共享语言对象。
- `modules/admin/controllers/PreviewController.php` 与 `modules/admin/controllers/TemplateController.php` 都从 `templates/new-template/` 渲染和发布页面。

只读取当前页面或共享组件真正需要的文件，始终控制上下文范围。

## 工作流程

1. 从需求中识别页面 slug、路由或共享组件名称。
2. 定位相关的 `tpl`、`Dev/js`、`Dev/scss`、`js`、`css` 和 `lan.json` 条目。
3. 检查页面是否依赖 `component/header.tpl`、`component/footer.tpl`、`component/gen/*`，以及 `component/gen/script.tpl` 中实际引入的 `js/gen/*` 共享模块。
4. 只修改保证模板、文案、样式和行为一致所需的最小文件集合。
5. 验证模板或脚本中新增或修改的语言 key 都存在。
6. 验证模板中引用的资源路径都实际存在。

如需把需求映射成文件列表，读取 `references/workflow.md`。

## 选文件规则

- 从 `templates/new-template/tpl/<page>.tpl` 开始定位页面。
- 在存在对应文件时，优先修改 `Dev/js/<page>.js` 与 `Dev/scss/<page>.scss`。
- 完成前必须检查模板中实际引入的运行时 `./js/*.js` 与 `./css/*.css`。
- 当存在对应 `Dev/js` 或 `Dev/scss` 源文件时，只修改源码层，不要再手工复制一份相同改动到 `js/` 或 `css/`。
- 如果修改了 `Dev` 源文件后发现运行时产物未更新，应提醒用户确认外部编译器是否已经开启，而不是默认手工同步产物。
- 如果不存在匹配的 `Dev` 源文件，则直接修改运行时产物，并明确说明当前产物就是有效源。
- 不要假设每个运行时产物都与一个 `Dev` 文件严格 1:1 对应。`Dev/js/gen/`、`Dev/js/recent-item/`、`Dev/scss/common/` 等共享模块可能共同产出多个运行时文件。

需要快速初筛时，使用 `scripts/find-page-files.ps1`。

## i18n 规则

- 将 `templates/new-template/lan/lan.json` 视为单一共享语言源。
- 页面私有文案应放在与模板文件同名的顶层对象下，例如 `ai-image-generator.tpl` 对应 `"ai-image-generator"`。
- 共享导航、页脚及公共组件文案应放在 `header`、`footer` 等共享顶层对象下。
- 非共享需求不要把页面私有文案放进 `header` 或 `footer`。
- 新增页面模板时，必须同步在 `lan.json` 中新增同名顶层语言对象。
- 当 JavaScript 需要文案时，优先沿用模板注入或现有全局对象模式，例如 `PAGE_LAN`、`HEADER_LAN`、`FOOTER_LAN`、`textContent` 等。

共享语言边界见 `references/i18n-and-shared-components.md`。

## 公用接口规则

- 当页面脚本中存在稳定的接口映射表或请求模式时，将其视为可复用的“公用接口知识”。
- 优先总结这些接口的用途、请求方式、常见参数、返回后的处理流程，以及与上传、轮询、下载相关的固定调用链。
- 不要只记录 URL；要同时记录调用语义，例如“创建任务”“查询任务状态”“申请上传地址”“获取下载访问地址”。
- 如果某个接口在当前页面里只是声明但未使用，也可以记录为“已出现但待确认用途”。
- `httpClient` 不应被视为全项目默认请求方式，它更偏向 Gen 页面模式。
- 对普通页面，先检查 `templates/new-template/Dev/js/common.js` 中现有的请求封装与 host 处理，例如 `jqAjaxPromise`、`jqAjaxPromiseJson`、`jqAjaxPromiseFile`、`interHost`、`toolsHost`，再决定如何归纳接口调用模式。
- 对上传相关需求，默认将 `templates/new-template/Dev/js/common.js` 中的 `apiGetUploadUrl` 视为“申请上传地址”的统一公共入口。
- 在这个 skill 里，如果需求只说“获取上传地址”而未额外说明，默认按临时文件语义处理，也就是调用 `apiGetUploadUrl({ permanent_file: false, ... })`；不要依赖 `common.js` 当前的默认 `permanent_file` 值。
- 只有当页面现有语义、接口上下文或用户需求明确指向永久文件时，才改为显式传 `permanent_file: true`。
- 如页面原本还是旧的 `/ai/source/get-upload-url`、`/ai/source/temp-upload-url`、`$LIB().getUploadUrl(...)`、`$LIB().tempUploadUrl(...)`、`$LIB().uploadAssets(...)` 上传链路，优先按 `vidnoz-upload-api-migration` 的规则迁移到 `apiGetUploadUrl` / `apiUploadFileWithSign`，不要在页面里继续扩散旧接口模式。
- 追加公用接口时，优先维护 `references/common-interfaces.md`，避免把接口说明散落在多个参考文件里。

## 共享组件规则

- 将 `templates/new-template/tpl/component/header.tpl` 与 `templates/new-template/tpl/component/footer.tpl` 视为全站共享组件。
- 将 `templates/new-template/tpl/component/gen/*` 视为 Gen 类页面共享基础设施。
- 分析 Gen 页面公共能力时，优先以 `templates/new-template/tpl/component/gen/script.tpl` 为准；其中实际通过 `./js/gen/*` 引入的脚本，都视为 Gen 页面默认可用、默认应沿用的公共 JS。
- 基于当前 `script.tpl`，默认可用的 Gen 公共 JS 包括 `@constants.js`、`@http.js`、`@common.js`、`@core.js`、`components/banner.js`、`components/zIndexManage.js`、`components/scrollLock.js`、`components/popup.js`、`components/languageRoute.js`、`components/loading.js`、`components/dialog.js`、`components/share.js`、`lib/jszip.min.js`。
- `templates/new-template/js/gen/components/*` 下未被 `script.tpl` 默认引入的活动 banner 组件，不作为通用复用目标；除非需求明确要求，否则不要主动使用或依赖 `blackFridayBanner.js`、`halloweenBanner.js`、`santaBanner.js` 等文件。
- 如需判断这些 Gen 公共 JS 各自负责什么、该优先复用哪一层，读取 `references/gen-common-modules.md`。
- 对普通 / 非 Gen 页面，也要留意 `Dev/js` 中实际复用的共享 UI 能力，例如下载进度弹层、错误提示弹层等。
- `references/common-ui-components.md` 里的下载与错误弹窗模式仅作为普通 / 非 Gen 页面参考；Gen 页面默认使用自己的方法，不要直接套用这些模式。
- 修改共享组件前，默认认为会影响多个页面。至少检查一个代表页面的 include 关系与修改后的影响范围。
- 除非需求明确要求页面分叉，不要把共享组件内容复制回页面模板中。

## SEO 规则

- 这个项目对 SEO 要求很高。编写 `tpl` 与 `js` 时，默认把 SEO 友好性当成硬约束。
- 优先保证首屏核心文案、标题区块、主要说明文本和关键内容块直接出现在 `tpl` 输出中，而不是完全依赖 JS 运行后再补内容。
- 优先使用清晰的语义化结构，例如合理的标题层级、正文区块、列表、按钮文案和图片 `alt`。
- 不要为了交互效果把本应直接输出的关键 SEO 文案延后到纯前端渲染。
- `js` 应避免破坏正文可读性、首屏主内容和标题层级，不要在初始化时无必要地清空、替换或隐藏核心文本区块。
- 当需求涉及文案、模块顺序、标题或内容块时，优先考虑是否有利于页面主题表达、关键词覆盖、内容完整性与可抓取性。
- 本 skill 不负责主动编写或维护 `canonical`、`alternate`、结构化数据代码；除非用户明确要求，否则不要把这三类内容纳入 SEO 工作范围。

## 优化规则

- 只在当前需求范围内或直接触达的共享组件周边做优化。
- 优先做局部清理：删除重复选择器、收敛重复 DOM 操作、复用已有工具方法、简化明显重复逻辑。
- 保持 Smarty 语法、include 路径、后端注入变量不被破坏。
- 保持既有文件名与发布假设不变，除非需求明确要求改名。
- 避免大范围架构重构、框架迁移和跨页抽象整理，除非用户明确要求。
- 如果修改的是 `Dev` 源文件且运行时产物没有更新，先提醒用户确认外部编译器是否已开启，不要直接复制源码改动到运行时产物。
- 做页面实现或优化时，顺带检查是否损伤 SEO：例如标题层级混乱、关键文案只存在于 JS 中、图片缺少必要 `alt`、按钮与链接文案过空等。

源码与产物的处理规则见 `references/editing-rules.md`。

## 验证

- 确认模板仍然引用存在的 `./js/` 与 `./css/` 文件。
- 确认新语言 key 或改动后的语言 key 确实存在于 `lan.json`。
- 确认共享 include 路径没有失效。
- 若改动触达共享 `header` 或 `footer`，明确说明影响面是全局。
- 如果修改的是 `Dev` 源文件且看起来未触发编译，明确提醒用户检查外部编译器是否已开启。
- 如果改动触达 `tpl` 或核心 `js` 逻辑，顺带检查是否影响页面可抓取文本、标题层级和主要内容输出。

## 参考资料

- 读取 `references/project-map.md` 了解项目结构与发布链路。
- 读取 `references/workflow.md` 把需求转成文件级操作清单。
- 读取 `references/i18n-and-shared-components.md` 处理页面文案、共享文案与组件边界。
- 读取 `references/gen-common-modules.md` 了解 `script.tpl` 默认注入的 Gen 公共 JS 与非默认注入模块边界。
- 读取 `references/common-interfaces.md` 了解已沉淀的公用接口与调用模式。
- 读取 `references/common-ui-components.md` 了解已沉淀的普通 / 非 Gen 页面下载组件和错误弹窗模式；不要默认把它们用于 Gen 页面。
- 在决定修改 `Dev/*` 还是 `js/*`、`css/*` 前，读取 `references/editing-rules.md`。
