# Gen 公共模块参考

这份文件用于说明 `templates/new-template/tpl/component/gen/script.tpl` 默认注入的 `./js/gen/*` 脚本分别负责什么。

先把规则说清楚：

- 判断 Gen 页面默认可用的公共 JS，优先以 `tpl/component/gen/script.tpl` 为准。
- `script.tpl` 里实际引入的 `./js/gen/*`，默认都可以认为是当前 Gen 页面可直接依赖的公共能力。
- 没有被 `script.tpl` 默认引入的 `js/gen/*`，不要当成页面天然可用；只有页面自己额外引入时，才按实际依赖处理。
- 普通 / 非 Gen 页面不要直接套用这里的实现方式，尤其不要把 Gen 的 `httpClient`、`genDialogService`、`genDownloader` 生搬过去。

## script.tpl 默认注入模块

当前 `tpl/component/gen/script.tpl` 默认引入了这些 `./js/gen/*`：

- `components/banner.js`
- `components/zIndexManage.js`
- `components/scrollLock.js`
- `components/popup.js`
- `@constants.js`
- `components/languageRoute.js`
- `@http.js`
- `@common.js`
- `@core.js`
- `components/loading.js`
- `components/dialog.js`
- `components/share.js`
- `lib/jszip.min.js`

## 模块职责

### `@constants.js`

主要职责：

- 维护 Gen 各类升级弹窗配置 `UPGRADE_CONTENT`
- 维护页面 / 产品类型到埋点或接口参数的映射 `USER_EXTRA_INFO`
- 提供 `PAYMENT_URL`、`MY_CREATIONS_URL`、`HOME_URL` 这类 Gen 公共跳转常量

使用判断：

- 当页面需要触发升级弹窗、跳转定价页、根据当前工具类型取通用配置时，优先先看这里
- 如果只是新增某个 Gen 工具在升级弹窗里的展示配置，通常改这里，而不是在页面里硬编码第二份

### `@http.js`

主要职责：

- 提供 Gen 页面通用请求客户端 `httpClient`
- 统一默认请求头，例如 `X-TASK-VERSION`、`Request-Language`、`Request-Origin`、`Request-App`
- 管理认证 cookie、`Authorization`、`device_id`
- 处理 GET / POST / PUT / DELETE / PATCH 与响应解析
- 对 Ai Gen 域名附加 `Request-Sub-Origin`、`X-Device-Id`

使用判断：

- 这是 Gen 页面自己的请求层，不要默认推广到普通页面
- Gen 页面新增接口请求时，优先沿用 `httpClient`
- 如果页面已经通过 `httpClient` 走登录态、设备标识或统一报错，就不要再混入第二套 fetch 封装

### `@common.js`

主要职责：

- 放置大量 Gen 公共工具函数和公共交互能力
- 通用工具：转义、UUID、数字格式化、复数判断、模板文本替换、移动端判断
- 状态占位：`StatusWrapper`、`notFound`
- 下载能力：`genDownloader`
- 内容安全检查：`ContentSafetyChecker`
- 积分展示辅助：`isShowCreditGen`
- 列表滚动加载：`createBottomLoad`
- 埋点与事件：`genGtag`、`trackEvent`、`PubSub`、`listenPubsub`
- 布局辅助：响应式网格、入口标签显示
- 语言与路由辅助：`getPreferredLanguage`、`pageLinks(...)` 结果消费
- 菜单 / banner / 跳编辑器 / 图片转文件等零散但公共的 Gen 逻辑

使用判断：

- 如果页面要做“下载、状态占位、内容安全、网格布局、埋点、通用跳转”这类能力，先查这里有没有现成实现
- `@common.js` 很大，修改前先确认是不是已有同名能力，避免页面里再造一套
- Gen 下载流程优先看 `genDownloader`，不要回退到普通页面的 `ToolTip + progress`

### `@core.js`

主要职责：

- 管理 Gen 站内菜单与当前页面激活状态：`GenMenu`
- 管理登录态、用户信息、积分、订阅展示：`GenCredit`、`GenUserAuthManager`
- 处理移动端菜单、导航、登录弹窗、登出、登录状态监听
- 拉取用户积分与 `user-extra-info`
- 暴露全局实例 `window.genMenu`、`window.genAuth`

使用判断：

- Gen 页面只要涉及登录、积分、当前菜单高亮、升级入口、登录后刷新数据，都应先检查这里
- 不要在页面里重复维护登录状态、用户积分显示、菜单激活逻辑

### `components/banner.js`

主要职责：

- 控制 `#banner_template` 对应的单日横幅展示
- 用 localStorage 记录当天是否展示
- 处理 banner 点击跳转和埋点

使用判断：

- 这个文件是 `script.tpl` 默认注入的公共 banner 基础能力
- 它和节日 / 活动 banner 不是一回事
- 只有页面里实际存在 `#banner_template` 且需要这套单日展示逻辑时，才围绕它扩展

### `components/zIndexManage.js`

主要职责：

- 统一维护 Gen 弹层的全局 z-index
- 跟踪当前打开的 dialog 栈
- 为 popup / dialog 提供层级分配

使用判断：

- 新增 Gen 弹层时，优先沿用这里的层级管理
- 不要手工写一组与 `GEN_Z_INDEX` 竞争的固定大 z-index

### `components/scrollLock.js`

主要职责：

- 统一锁定 / 解锁页面滚动
- 处理锁滚时 body 样式、header 偏移与 overscroll

使用判断：

- Gen 弹层、全屏预览、浮层打开后需要锁滚时，优先用 `ScrollLock`
- 不要在页面里散写 `body.style.overflow = "hidden"` 这种临时逻辑

### `components/popup.js`

主要职责：

- 提供通用浮层组件 `GenPopup`
- 通过 `$.fn.genPopup` 暴露 jQuery 调用方式
- 负责浮层位置计算、跟随目标元素、点击外部关闭、ESC 关闭、hover 离开关闭

使用判断：

- Gen 页面里按钮旁说明浮层、菜单浮层、轻量弹出面板，优先检查是否可用 `genPopup`
- 如果需求只是 anchor 附近的悬浮内容，不要直接上完整 dialog

### `components/loading.js`

主要职责：

- 定义自定义元素 `<gen-loading>`
- 提供局部区域 loading 和全局区域 loading 展示
- 用 attribute 控制 `loading`、`init-loading`、`global`

使用判断：

- 页面局部区域等待数据时，优先看能否直接套 `<gen-loading>`
- 如果只是内容容器的载入态，不要重复写一套 spinner DOM

### `components/dialog.js`

主要职责：

- 提供底层弹窗 `genDialog(...)`
- 提供高层服务 `genDialogService`
- 常见能力包括：
  - `failed`
  - `downloadSuccess`
  - `downloadProgress`
  - `globalLoading`
  - `zoomDialog`
  - `insufficientCredits`
  - `upgrade`
  - `spreadDialog`

使用判断：

- Gen 页面错误提示、下载进度、升级弹层、积分不足、放大预览，优先走这里
- 普通 / 非 Gen 页面的 `ToolTip(...)` 规则不适用于 Gen；Gen 侧默认应先用 `genDialogService`

### `components/share.js`

主要职责：

- 定义 `<gen-share-dialog>`
- 管理生成内容分享弹窗
- 生成或缓存分享链接
- 根据资源 key 获取访问地址
- 与 `genDialogService.globalLoading`、`httpClient`、`ScrollLock` 协同工作

使用判断：

- Gen 页面分享生成结果时，优先检查是否已经使用 `gen-share-dialog`
- 不要在页面里重复写一套“取资源地址 + 生成分享链接 + 展示分享面板”逻辑

### `components/languageRoute.js`

主要职责：

- 维护不同语言下的工具路由映射
- 通过 `pageLinks(lang)` 返回各工具页面 URL

使用判断：

- Gen 页面要做跨语言跳转、菜单路由、工具跳转时，优先用这里
- 不要在页面里再硬编码一份多语言链接表

### `lib/jszip.min.js`

主要职责：

- 为 Gen 多文件下载提供压缩能力
- 被 `genDownloader.downloadMultipleFiles(...)` 依赖

使用判断：

- 当页面涉及多文件打包下载，确认不要删掉这个依赖
- 如果页面只做单文件下载，一般不需要直接改它

## 非 script.tpl 默认注入，但可能被页面单独使用

这些文件在 `js/gen/*` 中存在，但不是 `script.tpl` 默认注入的公共 JS：

### `recentComponent/index.js`

主要职责：

- 定义 `<recent-component>`
- 拉取 `my creations` 列表
- 渲染最近生成记录
- 监听 `trainTask`、`retryEvent`、`updateRecentCom` 等事件

使用判断：

- 只有当页面自己引入 `./js/gen/recentComponent/index.js` 时，才把它当成当前页面可用能力
- 适合“最近生成记录”模块，不是所有 Gen 页面默认都有

### `@aside.js`

主要职责：

- 控制侧边栏展开 / 收起
- 处理 aside 宽度、hover 展开、本地缓存状态
- 兼顾部分页面的结果区布局联动

使用判断：

- 它属于 Gen 侧边栏行为层
- 不是 `script.tpl` 默认注入脚本，只有页面或模板实际引入时才处理它

### `components/blackFridayBanner.js` / `components/halloweenBanner.js` / `components/santaBanner.js`

主要职责：

- 节日 / 活动 banner

使用判断：

- 默认不纳入通用复用目标
- 只有需求明确要求活动 banner 或页面本身已引入时，才继续分析和复用

## 改动建议

- Gen 页面先判断是不是已经依赖 `script.tpl` 默认注入模块，再决定是否新增页面私有实现。
- 需要请求、下载、弹窗、分享、登录、积分、路由时，先在这份参考里定位对应公共层，不要直接新造。
- 如果某个需求看起来同时能落在 `@common.js` 和页面私有文件里，优先判断它是否属于跨页面复用能力，再决定是否上收。
