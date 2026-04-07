# 工作流

## 把需求映射成文件

1. 从需求中提取页面 slug、路由名称或共享组件名称。
2. 先打开页面模板。
3. 检查模板中的 `include`，识别是否使用了共享组件。
4. 检查模板里引入的运行时 `./js/*.js` 与 `./css/*.css`。
5. 查找是否存在对应的 `Dev/js/*.js` 与 `Dev/scss/*.scss` 源文件。
6. 检查 `lan/lan.json` 中：
   - 页面私有语言对象
   - 如有需要，再检查共享 `header` 或 `footer`
7. 如果是 Gen 页面，还要按需检查 `tpl/component/gen/*` 与共享 `js/gen/*` 模块。
8. 先打开 `tpl/component/gen/script.tpl`，把其中实际引入的 `./js/gen/*` 脚本视为当前项目 Gen 页面默认可用、默认应沿用的公共 JS。
9. 基于当前 `script.tpl`，优先检查 `@constants.js`、`@http.js`、`@common.js`、`@core.js`、`components/banner.js`、`components/zIndexManage.js`、`components/scrollLock.js`、`components/popup.js`、`components/languageRoute.js`、`components/loading.js`、`components/dialog.js`、`components/share.js`、`lib/jszip.min.js`。
10. `js/gen/components/*` 下未被 `script.tpl` 默认引入的活动 banner，不纳入通用复用范围；除非需求明确要求，否则跳过 `blackFridayBanner.js`、`halloweenBanner.js`、`santaBanner.js` 等文件。
11. 如果需要判断某个 Gen 公共 JS 的职责边界、依赖关系或应该优先复用哪一层，读取 `references/gen-common-modules.md`。

## 决定改哪些文件

只改当前需求真正需要的部分：

- 模板结构、SEO、Smarty include：
  - 改 `tpl/*.tpl`
  - 修改时同时检查首屏标题、主要文案、核心模块是否直接在模板输出中可见
- 交互行为：
  - 优先改 `Dev/js/*.js`
  - 不要把同样改动再手工复制到 `js/*.js`
  - 如果运行时文件看起来未更新，提醒用户确认外部编译器是否已开启
  - 避免把关键 SEO 文案改成完全依赖 JS 注入
- 样式：
  - 优先改 `Dev/scss/*.scss`
  - 不要把同样改动再手工复制到 `css/*.css`
  - 如果运行时文件看起来未更新，提醒用户确认外部编译器是否已开启
- 文案：
  - 改 `lan/lan.json`
- 共享导航、页脚或共享小组件：
  - 改 `tpl/component/` 下对应文件，或相关共享源码/运行时文件

## 需要警惕的信号

遇到以下情况先停下来重新判断：

- 需求会导致页面文件重命名
- 页面模板缺少同名语言对象
- 模板引用了运行时产物，但仓库里找不到明显源码来源
- 需求看起来是页面私有改动，却触达了 `header.tpl` 或 `footer.tpl`
- 变更依赖本仓库中并不存在的构建工具

## 最低检查清单

- 模板路径仍然有效。
- 语言 key 没有缺失。
- 共享组件变更是有意的。
- 如果只改了 `Dev` 源码，要检查运行时产物是否已经由外部编译器更新；如果没有，提醒用户确认编译器状态。
- 如果改动涉及 `tpl` 或核心 `js`，检查标题层级、首屏主要文案、图片 `alt` 与核心内容块是否仍然 SEO 友好。
