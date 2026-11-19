# sdd — 需求治理技能集

用 Agent 开发软件，混乱不在写码，而在写码之外：想法随口就来，Agent 听到就开干；讨论结论只活在聊天记录里，隔天重吵一遍；「做完了」拿不出凭据；需求并行互相踩踏；发布了说不清这次含什么。sdd 把这些装进一套治理体系：每个愿望被受理、分类、编号；探索有底稿，动工有规格与验收契约，完成要逐条指认证据，发布合并打 tag 全程留痕。

纯技能集插件：无 slash commands、零运行时依赖，装好后会话开始自动注入治理纪律与路由——不需要记任何命令。注入机制借鉴 [obra/superpowers](https://github.com/obra/superpowers)，但两者是不同层的独立插件：superpowers 管单需求的工程执行（怎么把一件事做对），sdd 管需求治理（一堆事之间谁先谁后、承诺过什么、凭什么算完），可并存互补。

## 安装

先添加本仓库为 marketplace（一次即可；路径换成实际 clone 位置）：

```bash
claude plugin marketplace add /path/to/mira-plugins

claude plugin install sdd@mira-plugins                  # user 级：本机所有项目
claude plugin install sdd@mira-plugins --scope project  # 写入项目配置，随仓共享
claude plugin install sdd@mira-plugins --scope local    # 仅当前项目、仅本机
```

本地修改插件后，更新已装副本（重启会话生效）：

```bash
claude plugin marketplace update mira-plugins
claude plugin update sdd@mira-plugins
```

开发调试可免安装单会话加载：`claude --plugin-dir ./sdd`。

## 装好后

会话开始自动注入治理纪律与路由（bootstrap）。六个技能各管一段，你只管说话：

| 技能 | 管什么 |
|---|---|
| sdd:init | 建立治理树：REGISTRY 与治理配置、双形态、模板对齐与重建 |
| sdd:intake | 受理一切新需求/想法/文档：三问分流、意图池、澄清拆分、立项探索 |
| sdd:spec | 写规格：范围内外、验收标准表（可核对契约）、设计与任务派生 |
| sdd:start | 实现：默认派发子 Agent 开发、分支 + worktree 隔离、任务边界提交、流水线循环 |
| sdd:accept | 验收：契约逐条证据指认；通过后合并、bump、CHANGELOG、tag |
| sdd:export | 治理知识提炼为给外人看的单文件概览（只读） |

问进度/看板不用调技能，直接说——有内置的只读汇总。

## 治理树

治理文档长在项目里的一个固定目录——人能读、git 能管、任何工具可续用：

```text
<项目根>/
└── .mira/sdd/
    ├── REGISTRY.md      # 登记簿：提案编号、代号、依赖、状态与治理配置
    ├── INTENT.md        # 意图池：每个需求想法的原话、边界与去向
    ├── JOURNAL.md       # 过程留痕：澄清、方案探索、选定与否决、拆分依据
    ├── AMENDMENTS.md    # 修正登记：推翻或取代已生效方案时记一笔
    └── proposals/
        └── P-001/       # 每个提案一个目录
            ├── P-001-SPEC.md    # 规格：背景、范围、验收标准表
            ├── P-001-DESIGN.md  # 设计：方案、技术决策、被否备选
            └── P-001-TASKS.md   # 任务：执行拆解与完成记录
```

两种形态：**inline** 随项目仓提交，团队可见；**standalone**（默认）不随项目仓提交——内嵌独立 git 仓，可本地私有，也可推私有远程仓库。REGISTRY 建立即在；INTENT/JOURNAL/AMENDMENTS 首次写入时出现。卸载不丢数据、不锁定格式：治理树是纯 Markdown，可读、可审计、可迁移；继续治理流程需 sdd 插件在位。

## 设计

完整设计（机制、原则、技能规格、分支拓扑）见本仓库 `docs/sdd-plugin-design.md`。
