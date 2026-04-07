---
name: tools-templates-builder
description: 用于 D:\work\tools-templates 这个多品牌前端工具仓库的页面定位、源码修改、统一构建、公共资源同步与打包。当任务涉及 vidqu、vidnoz、ismartta、vidmud 下的 HTML 页面、Dev/js、Dev/scss、dist、_common、lan、多语言页面、projects.config.js、watch.js 或 pack.js 时使用。也用于判断该改源码还是产物、该运行哪个根目录构建命令、以及新增工具时如何接入统一构建系统。该仓库的页面通常以静态页面形式产出，再交给后端作为 TWIG 模板接入，因此在实现时要兼顾静态交付与后端模板集成场景。
---

# Tools Templates Builder

## 概览

将 `D:\work\tools-templates` 视为“根目录统一治理”的多品牌前端仓库。

同时把它视为“前端静态页面源仓库”而不是完整站点运行时：这里产出的 HTML/CSS/JS 通常会交付给后端，再被接入为 TWIG 模板或类似服务端模板。

基于真实文件结构工作，不要套用“每个子项目都有独立构建配置”的常见前端假设：

- 根目录的 `package.json`、`watch.js`、`projects.config.js` 是唯一构建入口。
- 子项目通常只有页面 HTML、`Dev/`、`dist/`、`lan/`，不应自带独立 `package.json` 或 `watch.js`。
- `_common` 代表同品牌或同子品牌共享资源，不是单页私有目录。
- `projects.config.js` 决定构建和监听范围；磁盘里即使存在目录，只要未进配置，就不属于当前构建图。
- 页面实现需要优先保持静态可交付、后端易接入，不要轻易引入依赖前端框架运行时或只适用于纯前端 SPA 的假设。

只读取当前任务真正需要的品牌、子项目和共享目录，控制上下文范围。

## 工作流程

1. 先从用户请求识别目标品牌、子项目、页面文件名或共享模块名。
2. 用 `projects.config.js` 确认该项目是否在构建范围内，再定位 HTML 入口、`Dev` 源码、`dist` 产物、`_common` 和 `lan`。
3. 按 `references/editing-rules.md` 判断该改 HTML、`Dev/*`、`_common/*` 还是运行时产物。
4. 如果改动触达 `_common`，默认认为会影响同一路径前缀下的所有已配置项目。
5. 需要验证时，只在仓库根目录运行对应品牌的构建或监听命令。
6. 需要打包时，先确认 `dist` 已更新，再按 `references/commands.md` 的打包规则执行。

## 根目录规则

- 所有 `npm run ...`、`node watch.js ...`、`node pack.js ...` 命令都在仓库根目录运行。
- 所有依赖只加到根目录 `package.json`。
- 不要在子项目目录创建新的 `package.json`、`watch.js` 或 `node_modules/`。
- 新增顶级品牌时，同时更新 `projects.config.js` 和根目录 `package.json` 的脚本。
- 新增子项目时，通常只改 `projects.config.js` 并补齐目录结构。

## 选文件规则

- 页面入口通常是项目根目录下的主 HTML，例如 `vidqu/ps/image-changer.html`、`vidmud/ai-photo-editor/ai-photo-editor.html`。
- 样式和交互优先回溯到 `Dev/scss/**/*.scss`、`Dev/js/**/*.js`；`watch.js` 会保留相对子目录结构编译到 `dist/css`、`dist/js`。
- 如果存在对应 `Dev` 源文件，只修改源码层，不要再手工把同样改动复制到 `dist`。
- 如果某个运行时代码只存在于项目 HTML、`lan`、`_common/js`、`_common/css` 或 `dist`，而没有可追溯的 `Dev` 源文件，就把该运行时文件视为当前有效源，并在答复里说明。
- 纯 HTML 结构、SEO 文案、标题层级、`script` / `link` 位置、静态首屏文本调整，通常直接修改页面 HTML。
- 修改 `_common/Dev` 时，预期输出先落到 `_common/js` 或 `_common/css`，再同步到目标项目的 `dist/js`、`dist/css`；`_common/img` 会直接同步到目标项目 `dist/img`。
- 如果需求会影响后端模板落地，优先选择“后端可直接消费的静态结构”，避免把关键信息推迟到前端脚本执行后才生成。

## 前端约定

- 如果用户说明移动端稿原始设计宽度是 `750`，只是把设计图缩成约 `375` 截图给你看，不要按截图直接量尺寸；仍按原始 `750` 设计稿换算。凡是从这类截图上量出来的尺寸，都先按 `2` 倍还原后再落样式。
- 如果用户同时给出 `100px = 1rem`，则先把截图量到的值乘 `2`，再按 `100px = 1rem` 转成 `rem`。
- 在本仓库写页面 SCSS 时，移动端样式优先直接写在当前选择器内部的 `@include mobileMedia {}` 中，不要为了同一元素在文件后面再单独重写一整块移动端选择器，除非用户明确要求集中写法。

## 构建与服务规则

- `node watch.js --brand <brand>` 会先构建，再进入监听，并启动本地 HTTP 服务。
- `node watch.js --brand <brand> --build-only` 只构建一次。
- `node watch.js --brand <brand> --es5` 会启用更老浏览器兼容的 Babel 与 Autoprefixer 目标。
- 开发服务支持直接访问页面 HTML，也支持把 `/css/...`、`/js/...`、`/img/...` 通过 Referer 映射到对应项目的 `dist` 目录。
- 改动引用路径时，不要只看 HTML 写法；要同时确认实际运行文件在 `dist` 中存在。

## 多语言与共享资源规则

- `lan/` 不是单一模式：有些项目是多语言 HTML，有些是多语言 HTML + JS，有些语言 HTML 只是很小的入口壳。
- 不要默认假设 `lan/en.html` 或 `lan/en.js` 的内容结构和其他品牌一致。
- `projects.config.js` 里的 `commonPaths` 决定共享资源前缀，例如 `vidnoz/gen/_common` 只影响 `vidnoz/gen/*`，不会影响 `vidnoz/normal/*`。
- 对 `vidmud` 这类正在扩展的品牌，要同时看磁盘目录和 `projects.config.js`；例如磁盘里可能已有实验项目，但只有配置中的项目会被构建和监听。
- `vidmud` 当前已拆成两层 JS 语言包：
  - `_common/Dev/js/lan/*.js` 是公共语言包，供 `_common` 里的共享模块使用。
  - 页面自己的 `Dev/js/page-lan/*.js` 是页面可直接使用的语言包，只放当前页面业务脚本实际需要的语言项，不要误判成页面 `Dev/js/lan/*.js`。
- `Dev/js/page-lan/*.js` 只放静态文本类语言项，不要放路径、URL、开关、存储 key、运行时配置或其他非文案常量。
- 处理 `vidmud` 语言问题时，先看消费者在哪：
  - 如果调用方在 `_common/Dev/js/*`，优先改 `_common/Dev/js/lan/*.js`。
  - 如果调用方在页面自己的 `Dev/js/*`，优先改该页面的 `Dev/js/page-lan/*.js`。
- 不要把 `_common` 语言包和页面 `page-lan` 当成同一份数据源随意复制。
- 当页面 `page-lan` 只是公共语言的一个可用子集时，保持它精简，只保留页面脚本直接用到的键。

## 验证

- 确认 HTML 中引用的运行时 CSS、JS、图片路径真实存在。
- 若修改的是 `Dev` 或 `_common/Dev`，确认对应 `dist` 或 `_common` 产物已更新；如果没运行构建，要明确说明未验证构建结果。
- 若改动 `projects.config.js`，确认新项目是否只需要加入配置，还是还要补根目录脚本。
- 若改动共享目录，明确说明影响面是同路径前缀下的所有配置项目。
- 若执行打包，确认是基于最新 `dist` 结果，而不是未构建源码。

## 参考资料

- 读取 `references/project-map.md` 了解当前品牌、子项目和目录模式。
- 读取 `references/editing-rules.md` 判断该改 HTML、`Dev`、`_common` 还是 `dist`。
- 读取 `references/commands.md` 获取常用构建、监听、打包命令，以及 `pack.js` 的关键参数。
