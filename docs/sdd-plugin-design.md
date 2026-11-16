# sdd 插件设计文档

- 日期：2026-10-13
- 状态：1.0.0 设计定稿，已实现（纯技能集，零机械资产）
- 机制蓝本：obra/superpowers（bootstrap 注入架构）

---

## 1. 定位与设计原则

**定位**：[obra/superpowers](https://github.com/obra/superpowers) 是一套软件开发方法论（15 个技能 + 会话开始自动注入元技能 bootstrap 的插件形态，MIT、零运行时依赖），它管「怎么把一件事做对」——技能链覆盖单需求流水线的工程执行（头脑风暴 → 设计 → 计划 → TDD 执行 → 评审 → 收尾）。本插件沿用这套插件形态，管的是另一层——「一堆事之间谁先谁后、承诺过什么、凭什么算完」，即**需求治理层，只做 obra/superpowers 缺口的增量**。

| # | 原则 | 内容 |
|---|---|---|
| P1 | 治理层增量 | 关闭蓝本八缺口（需求实体、跨会话状态、插单纪律、验收契约、并发调度、变更治理、发布工程、治理体系本身）；执行机制零重建、零复制、零链取 |
| P2 | 纯技能载体 | 无 slash commands。纪律自动性是产品本体，只有 skill 能在用户没想到的时刻生效；命令是可后加的糖 |
| P3 | 切分依据 | 技能 = 有独立触发时刻的单位，从「无技能时 Agent 在哪走样」反推；不继承旧流程、不抄蓝本清单 |
| P4 | 横切两层解 | 横切规则进 bootstrap（注入常驻，一行一条「必须」）；程序与格式进对应阶段技能的 references（按需加载） |
| P5 | 同意链 | 每个有后果的写入必须追溯到已登记的用户意图。首次 init 对仓库的第一个写入须显式确认；之后一切自动化是这次确认的委托 |
| P6 | mode 单一职责 | mode 只决定阶段如何推进——interactive 每阶段与用户交互（探索即对话），unattended 无需值守；**文件、门禁、顺序等机制在两种取值下完全一致** |
| P7 | 公开面零治理 | 治理信息只住在治理根。README、CHANGELOG、git log、源码注释、分支名等一切公开面零治理痕迹；inline 形态下 sdd/ 随仓是唯一例外 |
| P8 | 双身份 | `P-XXX` 治理侧身份（只活在治理数据内）、`codename` 公开侧身份（分支名等公开面用）；映射存 REGISTRY |
| P9 | 两个开关相互独立 | mode（推进方式）× verification（验收执行者），2×2 全部合法可组合 |
| P10 | 懒加载 | SKILL.md 主流程精瘦；规格、模板、程序按步骤放 references 按需读取 |
| P11 | 编号即序 | 发号保证发号时点被依赖提案先号、任务拆分被依赖者排前；依赖显式登记于 REGISTRY 依赖列（静态声明、调度联查、不清除）——发号后新发现的依赖由联查兜序，队列序 = 依赖过滤后的编号序；登记与补登带环检测（游走非完结依赖，回自身即环 → 停下问，环属声明错误不自动解） |
| P12 | 独立自足 | 本插件不是 obra/superpowers 的继承，也不是它的超集——两者是不同层的独立插件（它管工程执行，本插件管需求治理），可并存、互补、各自演进。技能零复制、零链取；缺什么自己原创，不靠借用补齐 |
| P13 | 护栏靠来源链 | 误触发防护不靠「问」，靠追溯链：intake 是一切动作型输入的第一响应者（先过三问分流）；spec/start 不作入口（显式点名除外） |
| P14 | 宽容读取 | 治理文件遇不认识的字段、节与值：不删、不改、照常工作 |

## 2. 仓库布局（两层分发）

```text
mira-plugins/                        # 仓库 = marketplace
├── .claude-plugin/marketplace.json  # 插件清单，source 指向 ./sdd
├── docs/                            # 设计文档（本文件）
└── sdd/                             # 插件本体
    ├── .claude-plugin/plugin.json   # name: sdd，版本独立演进（初始 1.0.0）
    ├── templates/                   # 七个治理文档模板（tmpl-registry 等，小写 tmpl- 前缀）
    ├── hooks/hooks.json             # SessionStart 事件，matcher: startup|clear|compact
    ├── hooks/session-start          # bash 注入脚本（无扩展名）：读 bootstrap/SKILL.md 全文，
    │                                #   包 <EXTREMELY_IMPORTANT> 以嵌套 additionalContext 输出
    ├── skills/
    │   ├── bootstrap/SKILL.md       # 元技能（目录须与 session-start 的 SKILL_REL 一致）
    │   ├── init/  intake/  spec/  start/  accept/  export/   # 各含 SKILL.md + references/
    └── tests/test-session-start.sh  # hook JSON 形状自测（三形状分支 + 字段互斥断言）
```

marketplace 当前只登记 sdd 一个插件。版本登记纪律：版本号只落在 `sdd/.claude-plugin/plugin.json` 与根 `marketplace.json` 两处，手改同步；新增含版本号的文件必须在此登记。

## 3. 治理结构

### 3.1 形态与发现

- **治理根（两形态同位）**：`<项目根>/.mira/sdd/`——`.mira` 为插件目录族命名空间，sdd 占用 `.mira/sdd`
- **inline**：`.mira/sdd/` 随项目仓提交（团队可见）
- **standalone**：项目 `.git/info/exclude` 追加 `.mira/sdd/`（不随项目仓提交、不推送）+ 在 `.mira/sdd/` 内嵌独立 git 仓（自有提交历史，可推私有远端备份）；公开面（git 数据、log、远端）零痕迹
- **治理仓提交纪律**（standalone）：一笔提交只含一个关注点——状态迁移即时提交，探索、回填等过程性写入在一次响应收口时合为一笔；开始写新关注点前先提交上一个关注点的未提交改动
- **发现**（所有技能共用）：单点检查 `<项目根>/.mira/sdd/REGISTRY.md`
- 项目尚无 `.git` 时：exclude 写入跳过并报告，重跑 init 补写
- 卸载插件零影响：治理树是纯 Markdown，无任何可执行痕迹
- 路径引用语法：跨技能与跨目录的插件文件引用，技能与 references 内用 `sdd:` 逻辑地址——`sdd:` 即插件根（开发侧 = 仓内 `sdd/`，运行时 = 插件安装根，`CLAUDE_PLUGIN_ROOT` 所指），后接插件根相对路径；开发侧文档（本文件、CLAUDE.md、CHANGELOG）用仓根真实路径；技能内同目录引用用裸文件名

### 3.2 文件与语义（规则唯一源：`init/references/governance-files.md`；模板：`sdd/templates/`）

```text
<治理根>/
├── REGISTRY.md      # 执行维度：提案表（P-XXX、intent、codename、内容、依赖、状态）+ 配置 frontmatter；schema 版次
├── INTENT.md        # 需求维度：意图池，全部意图一个区块（I-XXX、短标题、原话、边界结论、状态、P 表格）
├── JOURNAL.md       # 探索底稿（条目槽位化）：澄清、方案成形（选定与否决）、拆分依据、提案细化探索
├── AMENDMENTS.md    # 方案修正登记：已生效方案被推翻/取代时记（为什么换、换成什么）
└── proposals/       # 工作产物区：只放提案目录
    └── P-XXX/       # 每提案一目录（治理侧身份命名；codename 只用于公开面，见 P8）
```

- 布局规则：治理根根上只放常驻四件，`proposals/` 只放提案目录
- 治理文档不写本机信息：仓库外的本机信息（路径、主机名、用户名等）不入文档，随仓迁移后不成立且泄露本机环境；引用项目内资源用项目内相对路径；用户原话逐字引用不受此限
- **I 包含 P**：一个意图（I-XXX）经澄清成形拆分为 1..n 个提案；意图是需求全程的源头（原话逐字保留），INTENT 区块只存事实（原话、状态、边界结论、拆分出的 P 表格），永不承载过程文本；提案归属登记在 REGISTRY 提案表 `intent` 列（与 P 表格同次写入；兄弟查询与聚合走 REGISTRY）
- **spec 之前的过程留痕只在一处：JOURNAL**（`[I-XXX]` 澄清/成形/拆分 + `[P-XXX]` 提案细化，双命名空间；决策——选定、否决、拆分——必须逐条留痕，不留痕即流程违规；条目正文按固定槽位落——已知信息与约束/成功标准/候选方案/开放问题/否决记录/拆分依据/形态结论，按条目类型齐备；追加不重写）
- 提案目录内部三文件（**带提案号前缀**，frontmatter 同构 `id`/`type`，H1 `# P-XXX <标题>`）：`P-XXX-SPEC.md`（frontmatter 另含 `version` 提案级 + `intent: I-XXX` 回链；背景 + 范围内外 + 边界与异常 + 验收标准表）/ `P-XXX-DESIGN.md`（方案概述 + 接口/数据/关键流程 + 技术决策 + 否决备选留档）/ `P-XXX-TASKS.md`（任务表 + 完成任务登记 commit hash）——前缀使文件在跨提案并列场景（编辑器标签、搜索、聚合）自标识；按阶段懒加载：start 只读 TASKS，accept 只读 SPEC 契约表
- 格式蓝本：frontmatter、节结构、JOURNAL 槽位借鉴 sdd@star-plugins / moss-mall 实证模板（不冲突全量采）——每个实体只有一种合法形状，格式即执法，封死落笔自由发挥
- 导出派生物不在治理根：落项目根 `.export/`（见 5.4）
- 命名规则：容器单数（REGISTRY/INTENT/JOURNAL）、条目集复数（AMENDMENTS）
- 模板占位区块（条目头、样例行）是首个同类实例的座位——首实例就地替换占位区块，其后同类追加；占位不含数据，替换不算重写
- REGISTRY 不复写任务明细（单源在 TASKS.md）；现场恢复 = 读 REGISTRY + INTENT + 在途提案的 TASKS.md
- 状态词表（闭集）：提案 `立项 → 待实现 → 待验收 → 验收中 → 完结`，旁路 `挂起`；意图 `记录 → 澄清中 → 已拆分 → 完结`（完结由名下提案推导回写），旁路 `已否`
- 编号：`I-XXX` 意图（全局递增永不复用）、`P-XXX` 提案（全局唯一 = 目录名，按依赖顺序发号，永不复用）、任务 `P-XXX-TNN`（提案内两位定宽递增；NN/XXX 为占位写法非定宽，超宽自然延展）

### 3.3 REGISTRY 配置区（frontmatter 承载；默认值在前，枚举第一个值即默认）

```text
schema: 1.0.0                        # 治理结构的版本戳，值取自 sdd 版本（模板对齐判据，见 5.3）
mode: unattended / interactive       # 推进方式：流水线 / 交互式（unattended 无需值守，interactive 每阶段与用户交互）
verification: auto / manual          # 提案末端验收执行者：系统自动 | 用户发起
versioning: semver / calver          # 目标项目发布版本方案（init 时定，公开契约）
sdd-kind: standalone / inline        # init 时定，不可变（默认 standalone）
```

### 3.4 AMENDMENTS 三分支（方案变更按所处阶段分流）

方案自**提案定稿**起生效——定稿起方案开始管事，此后的推翻与取代才涉及本登记；定稿前的变更自由。

| 方案所处阶段 | 处置 | AMENDMENTS |
|---|---|---|
| spec 期内（未 start） | 直接修改 + SPEC 头部 `version` 自增 | 否 |
| 开发中（start 后，未 accept） | 记 AMENDMENTS（为什么换：设计错误或发展不适用；换成什么）→ 提交丢弃、dev 分支删除 → 回退 spec 重来。**禁止边开发边改设计** | 是 |
| 已 accept 完结，被新提案以另一方案取代 | **旧提案冻结不动**（完结即历史文物）；新需求走 intake 正常立项；AMENDMENTS 记一笔 | 是 |

治理形态/规则本身（编号规则、状态词表、契约判据、目录形态）的演变走**插件仓库 CHANGELOG**，不进 AMENDMENTS。JOURNAL 只记探索过程，不记开发教训（教训并入 AMENDMENTS「为什么换」）。

## 4. 七技能清单

| 技能 | 类型 | 职责 | description（WHEN） |
|---|---|---|---|
| `sdd:bootstrap` | 自动注入（区别于按需调用的技能） | 元技能：纪律 + 路由 | 每个会话开始即生效（hook 整篇注入）——确立「任何响应前先查 sdd 技能」的纪律与路由表 |
| `sdd:init` | 阶段 | 建立治理 | 当用户要在此项目建立/启用 sdd；bootstrap 发现需治理而无治理痕迹；重跑（升级）；换机重建；治理版本低于插件时（只报告） |
| `sdd:intake` | 阶段 | 受理/分流/立项/探索 | 当用户抛来任何新需求、想法、变更愿望或需求文档；工作中途冒出新念头（插单）；提案被推进而技术形态未清（spec/start 退回补探） |
| `sdd:spec` | 阶段 | 写规格/契约/定稿/变更 | 当提案要写规格；要定或核对验收标准表；收到对已定稿提案内容的变更（升版） |
| `sdd:start` | 阶段 | 实现/流水线驱动 | 当要开始实现某个已定稿提案；任何写代码动作之前（显式点名提案/任务可直接进入）；实现中发现设计需推翻时 |
| `sdd:accept` | 阶段 | 验收/发布 | 当提案开发完成进入验收（unattended 自动推进；manual 等用户发起）；执行契约验证与证据核验；验收通过执行发布链 |
| `sdd:export` | 能力 | 知识导出 | 当用户要把项目知识导出给外部视角（「导出需求文档」「给新同事看现状」「写项目报告」）——只读零副作用 |

与 superpowers 15 技能零撞名，辖区互不重叠。

### 4.1 bootstrap（最后编写，纯组装）

- 组成：1% 规则 + 路由表 + 横切纪律行 + 现场恢复 + 首次确认措辞；目标 ≤ ~2-3k tokens（bootstrap 每会话每重置全额付费，越瘦越好）
- 路由表：

```text
动作型未分类输入（新愿望/想法/文档/插单） → sdd:intake（第一响应者，先过三问分流）
写规格/验收契约/变更升版                  → sdd:spec
写码/领任务/流水线推进                    → sdd:start（显式点名提案/任务可直接进入）
验收/发布                                 → sdd:accept
导出知识                                  → sdd:export
问进度/看板（只读聚合）                   → 读 sdd/skills/init/references/governance-files.md 看板读法
建立/升级/重建治理                        → sdd:init
发现治理根（任意会话开始）                → 先读 REGISTRY 恢复现场；
                                            schema 与插件版本不一致：按 5.3 模板对齐处置
无治理而要推进需求工作                    → sdd:init（首次写入等一句确认；
                                            已有治理按其 mode 行事）
```

- 横切纪律行（每条一行）：
  - 插单不打断——新想法只进 INTENT，当前工作永不自动转向
  - 无任务不写码——写码必须挂已定稿提案的任务
  - 开发中推翻已生效方案 → 必记 AMENDMENTS（程序：`init/references/governance-files.md`）
  - 提交前必过门禁（程序：`start/references/gate.md`，无论何时提交先读它）
  - 无证据不算完
  - 环境变更用户定——安装全局工具、搭建基础设施，用户决定
  - 行文说人话——不生造词、不自造缩略语，不生涩拗口；对话、文档、提交同一标准
- 命名：目录 `skills/bootstrap/`，SKILL_REL = `skills/bootstrap/SKILL.md`，frontmatter `name: bootstrap`，三处一致（组装步骤 3 验证项）

### 4.2 init

流程：

```text
1. 发现：单点检查 `<项目根>/.mira/sdd/REGISTRY.md`；当前 sdd 版本取自 `.claude-plugin/plugin.json`
   ├─ 无 → 2 新建
   ├─ 有，schema = 当前 sdd 版本 → 正常
   ├─ 有，schema 低于当前 sdd 版本 → 3 模板对齐（用户显式重跑 init 才动手；现场恢复路过只报告）
   ├─ 有，schema 高于当前 sdd 版本（治理文档来自更新的插件）→ 提示 claude plugin update sdd，
   │   升级后重跑 init 完成对齐；工作不受影响（按 P14 宽容读取）
   └─ schema 缺失或认不出（非版本号形）→ 停下问，不得当空目录处理
2. 新建：sdd-kind 默认 standalone（`.git/info/exclude` 隐藏 + 内嵌仓，公开面零治理痕迹；
   不可逆安全侧缺省——改 inline 仅在 init 首次确认时明说，此后不可切换）
   其余回报时逐项列出全部可选值，默认值在前：versioning=semver / calver（语义化版本 /
   日历版本，不可切换）、mode=unattended / interactive（推进方式：无交互 / 交互式，
   项目过程中可改）、verification=auto / manual（验收执行者：系统自动验收 / 用户验收，
   项目过程中可改）
   → 落 `<项目根>/.mira/sdd/` 四文件 + 配置区
   → 写 .git/info/exclude：.export/（两形态都写）；.mira/sdd/（仅 standalone）；
     项目无 .git 时跳过并报告
   → standalone 另在 .mira/sdd/ 内嵌 git 仓（自有历史，可推私有远端）
   → 回报：文件清单、治理根、形态；声明「卸载插件零影响」
3. 模板对齐：从治理树本身提取结构，与当前模板比对——
   无差异 → schema 写为当前 sdd 版本，结束；
   有差异 → 先查治理文件无未提交改动（standalone 查内嵌仓、inline 查项目仓治理路径，干净则
   git 历史即回滚点）→ 整文件重排：数据逐项填入当前模板形状——原字段搬运、新字段留空或默认、
   表格行补空单元格、树中多余内容保留并报告、搬不动的停下问；先查再补（已具备则跳过，中断重跑安全）；
   JOURNAL 与 AMENDMENTS 既有条目不重排、完结提案不动；
   完成 schema 写为当前 sdd 版本——standalone 内嵌仓提交一版，inline 留工作区随项目仓提交
4. 重建（standalone 项目新 clone 后 .mira/sdd 缺失）：询问——从私有远端恢复内嵌仓，
   或新开；inline 项目 clone 后目录随仓在，无需重建。补写 exclude——预期动作非损坏
```

references：`governance-files.md`（四文件规则 + 看板读法；模板在 `sdd/templates/`）；重建与未知残留处置并入 init SKILL 主流程

### 4.3 intake

流程：

```text
0. 无治理 → 退回 init，不得自行创建任何文件
1. 分流与捕获：插单无条件先捕获（原话入意图池得 I-XXX + 一句「已记录」，
   绝不转向）；常规入口一眼维护/咨询直接做并回报；需求与模糊类捕获得 I-XXX
2. 三问分流（决策表见下）：小改动直接做并回报（行标已否）；需求类进入澄清
3. 澄清与成形（JOURNAL [I-XXX] 实时落盘）：边界、约束、成功标准 → 方案选项、
   选定与否决逐条留痕；INTENT 区块状态澄清中、边界结论随手更新；
   模糊大需求停在澄清中，不强行拆分
4. 拆分判定：JOURNAL [I-XXX] 记拆分依据 → 建 1..n proposals/P-XXX/
   （按依赖顺序发号、生成 codename）→ REGISTRY 加行（intent 回指）+ INTENT 区块：已拆分 + P 表格；
   只拆当前看得清的交付物，其余留池等成熟
5. 提案细化探索（按需，逐提案）：提案被推进而技术形态未清时进行——
   interactive 与用户对话收敛（选项摆开 → 选定与否决），unattended 独自收敛；
   JOURNAL [P-XXX] 实时落盘；完成 = 该提案疑虑清零；
   未探提案停在立项，探索不批量预做
6. 移交 sdd:spec（逐提案，携带 I-XXX）；移交前置 = 该提案已细化探索；
   探索可重入（spec 定稿检查不过 → 退回补澄清或补探索）
```

三问决策表：

| ①行为差异 | ②方案空间 | ③标准自明 | 判定 |
|---|---|---|---|
| 无 | — | — | 维护/咨询，直接做 |
| 有 | 无 | 是 | 小改动，直接做并回报 |
| 有 | 无 | 否 | **仍立项**（防「顺手改」大面积走样） |
| 有 | 有 | — | 立项（探索收敛方案） |

文档受理（文件或目录，含路径，一至多份）：拆成条目 → 逐条定去向（每条显式，判据不能少不能多）→ 与存量治理数据核对 → 批量落位；unattended 下自动定去向并落位 + 差异报告（多出/缺失逐条列出）。落位成文不带材料来历——无导入叙述、无来历口吻、无外部文件引用。

references：`triage.md`（三问判据与决策表、拆分判定——同类重复不拆（十处校验是一个需求的十个任务）、codename 生成规则、文档受理程序）、`exploring.md`（探索方法论：自顶向下、先发散后收敛、逐层留痕，适用于澄清与提案细化两阶段；JOURNAL 条目格式引用模板）

### 4.4 spec

流程：

```text
0. 无提案上下文 → 退回 intake；方案没定（底稿没结论）→ 退回 intake 细化探索——
   探索归 intake，本技能只成文，写的过程中冒出没定的事同样退回
1. 写 P-XXX-SPEC.md：读 JOURNAL（[I-XXX] 段 + 本提案 [P-XXX] 段）+ INTENT 区块 →
   frontmatter version: v1 + intent: I-XXX 回链；背景（问题/目标，从意图边界转写）；
   范围内/范围外（范围外必写，防蔓延）；边界与异常（空态/错误/边界输入）；
   验收标准表逐条绑定可独立执行的验证命令（UI 行为即 E2E，用例随提案任务建）；
   不可核对表述（「好用」「美观」）退回重写
2. DESIGN.md：方案概述 + 接口/数据/关键流程 + 技术决策 + 被否备选留档（方案、
   否因——成形期否决来自 JOURNAL 对应条目）
3. TASKS.md ← DESIGN.md 派生：任务 = 一个提交粒度，被依赖者排前，
   每任务标注覆盖的验收条目
4. 定稿检查（四条全过）：验收标准全部可核对 / 范围边界清楚 / 方案已定 / 任务表就绪
   interactive → 停驻等确认；unattended → 定稿回报；定稿 → REGISTRY 待实现
5. spec 期内变更：直接修改 + SPEC 头部 version 自增（无 AMENDMENTS）
```

定稿语义：定稿 ≠ 冻结——它是「此后变更走三分支表」的开关。

references：`contract.md`（验收标准表列规则、可核对性判据好/坏对照、验证绑定格式；accept 引用此文件）、`proposal-layout.md`（提案三文件说明：frontmatter 同构、标题入 H1、intent 回链；模板在 `sdd/templates/`）

### 4.5 start

流程：

```text
0. 来源检查：无已定稿任务上下文 → 退回 intake（无任务不写码）
1. 领任务：查 REGISTRY「待实现」提案（依赖列含非完结提案的排除；P-XXX 序为消费序）；
   可取为空而待实现尚存 → 依赖环游走分诊（环 → 点名停下问/回报；无环 → 报等待原因）
   interactive：取用户指定提案或队首一个，完成后等待
   unattended：流水线循环——accept 完结回此取下一个；无待实现 →
   有 INTENT/探索中 → 回 intake/spec 补一个待实现提案 → 继续；彻底没有 → 总回报收尾
2. 工作区：主会话切 dev/<codename> + worktree 隔离（子 Agent 不建删分支）
3. 派发实现（默认提案级子 Agent）：按 TASKS.md 序完成任务，任务间不停顿、无需确认——
   interactive 交互点只在提案边界（启动开发=派发、回收报告后等待）；以任务为界提交
   （公开面零治理，无 footer；TASKS.md 完成列由主会话回填）；照常自检（构建/测试），
   无正式闸门；子 Agent 只产出提交，设计疑点停下上报（派发不可用 → 主会话按同一纪律直做）；
   派发期间主会话照常受理与探索其他提案，回收通知优先处理——先核验回填，再回到手头事务
4. 并行加速（仅用户明确要求）：任务级或多个提案同时派发，回收逐项核验
5. 全任务完成 → REGISTRY 待验收 → 移交 sdd:accept
   （开发中发现设计需推翻 → 走 AMENDMENTS 三分支第二行：放弃、回退 spec）
```

references：`git-flow.md`（分支拓扑 + 验收位协议 + codename 规则；accept 引用）、`gate.md`（提交门禁程序：书写规范检查清单，error 阻断 / warning 放行；bootstrap 指针目标）、`dispatch.md`（提案派发简报、回收核验、中断恢复）

### 4.6 accept

流程：

```text
0. 前置：REGISTRY 待验收 + 验收位空闲
1. 占位：main 拉 test/<codename> → 合入 dev/<codename>（冲突在此解决，解不了挂起问人）→
   REGISTRY 验收中
2. 验证：按 SPEC 契约表逐条执行 + 指认证据（命令、用例、输出摘要）；
   指认不出 = 失败；manual = 停等用户发起
3. 失败 → 修复落 test/<codename> → 重验；auto 上限 3 次挂起释放验收位；manual 无上限
4. 挂起后恢复：删旧 test/<codename> → 从最新 main 重拉 → 合 dev → 同一循环
   （挂起即释放验收位 → main 解冻前进 → 恢复必须重立基线，互锁）
5. 全绿 → 发布链：合并 main（解冻）→ versioning bump → CHANGELOG（用户语言、
   零治理信息、按版本节）→ 发布提交 → tag；阶段内不二次确认（mode 零分叉）
6. 清理：删 test/<codename>、dev/<codename>、worktree → REGISTRY 完结 → 按 `intent` 列
   查兄弟提案，名下全完结则 INTENT 区块回写完结 → 回 start（unattended）
```

验收位协议（互斥资源）：进入前检查 `test/*`——无则创建占用；有且对应验收中提案 → 按号排队；**有但无主（人工创建或孤儿）→ 一律不碰不删**，本提案转待验收，interactive 告知用户、unattended 跳过并回报、继续。

references：`release.md`（发布链程序 + CHANGELOG 规范）；验证程序见 `spec/references/contract.md`

### 4.7 export

流程：

```text
0. 治理根发现；无治理 → 提示先 init
1. 只读采集：REGISTRY + INTENT + JOURNAL + 各提案 SPEC/DESIGN + AMENDMENTS
   （AMENDMENTS 演变链与 JOURNAL 转向记录 →「历程与转向」叙述）
2. 提炼转写（零治理词汇：不出现 P-XXX/I-XXX/codename/状态机/意图/提案等术语，
   以读者问题组织），
   单文件两章：
   需求层：现状与计划（产品/管理视角）
   技术层：目录结构、技术栈、方案与决策（工程视角）
3. 落盘：<项目根>/.export/<项目名>-<YYYYMMDDHHmmss>.md（已被 info/exclude 排除）
4. 回报路径；除此之外零副作用
```

references：`export.md`（两章模板、脱治理词汇转写纪律）

## 5. 横切机制

### 5.1 分支拓扑（唯一源：`start/references/git-flow.md`）

```text
dev/<codename>    每提案一支 + worktree 隔离
   │ 开发完成
   ▼
test/<codename>   从 main 拉取创建 → 合入 dev/<codename> → 验收（全局串行，互斥位）
              存续期 main 冻结；一切修复落 test/<codename> 随本提案发布
   │ 验收通过
   ▼
main          合并 + bump + CHANGELOG + 发布提交 + tag（解冻）
```

分支只在两处死亡：accept 完结清理（test+dev+worktree）、start 开发中放弃（dev）。挂起不动任何分支。分支命名一律 codename（P8 双身份）。worktree 固定在项目根 `.worktrees/`（`.git/info/exclude` 本地排除），提交与验证都在 worktree 内进行，主工作区不受扰；遇大文件下载、依赖安装等耗时操作先选省时路径——拷贝有收益的拷贝后增量补齐，增量安装本身就快的直接安装。

### 5.2 提交纪律

以任务为界，单提交不混多任务；公开面零治理（主题行无治理 ID、无 footer）；TASKS.md 登记任务↔commit 映射（治理侧私留）。

### 5.3 模板对齐

两个版本各走各的升级：插件版本经 claude plugin 升级；schema 是治理结构的版本戳，值取自 sdd 版本，
只经 sdd:init 更新。schema 与插件版本比较：

- 相同：正常
- 落后：init 模板对齐（用户显式重跑 init 触发）——比对治理文档结构与当前模板，无差异只更新
  schema；有差异把数据重排进当前模板（原字段搬运、新字段留空或默认、表格行补空单元格、
  多余内容保留并报告、搬不动的停下问），结束 schema 置为当前 sdd 版本
- 领先（治理文档来自更新的插件）：工作不受影响（按 P14 宽容读取）——处置：先
  `claude plugin update sdd` 保证插件最新（已是最新则空操作），再跑 init 完成对齐

检查点：会话开始的恢复现场（bootstrap）；会话中拉取治理文档的，退出重进后看到。

### 5.4 导出物

`.export/` 在项目根，`.git/info/exclude` 本地排除（两形态统一，不碰公开的 .gitignore）；环境重建时由 init 重写。

## 6. 组装与验收（kit 七步 × 每步验证）

| 步 | 动作 | 验证 |
|---|---|---|
| 1 | `claude plugin init sdd --with skills hooks`（产物在 ~/.claude/skills/sdd/） | 产物存在、plugin.json 有效 |
| 2 | 移入 mira-plugins/sdd/；仓库根 git init + 首笔提交（含本设计文档） | 结构就位 |
| 3 | 落 hooks（hooks.json + session-start，按 §2 行为描述自建）、元技能与各技能正文骨架 | `bash sdd/tests/test-session-start.sh` → PASSED；SKILL_REL↔目录↔frontmatter 三处一致 |
| 4 | `claude --plugin-dir ./sdd` 冒烟 | hook 触发、技能可见 |
| 5 | `claude plugin validate ./sdd --strict` | 通过 |
| 6 | **验收铁律**：干净会话（无治理痕迹目录）发一句话需求（如「我要做一个 react todo list」） | **必须**在写任何代码前呈现 bootstrap 驱动行为（init 建议或 intake 三问），不触发 = 注入未生效，回查 matcher 与 JSON 分支 |
| 7 | 根 marketplace.json + `claude plugin marketplace add` + install + `details` | 冒烟通过 |

## 7. 后续迭代（本设计不做）

- 机械资产（模板/生成器/门禁脚本）进插件 scripts/references，不动机制
- Windows 支持：polyglot 包装脚本（单文件同为合法 cmd 与 bash，定位 bash 分发执行）
- `claude plugin eval` 行为评估套件

## 8. 被否决的备选（存档防重蹈）

| 备选 | 否因 |
|---|---|
| 借鉴 superpowers 动名词命名（starting/accepting…） | 与 sdd 词汇连续性断裂；bootstrap 用名词恰标记注入件类别 |
| 软依赖 superpowers + 内嵌降级 | 两套规则 + 静默降级（用户不知情换流程）；实际必需链点为 0 |
| AMENDMENTS 记治理规则演变 | 治理规则的家在插件，历史走插件 CHANGELOG |
| interactive 发布前呈报 | mode 阶段内零分叉原则；入口触发已是同意 |
| 三层导出（需求/技术/全量） | 全量 = 前两者机械合并，伪选项；收缩为单文件内两章 |
| .gitignore 排除 .export/ | .gitignore 本身是公开文件，standalone 下即治理痕迹；用 .git/info/exclude |
| 探索放 spec | 探索燃料是用户在场，是受理对话的延伸；spec 只做结晶与契约化 |
| 软 LEDGER 命名 | 财务味；REGISTRY 更准（发号登记语义） |
| 任务级 manual 验证 / auto 逐任务验证 | 正式闸门只有提案末端一道，两取值只差执行者 |
| 需求组（R-XX）独立于意图 | 组与意图同体分叉：聚合单位 = INTENT 行本身，需求完结由名下提案推导 |
| 提案独立 PROPOSAL 文件 | 问题/目标与规格一体，四文件减为三；来源意图以 intent 回链表达 |
| 意图 per-intent trail 文件 | 留痕单点在 JOURNAL（[I-XXX]/[P-XXX] 双命名空间）；INTENT 行只存事实 |
