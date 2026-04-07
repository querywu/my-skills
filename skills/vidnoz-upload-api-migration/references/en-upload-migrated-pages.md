# 英文已改 JS 基线

## 用途

这份清单用于记录当前 EN 站上传接口迁移时已确认需要修改的 JS 文件，供后续多语言迁移直接复用。

优先把它当作：

- 多语言迁移的 JS 基线列表
- 用来确认本轮只需要修改哪些 JS 文件
- 反例库，提醒不要假设 JS 和 `tpl` 同名

如需最新工作区状态，优先运行：

```powershell
powershell -ExecutionPolicy Bypass -File tools/skills/vidnoz-upload-api-migration/scripts/find-upload-migration-context.ps1 -ChangedOnly
```

## 当前已确认需修改的 EN JS

这些文件来自当前仓库根目录的 `en-upload-migration-test-checklist.txt`、现有工作区改动，以及已确认的实际入口文件。后续处理时，只需要修改下面这些 JS：

- `ai-anime-kissing.js`
- `ai-baby-generator.js`
- `ai-cartoon-generator.js`
- `ai-clothes-changer.js`
- `ai-dubbing.js`
- `ai-ghibli-filter.js`
- `ai-head-swap-method.js`
- `ai-image-generator-methods.js`
- `ai-kissing-video.js`
- `ai-photo-editor-methods.js`
- `ai-song-cover.js`
- `ai-video-compressor.js`
- `ai-video-enhancer.js`
- `ai-voice-translator.js`
- `audio-to-text.js`
- `gen-face-swap-auth.js`
- `hailuo-ai-video.js`
- `image-combiner.js`
- `image-to-video-ai.js`
- `kissing-upload.js`
- `kling-ai-video.js`
- `magic-animate.js`
- `music-video.js`
- `template-upload.js`
- `video-translate.js`
- `vidnoz-gen-clothesChanger.js`
- `vidnoz-gen-outfit.js`
- `vidnoz-gen-photo-dance.js`

## 已确认的入口映射

这些映射说明了为什么不能默认按文件同名定位：

- `templates/new-template/Dev/js/ai-anime-kissing.js -> templates/new-template/tpl/anime-kissing.tpl`
- `templates/new-template/Dev/js/gen-face-swap-auth.js -> templates/new-template/tpl/face-swap.tpl`
- `templates/new-template/Dev/js/music-video.js -> templates/new-template/tpl/ai-music-video-generator.tpl`
- `templates/new-template/Dev/js/vidnoz-gen-photo-dance.js -> templates/new-template/tpl/magic-animate.tpl`
- `templates/new-template/Dev/js/vidnoz-gen-clothesChanger.js -> templates/new-template/tpl/ai-clothes-changer.tpl`
- `templates/new-template/Dev/js/vidnoz-gen-outfit.js -> templates/new-template/tpl/ai-clothes-changer.tpl`

## 特殊入口说明

### 1. 不要按 `tpl` 清单改文件

这份基线的用途是直接告诉你“改哪些 JS”，不是让你先按 `tpl` 名找文件。

遇到非一对一映射时，优先以这份 JS 清单为准，再回看 `tpl` 的实际 runtime 引用。

### 2. `ai-headshot-generator`

这个页面当前入口上传逻辑不在平级 `Dev/js/<page>.js`，而在：

- `templates/new-template/js/ai-headshot-generator/index.js`
- `templates/new-template/js/ai-headshot-generator/api.js`

遇到类似结构时，优先跟随 `tpl` 里的实际 runtime js 引用，不要强行寻找平级 `Dev/js` 文件。

### 3. `ai-clothes-changer`

这个页面的入口 runtime js 是：

- `templates/new-template/js/vidnoz-gen-clothesChanger.js`
- `templates/new-template/js/vidnoz-gen-outfit.js`

但当前 EN 改动里还出现了共享逻辑文件：

- `templates/new-template/Dev/js/ai-clothes-changer.js`

如果多语言页复用同一入口 `tpl`，通常只需改一次 JS；如果不同语言页拆成不同 `tpl`，要把 Turnstile 和模板入口一起补齐。

## 当前工作区里出现的共享 helper

这些文件可能没有直接被 `tpl` 以同名方式引用，但仍可能承载上传逻辑：

- `templates/new-template/Dev/js/ai-clothes-changer.js`
- `templates/new-template/Dev/js/kissing-upload.js`
- `templates/new-template/Dev/js/magic-animate.js`
- `templates/new-template/Dev/js/template-upload.js`

处理这类文件时：

- 先看它是否在上面的 JS 基线清单里
- 再用 `rg` 反查 importer、模板片段或运行时入口
- 不要因为它没有直接同名 `tpl` 就忽略
