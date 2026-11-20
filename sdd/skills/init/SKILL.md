---
name: init
description: 当用户要在此项目建立/启用 sdd 治理（「初始化」「在这个项目用 sdd」）；bootstrap 发现需治理而无治理痕迹；重跑初始化（模板对齐）；换机重建；治理文档领先于插件版本时（只提示升级插件，不动手）。
---

# sdd:init — 建立治理

在目标项目落一套**纯 Markdown 治理树**（零可执行痕迹），或对已有治理树做升级/重建。治理树是其他一切 sdd 技能的地基：没有它，intake 无处记录，start 无任务可领。

## 流程

### 1. 发现（单点检查）

检查 `<项目根>/.mira/sdd/REGISTRY.md`；当前 sdd 版本取自 `.claude-plugin/plugin.json`：

- **无** → 第 2 步新建
- **有，schema 与当前 sdd 版本一致** → 报告「治理文档与插件同版」，退出
- **有，schema 低于当前 sdd 版本** → 模板对齐（第 3 步）。注意：现场恢复类的路过（bootstrap 路由的「发现治理根」）只**报告**版本差，不动手；只有用户显式重跑 init 才对齐
- **有，schema 高于当前 sdd 版本**（治理文档来自更新的插件）→ 宽容读取照常；提示 `claude plugin update sdd`，升级后重跑 init 完成对齐
- **schema 缺失或认不出（非版本号形）** → **停下问人**：向用户列出现存内容，问清来历后按其指示处置；不得删除、不得覆盖、不得当空目录处理

### 2. 新建

治理根固定为 `<项目根>/.mira/sdd/`。

- **sdd-kind 默认 standalone**：项目 `.git/info/exclude` 追加 `.mira/sdd/`（不随项目仓提交、不推送），并在 `.mira/sdd/` 内嵌独立 git 仓（自有提交历史，可推私有远端备份）——公开面零治理痕迹。**不可变字段**：要 inline（随项目仓提交、团队可见）就在 init 首次确认时说一声，此后不可切换
- 其余**回报时逐项列出全部可选值，默认值在前**：`versioning: semver / calver`（语义化版本 / 日历版本，不可切换）、`mode: unattended / interactive`（unattended：各阶段由 Agent 推进，verification=auto 时从受理到发布无需值守；interactive：逐阶段与用户对话；项目过程中可改）、`verification: auto / manual`（验收执行者：系统自动验收 / 用户验收，项目过程中可改）
- 落 REGISTRY.md（模板 `sdd:templates/tmpl-registry.md`，规则见 `references/governance-files.md`）：配置区按确认值 + 空提案表；INTENT/JOURNAL/AMENDMENTS 不落盘——首写时按模板整建（存在 ⇔ 至少一条真实条目）
- 写项目 `.git/info/exclude`：`.export/` 与 `.worktrees/`（两形态都写）；`.mira/sdd/`（仅 standalone）。项目尚无 `.git` 时跳过并报告一句，重跑 init 时补写
- 回报：治理根路径、形态、文件出生顺序（REGISTRY 必在，其余首写出现）；并声明「卸载不丢数据、不锁定格式——治理树是纯 Markdown，可读、可审计、可迁移；继续治理流程需 sdd 插件在位」

### 3. 模板对齐（schema 低于当前 sdd 版本）

从治理树本身提取结构，与当前模板比对：

- **无结构差异** → schema 写为当前 sdd 版本，结束
- **有差异** → 先查治理文件无未提交改动（standalone 查内嵌仓，inline 查项目仓治理路径）——有则停下请用户先处理；干净则 git 历史即回滚点，改坏可 restore。然后整文件重排：
  - 数据逐项填入当前模板形状：原字段值逐项搬运，新字段留空或默认，表格行补空单元格保持表格完整，树中多余内容原样保留并在回报中列出，搬不动的停下问
  - **先查再补**：应用前先看目标是否已具备该结构，已具备则跳过——中断重跑不重复应用
  - JOURNAL 与 AMENDMENTS 的既有条目不重排（此后新条目按当前模板追加）；完结提案不动
- 存量迁移（1.0.x 座位制树）：未替换的占位条目/行移除、INTENT 旧参照注释清除、真实条目原样保留、清扫后仅剩 H1 的文件删除、REGISTRY 占位行移除
- 完成：schema 写为当前 sdd 版本；standalone 在内嵌仓提交一版，inline 治理改动留在工作区，提醒用户随项目仓提交

### 4. 重建（standalone 项目新 clone 后治理根缺失）

inline 项目 clone 后 `.mira/sdd/` 随仓在，无需重建。standalone 项目 clone 后目录缺失（未被父仓跟踪），属预期：

- 问用户：从私有远端恢复内嵌仓（clone 进 `.mira/sdd/`），还是新开
- 补写 `.git/info/exclude` 两行：`.export/` 与 `.mira/sdd/`
- 恢复/新建后核对 schema（低于当前 sdd 版本就按第 3 步模板对齐）
- 提醒备份手段：standalone 治理的内嵌仓推私有远端；向用户说明「这是重建，不是损坏」

## 常见误区

| 你会想 | 事实 |
|---|---|
| 「项目还小，先随便建个目录记一下」 | 即兴形状的治理树无法跨项目对照；形状唯一源是 sdd:templates/tmpl-*.md，首写按模板整建 |
| 「治理根放项目根 `sdd/` 更显眼」 | 位置固定 `.mira/sdd/`——发现是单点检查，位置漂移会让所有技能扑空 |
| 「发现旧版残留，直接清掉重建最干净」 | 残留可能是用户数据；无 schema 残留必须停下问 |
| 「模板对齐要重写整个 REGISTRY」 | 重排的是形状；数据逐项搬运，不认识的保留并报告 |
| 「schema 字段不重要，忘了写也没事」 | 没有 schema，init 无法判断治理文档与插件的版本关系；缺失 = 停下问人 |

## references

- `governance-files.md` — 治理文件规则：布局与出生顺序、配置区字段、提案表状态闭集、编号与状态词表、条目规则（含判直做留痕）、看板读法（模板在 `sdd:templates/tmpl-*.md`）
