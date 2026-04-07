# 项目地图

## 根目录关键文件

- `package.json`: 唯一 npm scripts 与依赖入口。
- `watch.js`: 统一构建、监听、HTTP 开发服务入口。
- `projects.config.js`: 品牌、`commonPaths`、项目列表的唯一配置源。
- `pack.js`: 打包为部署 ZIP，并按代码引用裁剪未使用媒体。

## 当前配置内品牌

截至 2026-03-25，`projects.config.js` 中的构建品牌如下：

- `vidqu`
  - `commonPaths`: `vidqu/_common`
  - `projects`: `vidqu/ps`, `vidqu/face-swap`, `vidqu/image-to-video`
- `vidnoz`
  - `commonPaths`: `vidnoz/gen/_common`, `vidnoz/normal/_common`
  - `projects`: `vidnoz/gen/ai-kissing-video`, `vidnoz/gen/image-to-video`, `vidnoz/normal/ps`, `vidnoz/normal/girl-voice-changer`
- `ismartta`
  - `commonPaths`: `ismartta/_common`
  - `projects`: `ismartta/image-changer`
- `vidmud`
  - `commonPaths`: `vidmud/_common`
  - `projects`: `vidmud/ai-photo-editor`

注意：

- 磁盘里存在的目录不等于“已纳入构建”。例如 `vidmud/image-to-video` 当前存在于文件系统，但不在 `projects.config.js` 里，所以不会被统一构建系统覆盖。
- 判断“某页面为何没被 watch/build 处理”时，先看 `projects.config.js`，再看目录本身。

## 统一目录模式

大多数项目采用以下结构：

```text
{brand-or-subbrand}/{project}/
├── Dev/
│   ├── js/
│   └── scss/
├── dist/
│   ├── css/
│   ├── js/
│   ├── img/
│   └── font/   # 视项目而定
├── lan/        # 视项目而定
└── {page}.html
```

共享目录一般采用：

```text
{brand-prefix}/_common/
├── Dev/
├── js/
├── css/
├── img/
└── lan/        # 视品牌而定
```

`watch.js` 的行为是：

1. 编译项目 `Dev/scss` 到项目 `dist/css`
2. 编译项目 `Dev/js` 到项目 `dist/js`
3. 编译 `_common/Dev/scss` 到 `_common/css`
4. 编译 `_common/Dev/js` 到 `_common/js`
5. 把 `_common/js`、`_common/css`、`_common/img` 同步到同前缀项目的 `dist`

## 语言文件模式

不要假设所有 `lan/` 一样：

- `vidqu/face-swap/lan` 以多语言 HTML 为主。
- `vidqu/ps/lan`、`vidnoz/*/lan` 常同时有多语言 HTML 和 JS。
- 某些 `vidnoz` 项目的 `lan/*.html` 很小，更像语言入口壳，实际文本与逻辑在对应 `lan/*.js`。
- `vidmud` 当前有两层 JS 语言包：
  - `_common/Dev/js/lan/*.js` 编译到 `_common/js/lan/*.js`，供共享模块使用。
  - 页面自己的 `Dev/js/page-lan/*.js` 编译到页面 `dist/js/page-lan/*` 或相关运行时产物，供页面业务脚本使用；不要把页面语言包误认成 `Dev/js/lan/*.js`。

处理多语言问题时，先看目标品牌当前项目的 `lan/` 实际文件组合。

对 `vidmud`，还要额外区分“公共模块语言”与“页面语言”：

- `_common/Dev/js/dialog.js`、`bottom-message`、`popup` 这类共享模块，优先从 `_common/Dev/js/lan/*.js` 取值。
- 页面自己的业务脚本，应优先看同页的 `Dev/js/page-lan/*.js`。
- 页面语言包通常可以只是公共语言的一个子集，不需要无差别镜像 `_common` 里的全部键。

## HTTP 服务与路径投射

`watch.js` 启动的服务会：

- 枚举配置中所有项目根目录下的主 HTML，过滤掉 `lan/` 内页面。
- 支持直接访问这些 HTML。
- 支持把 `/css/...`、`/js/...`、`/img/...` 按 Referer 自动映射到对应项目 `dist/` 目录。

因此：

- HTML 里可能同时出现 `/dist/css/a.css` 和 `/css/a.css` 两种写法。
- 修改路径前，先确认真实资源文件存在于哪个目录，不要只按字面路径判断。
