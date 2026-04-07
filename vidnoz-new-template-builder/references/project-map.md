# 项目结构图

## 作用范围

这个 skill 只服务于 `templates/new-template/` 下的前端页面目录。

## 关键目录

- `templates/new-template/tpl/`
  - Smarty 页面入口模板。
  - 共享 include 在 `tpl/component/` 下。
  - FAQ、pressroom、二级目录页面在子目录内。
- `templates/new-template/Dev/js/`
  - 在存在对应文件时，是优先修改的 JavaScript 源码层。
  - 包含 `gen/`、`recent-item/`、`video-dialog/`、`api/` 等共享模块目录。
- `templates/new-template/Dev/scss/`
  - 在存在对应文件时，是优先修改的样式源码层。
  - 通用样式模块位于 `common/`。
- `templates/new-template/js/`
  - 模板实际加载的运行时 JavaScript。
- `templates/new-template/css/`
  - 模板实际加载的运行时 CSS。
- `templates/new-template/lan/lan.json`
  - 单文件语言包，混合存放页面文案和共享文案。
- `templates/new-template/img/`
  - 页面图片资源与共享图片。

## 共享组件

- `templates/new-template/tpl/component/header.tpl`
- `templates/new-template/tpl/component/footer.tpl`
- `templates/new-template/tpl/component/common.tpl`
- `templates/new-template/tpl/component/share-meta.tpl`
- `templates/new-template/tpl/component/sharemeta.tpl`
- `templates/new-template/tpl/component/gen/*`

## 后端渲染与发布链路

项目不会把 `templates/new-template/` 当成普通静态目录。

- `modules/admin/controllers/PreviewController.php`
  - 从 `templates/new-template/tpl/` 生成预览 HTML。
- `modules/admin/controllers/TemplateController.php`
  - 发布静态 HTML，并从 `templates/new-template/` 复制共享资源。
- `modules/admin/service/ComCreateFun.php`
  - 提供预览与发布所依赖的辅助逻辑。

因此必须保护以下假设：

- Smarty include 关系不被破坏
- 模板文件名保持稳定
- `lan.json` 顶层页面 key 与模板文件名保持对应
- 模板里的相对资源路径保持有效

## 页面命名规则

对一个常规页面 `<page>`，通常对应：

- 模板：`tpl/<page>.tpl`
- 源脚本：`Dev/js/<page>.js`
- 源样式：`Dev/scss/<page>.scss`
- 运行时脚本：`js/<page>.js`
- 运行时样式：`css/<page>.css`
- 语言对象：`lan/lan.json` 中顶层 key `"<page>"`

这是常见规则，不是绝对规则。最终以模板中的真实引入关系为准。
