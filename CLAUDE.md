# CLAUDE.md

本仓库是插件市场 mira-plugins；收录的 sdd 插件（安装名 sdd@mira-plugins）是需求治理技能集（纯技能，会话开始自动注入）。

## 布局

- `sdd/` — 插件本体：`hooks/`（SessionStart 注入脚本）、`skills/`（bootstrap 元技能 + init/intake/spec/start/accept/export）、`templates/`（七个治理文档模板）、`tests/`
- `docs/sdd-plugin-design.md` — 设计文档，唯一依据；改行为先改它，再落技能
- `.claude-plugin/marketplace.json` — 插件清单

## 核心模型

意图 `I-XXX` 经澄清成形拆分为提案 `P-XXX`（I 包含 P）；定规格之前的讨论过程留痕于探索底稿 `JOURNAL.md`（条目按归属标 `[I-XXX]` 或 `[P-XXX]`，追加不重写）；两个行为开关独立：`mode`（推进方式）× `verification`（验收执行者）。完整设计见设计文档。

## 铁律

- **不造词**：日常词够用就不造词，不把简单机制包装成「体系感」名词、非必要不用比喻装饰
- **模板唯一源**：治理文档模板在 `sdd/templates/`（规则在 `sdd/skills/init/references/governance-files.md`），验收契约规则在 `sdd/skills/spec/references/contract.md`，分支拓扑在 `sdd/skills/start/references/git-flow.md`——改模板即全局生效，任何技能不得另立副本
- **设计变更先改设计文档**，再落技能；治理形态/规则的每次修订在本仓 `CHANGELOG.md` 留一行
- **插件版本号只落两处**：`sdd/.claude-plugin/plugin.json` 与根 `marketplace.json`，同步手改；新增含版本号的文件必须在此登记
- **文件分读者**：`sdd/` 内的规则与模板写给 Agent——从正面阐述，无需赘述防御性/解释性补充；README/CHANGELOG/设计文档写给用户，可展开解释；治理文档（治理根下）是目标仓库的治理资产、给用户审阅，Agent 按模板读写维护；跨技能与跨目录的插件文件引用，技能与 references 内用 `sdd:` 逻辑地址（`sdd:` 即插件根——开发侧 = 仓内 `sdd/`，运行时 = 插件安装根，`CLAUDE_PLUGIN_ROOT` 所指），后接插件根相对路径；开发侧文档用仓根真实路径
- **双身份**：`P-XXX`/`I-XXX` 治理侧，codename 公开侧（分支名、worktree 目录）；P / I 的编号全局递增，不复用、不重排；提案按依赖顺序发号——被依赖的先号，发号后新发现的依赖经提案表依赖列兜序
- **文档自足**：不引用仓库外的路径或文档

## 验证

```bash
bash scripts/check.sh   # 统一门禁入口：validate / 测试 / markdownlint / sdd: 引用完整性 / 模板形状守卫（依赖 node、npx；markdownlint 禁用 MD013 MD060——对中文不适用）
```

行为验收：干净目录执行 `claude -p --max-turns 12 --plugin-dir ./sdd "一句话需求"`，首反应必须是治理行为（init 建议或 intake 澄清），不得写代码。

## Git 纪律

- 提交信息：标题动词开头；正文不折行，条目一行一个
- 提交与推送前统一门禁全绿

## 开发迭代

`claude --plugin-dir ./sdd` 单会话加载（可与其他 `--plugin-dir` 并传），改完重开会话生效。

## 词汇表

| 中文概念 | 标识 | 含义 | 错误示例 |
| --- | --- | --- | --- |
| 治理根 | `<项目根>/.mira/sdd/` | 治理树所在目录：REGISTRY 必在 + `proposals/`，INTENT/JOURNAL/AMENDMENTS 首写出现 | 账本 |
| 登记簿 | REGISTRY.md | 执行维度登记：提案表与治理配置 | 账本、总表 |
| 意图池 | INTENT.md | 需求维度登记：全部意图的原话、边界与去向 | 构想池、台账 |
| 探索底稿 | JOURNAL.md | 定规格前澄清、探索、选定与否决的过程留痕，追加不重写 | 日志、留痕 |
| 修正登记 | AMENDMENTS.md | 已生效方案被推翻或取代时的登记 | |
| 意图 | `I-XXX` | 受理的模糊需求，澄清成形后拆分为提案 | 需求、构想 |
| 提案 | `P-XXX` | 经规格定形的实施单元，含 SPEC / DESIGN / TASKS 三文件 | |
| 任务 | `P-XXX-TNN` | 提案内一次提交粒度的实现步骤 | |
| 代号 | codename | 具体提案的公开侧名称（用作分支名、worktree 目录），与提案的对应关系登记在 REGISTRY 提案表中 | |
| 受理 | intake | 需求进入治理 | |
| 模板 | `sdd/templates/tmpl-*.md` | 治理文档的结构参照：写入时取用，占位不落盘，改即全局生效 | |
| 推进方式 | `mode: unattended / interactive` | 阶段推进要不要人机交互：unattended 无需值守，interactive 每阶段与用户交互 | 模式、阶段衔接 |
| 治理形态 | `sdd-kind: standalone / inline` | 治理树存放形态：standalone 不随项目仓提交、内嵌独立 Git 仓（可本地私有，也可推私有远程仓库）；inline 随项目仓提交 | |
| 模式 | `schema` | 治理结构的版本戳：值取自 sdd 版本，模板对齐判据 | 治理规范、锚点 |
