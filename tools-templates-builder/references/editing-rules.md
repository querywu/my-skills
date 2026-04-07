# 编辑规则

## 决策顺序

1. 先定位页面入口 HTML。
2. 再判断运行时代码是否能回溯到 `Dev` 源码。
3. 决定改项目私有文件还是 `_common` 共享文件。
4. 只有在没有可维护源码时，才把 `dist` 或其他运行时文件视为有效源。

## 何时改 HTML

直接改页面 HTML 的典型情况：

- 调整 `title`、`meta`、`canonical`、`alternate`
- 调整 `script`、`link`、`style`、语义标签位置
- 调整 H1/H2、首屏静态文案、SEO 结构
- 调整 header/footer 在当前页的引入顺序或静态 DOM

如果用户需求本质上是页面结构或可抓取内容问题，不要强行绕到 JS 或 SCSS。

## 何时改 Dev

优先改 `Dev/js` 或 `Dev/scss` 的条件：

- 项目 `dist/js` 或 `dist/css` 明显由对应 `Dev` 文件编译而来
- 共享 `_common/js` 或 `_common/css` 明显由 `_common/Dev` 编译而来
- 需要长期维护的交互逻辑或样式修正

注意：

- `watch.js` 会递归保留 `Dev/js`、`Dev/scss` 的子目录结构。
- 以 `_` 开头的 SCSS partial 不会单独编译。
- 只改 `Dev` 时，不要再手工补同样的改动到 `dist`。

## 何时改 _common

优先改 `_common` 的条件：

- 变更本质是共享 header/footer、dialog、popup、通用请求、通用样式、共享图片资源
- 相同品牌或子品牌下多个项目共用该模块
- 对 `vidmud`，共享模块语言也属于 `_common` 范畴，应改 `_common/Dev/js/lan/*.js`

影响判断：

- `vidqu/_common` 影响所有 `vidqu/*`
- `vidnoz/gen/_common` 只影响 `vidnoz/gen/*`
- `vidnoz/normal/_common` 只影响 `vidnoz/normal/*`
- `ismartta/_common` 影响 `ismartta/*`
- `vidmud/_common` 影响 `vidmud/*` 中已纳入配置的项目

不要只改某个项目的 `dist` 副本来规避共享修改，除非用户明确要求做局部分叉。

## 语言包边界

对 `vidmud`，默认遵守以下边界：

- `_common/Dev/js/lan/*.js`:
  - 存放公共语言包
  - 服务于 `_common/Dev/js/*` 里的共享模块
- `{page}/Dev/js/page-lan/*.js`:
  - 存放页面可直接使用的语言包
  - 只服务于该页面自己的业务脚本
  - 不是页面 `Dev/js/lan/*.js`

处理语言项时先找消费者，再决定改哪一层：

- 如果引用发生在 `_common/Dev/js/*`，改 `_common/Dev/js/lan/*.js`
- 如果引用发生在页面 `Dev/js/*`，改页面 `Dev/js/page-lan/*.js`

不要因为两个文件里都叫 `en.js`，就把它们当成同一份语言源。

页面 `page-lan` 可以是公共语言包的子集：

- 保留页面直接用到的键
- 删除页面未用到的冗余键
- 不要为了“看起来统一”把 `_common` 的全部键复制进页面语言包

## 何时改 dist

只有这些情况才直接改 `dist`：

- 目标运行时文件没有对应 `Dev` 源码
- 该品牌或项目当前就是直接维护运行时文件
- 用户明确要求修改编译产物
- 临时排查线上等价产物行为，而不是做长期源码修复

直接改 `dist` 时，要在答复里说明“当前产物就是有效源”或“没有可追溯源码”。

## 何时改配置

改 `projects.config.js` 的典型情况：

- 新增子项目到现有品牌
- 新增顶级品牌
- 调整 `commonPaths` 或构建覆盖范围

同时注意：

- 新增顶级品牌时，根目录 `package.json` 也应补脚本。
- 仅新增子项目时，通常不需要改 `watch.js`，因为它根据配置动态工作。
