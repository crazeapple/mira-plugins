# CHANGELOG

本文件记录插件与治理形态的演变（治理规则的每次修订都在这里留痕）。格式：最新在上，一个发布一节。

## 1.0.0（2026-10-16）

首个版本：需求治理技能集，纯技能载体（无命令），会话开始自动注入。

### 新增

- **bootstrap 元技能**：SessionStart（startup/clear/compact）整篇注入治理纪律与技能路由表；插单不打断、无任务不写码、提交过门禁、无证据不算完四条横切纪律常驻
- **sdd:init**：在目标项目建立治理树 `<项目根>/.mira/sdd/`（REGISTRY/INTENT/JOURNAL/AMENDMENTS + proposals/，纯 Markdown 零可执行痕迹）；七种治理文档各有唯一模板（`sdd/templates/`）；standalone（默认，该选项不可变）/ inline 双形态；治理写入即提交（一笔一个关注点）；重跑自动判模板对齐：以 `schema` 对比插件版本，结构有差则把治理数据重排进当前模板
- **sdd:intake**：一切需求的第一站：顺手能改的直接做（有三条问题把关，说不清完成标准的不算顺手）；真需求收进意图池（原话逐字留档）；与用户把需求聊清楚、候选方案摆开做选定与否决，聊到哪记到哪（JOURNAL）；一个需求拆成一个或多个提案，只拆现在看得清的部分；每个提案动工前把技术方案定下来——interactive 和你对话着定，unattended Agent 自己定，推进到哪个提案才定哪个；也可把需求文档作为参数（贴路径或粘贴），逐条确认去向再落位
- **sdd:spec**：把已收敛的探索底稿成文为提案三文件（SPEC：背景、范围内外、边界与异常、验收标准表；DESIGN；TASKS）；验收标准表契约化——逐条绑定可独立执行的验证命令（UI 行为即 E2E 测试，用例随提案任务创建），不可自动核对的表述退回重写；spec 期内变更升版
- **sdd:start**：任务实现（一任务一提交、公开面零治理、worktree 隔离）；实现默认派发子 Agent（提案级简报、回收核验、中断恢复）——主会话交付判断，子 Agent 只交付提交；unattended 流水线循环驱动多提案；提交门禁（markdownlint 机械检查 + 语感清单）；开发中推翻方案走修正登记回退规格
- **sdd:accept**：验收契约逐条证据指认（auto 有重验上限 / manual 无上限、恢复重立基线）；发布链（合并 → bump → CHANGELOG → tag → 分支清理）
- **sdd:export**：治理知识提炼为单文件项目概览（需求层 + 技术层两章，零治理词汇，落 `.export/` 本地排除）
- 治理骨架：意图/提案/任务三级编号（I-XXX / P-XXX / P-XXX-TNN，按依赖顺序发号，永不复用）、提案表依赖列（静态声明、调度联查——发号后新发现的依赖不破序）、双身份（P-XXX 治理侧 / codename 公开侧）、I 包含 P（提案归属登记在 REGISTRY 提案表 intent 列）；定规格前的过程留痕单点在 JOURNAL（探索底稿，条目按归属标头、追加不重写）
- 治理配置：`mode`（推进方式）× `verification`（验收执行者）随时可改；`versioning`（semver / calver）init 时定，公开契约；`sdd-kind` init 时定不可变；REGISTRY 头 `schema` 为治理结构的版本戳（值取自 sdd 版本）
- 治理文件形状：有元数据的文件一律 frontmatter（提案三文件 id/type/intent/version，REGISTRY 配置区 schema/mode/verification/versioning/sdd-kind）；INTENT 区块式（原话逐字引用，已拆分区块带 P 表格）；JOURNAL 条目槽位化；AMENDMENTS 含影响范围——每个实体只有一种合法形状；治理文档不写本机信息（路径、主机名、用户名等）
