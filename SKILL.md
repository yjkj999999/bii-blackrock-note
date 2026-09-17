---
name: bii-blackrock-note
description: 把 BII 范式的个股研判简报（A4 横向 · 封面+9 正册+12 增补册 · 左文字栏+右图表栏）整体重定向为「贝莱德智库（BlackRock Investment Institute）风格」，并一条龙产出 pptx + pdf + html 三件套。核心能力：① 全局色板重定向（35 类源色 → 品牌令牌，含 7 槽分类色相保真）；② 结构装饰注入（左侧黑书脊 / 顶部黑色色带 / 品牌黄书签 / 黑色持仓面板 / 黄头摘要框 / 三段式「免责声明｜页码｜文件编号」页脚）；③ 装饰件零净增量约束——保证 22 页版式不被挤爆；④ 七门体检，含「可见文本逐字零改动」比对。Use when 用户要求「把这份个股简报做成贝莱德智库风格」「按贝莱德智库的版式出 pptx/pdf/html」「给 BII 简报换个品牌风格」，或需要把已有 BII HTML 交付成三格式。
homepage: https://github.com/yjkj999999/bii-blackrock-note
author: 王东杰 (Wang Dong Jie) · yjkj999999
license: MIT-0
version: 1.0.1
agent_created: true
read_when:
  - 用户要求把 BII / 个股简报做成贝莱德智库（BlackRock）风格
  - 用户要求某份 BII 简报同时交付 pptx + pdf + html
  - 用户说「换个品牌风格」「按这种版式再来一份」
  - 需要给已有 BII HTML 加品牌色带 / 书签 / 文件编号页脚
metadata:
  openclaw:
    emoji: 🖤
    version: "1.0.1"
---

> **版本谱系**：本技能自 v1.0.1 起**取代** `brand-pdf-deck-replica`（已退休）。
> 后者面向「复刻**外部**品牌 PDF + 反解图表数值」；本技能面向「自家 BII 简报换品牌皮 + 三格式交付」，
> 是把前者的**视觉体系与交付管线**并进 BII 内容引擎后的合并产物。两份并存会造成路由歧义，故只保留本技能。

# BII 简报 × 贝莱德智库风格（内容不动 · 只换视觉体系）

产出：**同一份 22 页个股简报**，套上贝莱德智库的视觉语言，并同时交付 `pptx + pdf + html`。

本技能是「**内容引擎 + 视觉层**」的组合，不是从零画报告：

| 层 | 来自 | 职责 |
|---|---|---|
| 内容与版式骨架 | `bii-equity-note` | 22 页结构、双栏骨架、5 canvas + 12 SVG 图表、全部正文与数据 |
| 视觉体系 | 本技能 | 品牌令牌、结构装饰、三格式交付、七门体检 |

> **不要**用本技能生成一份新简报的内容。内容先由 `bii-equity-note` 出 HTML，再用本技能上妆。

## 依赖

| 依赖 | 用途 |
|---|---|
| `bii-equity-note` | 产出源 BII HTML（本技能的输入） |
| `html-to-pdf-cdp/scripts/render_html_pdf.sh` | CDP 出 PDF（含 canvas 墨量验收） |
| `html-to-pdf-cdp/scripts/measure_pages.js` | 由 `inspect_pages.sh` 调用，逐页量高度定位溢出 |
| poppler（`pdfinfo/pdftotext/pdftoppm`） | 页数尺寸核对、备注全文、位图铺底 |
| python-pptx + Pillow | PPTX 封装 |

## 资产与脚本

```
bii-blackrock-note/
  assets/
    br_tokens.json          # 品牌令牌 + 色板映射表（★单一来源，脚本一律从这里读）
    blackrock-theme.css     # 结构装饰层（不含映射表，只管新增装饰）
  scripts/
    theme_inject.py         # ① 色板重定向 + 装饰注入（三条硬断言）
    inspect_pages.sh        # ② 逐页版式体检（定位溢出页 + 可选截 PNG）
    mkpptx.py               # ④ PDF → PPTX（满幅位图 + 演讲者备注）
    check_br.py             # ⑤ 七门体检
    pipeline.sh             # 一条龙（①→⑥）
  examples/
    sz001337_case.md        # 实跑记录（四川黄金 · 22 页）
```

---

## 一条龙（最常用）

```bash
bash ~/.workbuddy/skills/bii-blackrock-note/scripts/pipeline.sh \
  ~/Desktop/bii_sz001337_20260917.html \
  ./out
# → out/bii_sz001337_20260917_blackrock.{html,pdf,pptx}
```

分步执行见下。

## 步骤 1 · 注入（色板重定向 + 结构装饰）

```bash
PY=~/.workbuddy/binaries/python/envs/default/bin/python     # 需要 python-pptx
$PY ~/.workbuddy/skills/bii-blackrock-note/scripts/theme_inject.py \
  src.html out.html --report inject.json
```

做两件事，**其余字节不变**：

**① 全局色板重定向**（35 类源色，作用于 CSS / 内联样式 / SVG fill / canvas JS 全区域）

| 源色 | → 品牌色 | 语义 |
|---|---|---|
| `#FFB500` | `#FFCE00` | 品牌黄（贝莱德第一识别色） |
| `#C62828` | `#CE2A0A` | 涨 / 品牌红 |
| `#2E7D32` | `#00704A` | 跌 / 品牌绿 |
| `#2E6FAF` | `#3F6FA6` | 分类槽·钢蓝 |
| `#2E9E8F` | `#008B5C` | 分类槽·绿 |
| `#E07B39` | `#E8892B` | 分类槽·橙（MA5） |
| `#8E44AD` | `#9062BC` | 分类槽·紫（MA60） |
| `#FBE8C4 / #FAC775 / #EF9F27` | `#FFF3C4 / #FDDC6B / #F5C518` | 热力图暖色阶 |
| …（其余 27 类见 `br_tokens.json`） | | |

**② 结构装饰注入**

- `data-br-tab` 属性 → 每页顶部**品牌黄书签**（文案自动取页眉 `.rh-l`）
- `<span class="br-code">` → 每页页脚**文件编号**（自动读源件的「报告编号」，拼成 `BII-<报告编号>`）
- 封面品牌行改写 + 封面页脚加**版式来源声明**
- 主题 CSS 注入 `</head>` 之前

**三条硬断言**（不满足直接非零退出，不留半成品）：section 数 == 期望页数；每个页脚恰好 2 个 `<span>`；注入后无源色残留。

## 步骤 2 · 逐页版式体检（★装饰件最容易在这一步翻车）

```bash
bash ~/.workbuddy/skills/bii-blackrock-note/scripts/inspect_pages.sh out.html [png目录]
```

> 本脚本是**薄委托**，实际执行 `html-to-pdf-cdp/scripts/measure_pages_selfhost.sh`
> （Chrome 必须起在**同一个前台进程**里——受限沙箱会回收后台常驻 Chrome，
> 直接跑 `measure_pages.js` 会报 `fetch failed`）。

输出 `over` 列即「超出纸高多少」。**A4 横向的溢出阈值是 794px**（210mm）。
源稿通常刚好卡在 793.7px（= `min-height:210mm`），所以**任何正增量都会让那页多出一张纸**。

### 装饰件零净增量铁律（v1.0.0 血泪）

在一份 22 页源稿上首次注入时，三页溢出（+16.2 / +7.4 / +7.4px）。原因是装饰件引入了**行盒**：

| 坑 | 症状 | 正解 |
|---|---|---|
| **`display:inline-block` 胶囊标签** | 单这一项就 +7px | 行盒高 = `max(父级 strut, 标签高)`，父级 strut = 10.5px×1.66 ≈ 17.4px，远高于标签本身。**保持 `display:block` + `width:fit-content`** |
| **页脚改两行网格** | 每页 +4.5px | 文件编号改 `position:absolute; top:100%`，落进页面下内边距，行数不变 |
| **给块加 `border-bottom`/`padding-bottom`** | 每个块 +4px（3 个块 +12px） | 只改颜色，不加边线；或用 `box-shadow: inset` 代替真实边框 |

净效果：22 页全部回到 793.7px，`colL` 甚至比源稿小 4~6px。

> **不要**靠缩字号或减内边距去硬塞。先按上表把装饰件做成零增量。

## 步骤 3 · 出 PDF

```bash
bash ~/.workbuddy/skills/html-to-pdf-cdp/scripts/render_html_pdf.sh out.html out.pdf 3200 css
```

**不要加 `SKIP_VERIFY=1`**：本版面有 5 个 canvas，脚本自带的墨量验收是有效的真门（`ratio` 应落在 0.03~0.7）。

## 步骤 4 · 封 PPTX

```bash
~/.workbuddy/binaries/python/envs/default/bin/python \
  ~/.workbuddy/skills/bii-blackrock-note/scripts/mkpptx.py out.pdf out.pptx 200
```

- 幻灯片尺寸**自动探测** PDF 首页尺寸（本例 841.92×594.96pt = 11.69×8.26in），1:1 不缩放
- 每页 **200dpi 位图满幅铺底** —— 自绘 SVG/canvas 图表无法用 python-pptx 原生表达
- 每页写入**演讲者备注**（`pdftotext` 全文，剔除页脚固定件）→ PPTX 仍可检索、可复制文字
- **交付时必须向用户说明这一取舍**：要改字请改 HTML 重出，不要试图在 PPT 里改

## 步骤 5 · 七门体检

```bash
$PY ~/.workbuddy/skills/bii-blackrock-note/scripts/check_br.py out.html \
  --src src.html --pdf out.pdf --pptx out.pptx --pages 22
```

| # | 门 | 判据 |
|---|---|---|
| 1 | 结构完整性 | section 数 == 书签数 == 页脚编号数 == 期望页数 |
| 2 | 品牌令牌/装饰结构 | `br_tokens.json` 的 `required_structures` 全部命中 |
| 3 | 源色板无残留 | `forbidden_after_inject`（`#FFB500/#C62828/#2E7D32`）计数为 0 |
| 4 | 分类色相可区分 | 7 槽分类色一个不少（防止色相塌缩） |
| 5 | **内容零改动** | 可见文本词元多重集比对：产物只允许多出「本次注入的文案词元」 |
| 6 | PDF 页数/尺寸 | 页数 == 22；`841.92×594.96pt` |
| 7 | PPTX 结构 | 页数、宽高、每页恰 1 张图、备注非空 |

**门 5 是本技能的核心价值**。它把「只换视觉、不动内容」从口号变成可执行判据：任何正则误伤正文或图表脚本都会被它抓住。
白名单**不写死**，而是从 DOM 反推本次真正注入了什么（品牌行 / 风格声明 / 页脚编号）——
写死白名单只会掩盖真正的注入事故（v1.0.0 就是这么误报的）。

## 交付

用 `present_files` 一次给出：**PDF（第一顺位）→ PPTX → HTML**，并附上七门体检结果。
正文里必须带上：标的、报告期、**版式来源声明**（本报告为独立分析件，非贝莱德公司出品），以及免责声明。

---

## 常见故障速查

| 症状 | 根因 | 处置 |
|---|---|---|
| PDF 页数 > section 数 | 装饰件把某页挤爆 | `inspect_pages.sh` 看 `over` 列，按「零净增量铁律」改 CSS |
| 色板映射后两个系列色看起来一样 | 7 槽分类色塌缩成 5 色 | 查 `br_tokens.json` 的 `_categorical_note`；分类槽必须保留独立色相 |
| 胶囊标签一加就溢出 | `display:inline-block` 撑高行盒 | 改 `display:block; width:fit-content` |
| 页脚文件编号被裁掉 | 绝对定位超出页面下内边距 | 确认 `.page{padding-bottom}` ≥ 8mm；`top:100%` 落点应在内边距内 |
| 注入后 PDF 还是旧版面 | Chrome 复用旧 profile | 用 `render_html_pdf.sh` 自起模式（每次全新 profile） |
| 后台起 Chrome 量页面失败 | 沙箱回收后台进程 / GPU 进程 FATAL | 用 `inspect_pages.sh`——它把 Chrome 放在**同一个前台进程**里并 trap 收尾 |
| 门 5 报「产物多出非注入词元」 | 正则误伤正文，或注入文案改了没更新白名单 | 看 `bad_extra` 具体词元；**不要**直接放宽白名单 |
| 图表全白 | HTML 里没写进图表，或脚本被破坏 | grep 产物 HTML 的 `<canvas>`/`<svg>` 数量应与源件一致 |

## 与其他技能的关系

- 上游：`bii-equity-note`（出内容）→ 本技能（上妆 + 三格式交付）
- 已被本技能取代：`brand-pdf-deck-replica`（v1.0.1 起退休，已从 ClawHub 下架）——
  其「复刻外部品牌 PDF + 反解图表数值」的能力未并入本技能，如需该能力请从
  GitHub 历史版本取用，不要再与本技能并列挂在技能根目录下。
- 下游：`present_files` 交付

## 发布

```bash
bash ~/.workbuddy/skills/bii-blackrock-note/scripts/publish.sh          # 干跑，只体检
bash ~/.workbuddy/skills/bii-blackrock-note/scripts/publish.sh --go     # 真发布（ClawHub + GitHub）
```

发布目标：

| 渠道 | 标识 | 说明 |
|---|---|---|
| ClawHub | `bii-blackrock-note` | 作者 `yjkj999999`；若旧 slug 存在会自动 `hide` |
| GitHub | `yjkj999999/bii-blackrock-note` | SSH `git@github.com:...`（API 走 `--noproxy '*'` 直连） |

> **网络注意**：本机 `https_proxy` 对 `api.github.com` 的 CONNECT 会 502，
> 但**直连可用**。脚本里所有 GitHub API 调用都带 `--noproxy '*'`。

## 本地许可

MIT-0 · Copyright (c) 2026 王东杰 (Wang Dong Jie) · yjkj999999
