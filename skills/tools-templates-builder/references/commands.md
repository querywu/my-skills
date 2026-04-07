# 命令与打包

## 常用命令

所有命令都在仓库根目录 `D:\work\tools-templates` 运行。

### 监听 / 开发

```powershell
npm run watch:vidqu
npm run watch:vidnoz
npm run watch:ismartta
npm run watch:vidmud
```

等价的底层写法：

```powershell
node watch.js --brand <brand>
```

用途：

- 初始全量构建
- 进入文件监听
- 启动本地 HTTP 服务

### 单次构建

```powershell
npm run build:vidqu
npm run build:vidnoz
npm run build:ismartta
npm run build:vidmud
```

等价的底层写法：

```powershell
node watch.js --brand <brand> --build-only
```

### 兼容模式

```powershell
node watch.js --brand vidqu --es5
node watch.js --brand vidnoz --build-only --es5
```

`--es5` 会切换 Babel 和 Autoprefixer 目标，适合老浏览器兼容验证。

## watch.js 行为要点

- 递归编译项目 `Dev/js/**/*.js` 到项目 `dist/js/**`
- 递归编译项目 `Dev/scss/**/*.scss` 到项目 `dist/css/**`
- 跳过以 `_` 开头的 SCSS partial
- 编译 `_common/Dev` 后，同步 `_common/js`、`_common/css`、`_common/img` 到同前缀项目的 `dist`
- 启动 HTTP 服务并支持 `/css`、`/js`、`/img` 的 Referer 映射

## 打包命令

最常用入口：

```powershell
npm run pack
```

底层也可以直接传参数：

```powershell
node pack.js --brand vidqu --subproject vidqu/ps
node pack.js --brand vidnoz --subproject vidnoz/gen/image-to-video --keep-console
node pack.js --brand vidmud --subproject vidmud/ai-photo-editor --no-media-prune
```

## pack.js 规则

- 打包前先确保目标项目 `dist` 已存在且是最新构建结果。
- 默认会分析并裁剪未使用媒体：
  - 扫描 `dist` 下的 HTML / CSS / JS
  - 递归扫描语言文件
  - 必要时会把对应 `_common` 代码文件也纳入分析
- 默认 `mediaPrune = true`
- `--no-media-prune` 会保留所有媒体文件
- `--keep-console` 会保留 console 语句

打包输出：

- 统一写到根目录 `packages/`
- 文件名格式为 `{brand}_{subproject-name}_{timestamp}.zip`

## 执行建议

- 做源码修复后，优先跑对应品牌的 `build:*` 或 `watch:*`。
- 做共享目录修改后，至少检查一个受影响项目的 `dist` 是否同步更新。
- 做打包相关任务时，不要假设 `pack.js` 只是简单 zip；它会做媒体引用分析和清理。
