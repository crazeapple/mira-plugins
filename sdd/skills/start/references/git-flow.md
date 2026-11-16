# git-flow.md — 分支拓扑

本文件是分支与工作区的唯一规则源；sdd:accept 引用本文件，不另行定义。

## 拓扑

```text
dev/<codename>    每提案一支，配 worktree 隔离（实现在这里发生）
   │ 全任务完成
   ▼
test/<codename>   从 main 拉取创建 → 合入 dev/<codename> → 验收（全局串行，互斥位）
              存续期 main 冻结；一切修复落 test/<codename>，随本提案发布
   │ 验收通过
   ▼
main          合并 + bump + CHANGELOG + 发布提交 + tag（解冻）
```

- 分支名一律用 **codename**（公开面零治理，P-XXX 不上分支名）
- `test/<codename>` 从 main 拉取（不从 dev）——验收基线 = 当前 main；dev 合入时冲突在此解决
- `test/<codename>` 存续期间 **main 冻结**：验收基线 = 发布基线；其他提案照常在各自 dev 开发，但不得进入验收

## 验收位协议（互斥资源）

全局同时至多一个提案处于验收中。进入验收前检查现存 `test/*` 分支：

| 发现 | 处置 |
|---|---|
| 无 | 创建 `test/<codename>`，占用验收位 |
| 有，且 REGISTRY 中对应提案状态 = 验收中 | 排队：按 P-XXX 序，本提案转「待验收」，先处理别的 |
| 有，但**无主**（无提案处于验收中——人工创建或上次中断的孤儿） | **一律不碰、不删、不合并**；本提案转待验收；interactive 告知用户由人处置，unattended 跳过并回报、继续 |

原则：**流水线永不处置它没创建的分支。**

## worktree 操作

```text
git worktree add .worktrees/<codename> dev/<codename>
```

- worktree 固定在项目根 `.worktrees/` 下（init 已写入 `.git/info/exclude`，不提交）；提交与验证都在 worktree 内进行，主工作区不受扰
- worktree 的生死跟随分支：完结清理时一并移除（`git worktree remove`）
- worktree 内遇大文件下载、依赖安装等耗时操作，先选省时路径：项目根已有产物且拷贝有收益的，拷贝后增量补齐（如 npm 拷 node_modules 后再跑一次安装，只补差异）；增量安装本身就快的（如 pnpm 走全局存储建链接），直接安装不拷贝

## 分支生死

分支只在两处死亡：

1. **accept 完结清理**：发布链完成后删 `test/<codename>`、`dev/<codename>`、对应 worktree
2. **start 开发中放弃**：删 `dev/<codename>` 与 worktree（提交随之丢弃）

挂起**不动任何分支**（dev 要活到恢复；test 由 accept 的恢复程序重建）。

## 放弃流程（start 开发中发现设计需推翻）

1. 记 AMENDMENTS（为什么换 / 换成什么；技术缘由写进「为什么换」）
2. 丢弃 dev 分支提交：删 `dev/<codename>` + worktree
3. 回 sdd:spec 重来（携带 AMENDMENTS 里的新方向）
