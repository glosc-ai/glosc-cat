# CatAudio 资源说明

本目录收集用于猫语识别与播放演示的公开音频样本，优先选择带有明确语义描述、许可清晰、可公开下载的素材。

本轮已额外补充一组更干净、杂音更少的短音频，优先推荐使用 `Mixkit` 的 4 条样本作为 MVP 演示素材。

## 优先使用（更干净）

| 文件名 | 语义标签 | 描述 | 来源 | 许可 |
| --- | --- | --- | --- | --- |
| `clean_meow_mixkit.mp3` | 干净喵叫 | 简短、清晰的基础 meow | Mixkit: `Sweet kitty meow` | Mixkit License |
| `hungry_meow_mixkit.mp3` | 饥饿喵叫 | 更贴近想吃东西的短叫声 | Mixkit: `Domestic cat hungry meow` | Mixkit License |
| `attention_meow_mixkit.mp3` | 求关注 | 更贴近求关注/招呼的短叫声 | Mixkit: `Little cat attention meow` | Mixkit License |
| `agitated_meow_mixkit.mp3` | 激动/不满 | 偏激动、偏尖锐的短叫声 | Mixkit: `Angry cartoon kitty meow` | Mixkit License |

## 文件清单

| 文件名 | 语义标签 | 描述 | 来源 | 许可 |
| --- | --- | --- | --- | --- |
| `food_request_british_shorthair.mp3` | 想吃东西 | 母英国短毛猫想要食物 | Wikimedia Commons: `File:Weibliche Britisch Kurzhaar will Futter C1277 MIAUEN.wav` | CC BY 4.0 |
| `pleading_to_go_out.mp3` | 请求出门 | 猫请求出去 | Wikimedia Commons: `File:Meow of a pleading cat.oga` | Public Domain |
| `impatient_to_go_out.mp3` | 出门前不耐烦 | 猫知道要出门散步，表现得不耐烦 | Wikimedia Commons: `File:GettingOutImpatient.ogg` | Public Domain |
| `basic_meow.ogg` | 基础喵叫 | 通用猫叫样本 | Wikimedia Commons: `File:Felis silvestris catus.ogg` | CC BY-SA 2.5 |
| `siamese_meow.wav` | 暹罗猫叫 | 暹罗猫 meow 示例 | Wikimedia Commons: `File:Meow of a Siamese cat - freemaster2.wav` | CC0 |
| `purring_short_mimi.ogg` | 短呼噜 | Mimi 的短促呼噜声 | Wikimedia Commons: `File:Cat purring (Mimi).ogg` | CC BY-SA 3.0 |
| `purring_long.ogg` | 长呼噜 | 持续呼噜声 | Wikimedia Commons: `File:Felis silvestris catus purrs.ogg` | CC BY-SA 3.0 |
| `angry_hiss.ogg` | 生气警告 | 生气的猫发出嘶嘶声 | Wikimedia Commons: `File:Cat hissing - Zabuhailo.wav` | CC0 |
| `in_heat_call.mp3` | 发情呼叫 | 发情期母猫的持续叫声 | Wikimedia Commons: `File:Audio file of cat meowing.ogg` | CC BY-SA 4.0 |

## 使用建议

- 可把这些文件映射为应用内的意图样本，如“饥饿”“想出门”“不耐烦”“亲近放松”“警告防御”。
- 若只想先做干净试听与演示，建议优先使用 `clean_meow_mixkit.mp3`、`hungry_meow_mixkit.mp3`、`attention_meow_mixkit.mp3`。
- 带 `CC BY` 或 `CC BY-SA` 的素材在对外发布时需要保留署名与原许可信息。
- `Mixkit` 素材需遵守其站点许可条款，适合先用于原型和应用内演示前的资源筛选。
- 若后续用于 App 内正式内置资源，建议再统一转码到项目目标格式，如 `m4a` 或 `caf`。

## 备注

- 本次下载过程中，部分 Wikimedia 转码链接会触发限流，因此目录内同时保留了 `mp3`、`ogg`、`wav` 三种格式。
- 社交平台视频里的猫叫虽然可能更生活化，但通常缺少可直接复用到 App 资源中的明确授权，因此这一轮没有直接采用社交平台抓取音频作为正式资源。
- 当前样本更适合用作 MVP 演示、标签映射与试听，不代表严谨的行为学标注数据集。
