# 语言包与共享组件

## 语言包边界

`templates/new-template/lan/lan.json` 同时存放页面私有文案和共享文案。

### 共享顶层对象

常见共享对象包括：

- `header`
- `footer`
- `header.SelfLogin`
- `header.common-components`

这些只应用于多页面复用的共享 UI。

### 页面私有对象

页面模板通常使用与模板文件同名的顶层对象。

示例：

- `about.tpl` -> `"about"`
- `ai-image-generator.tpl` -> `"ai-image-generator"`
- `index.tpl` -> `"index"`

不要把页面私有文案塞进 `header` 或 `footer`。

## 模板中的常见使用方式

常见模式包括：

- `{$lan['title']}`
- `{$lan['sectionKey']['title']}`
- `{include file="./component/header.tpl"}`
- `{include file="./component/footer.tpl"}`
- `window.lan = JSON.parse(atob(...))`
- 页面自己的全局对象，例如 `textContent`、`PAGE_LAN`、`HEADER_LAN`、`FOOTER_LAN`

## 共享组件事实

- `tpl/component/header.tpl` 依赖共享语言数据渲染。
- `tpl/component/footer.tpl` 依赖共享语言数据渲染。
- Gen 页面经常复用 `tpl/component/gen/header.tpl`、`tpl/component/gen/aside.tpl`、`tpl/component/gen/script.tpl`。
- 判断 Gen 页面默认可用的公共 JS 时，优先以 `tpl/component/gen/script.tpl` 中实际引入的 `./js/gen/*` 脚本为准。

## 编辑规则

- 在 `tpl` 或 `js` 中使用新 key 之前，先在语言包里补齐。
- 如果只是改文案，不要轻易改 key 名。
- 同一页面内优先沿用已有命名风格，不要新造第二套结构。
- 如果 JS 已经通过模板注入拿到页面文本对象，就继续沿用现有模式，不要再新造一套全局变量。
