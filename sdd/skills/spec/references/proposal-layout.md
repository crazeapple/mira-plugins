# proposal-layout.md — 提案三文件说明

提案目录 `proposals/P-XXX/` 内文件一律**带提案号前缀**。**提案无独立 PROPOSAL 文件**——问题/目标并入 SPEC 背景，来源意图以 frontmatter `intent: I-XXX` 回链。三个文件的模板在 `sdd:templates/`（tmpl-spec、tmpl-design、tmpl-tasks），逐字落盘，尖括号占位处填实；三文件 frontmatter 同构（`id`/`type` 由文件名可推导，静态冗余，为同构保留），标题入 H1。

- frontmatter `version` 是**提案级版本号**（仅 SPEC 有）：spec 定稿后每次变更自增（spec 期内改不算，定稿从 v1 起算）
- `intent` 是来源意图的静态回链（提案归属永不变，指路 JOURNAL 澄清成形段）；兄弟提案与意图完结推导查 REGISTRY 提案表 `intent` 列
- SPEC 的验收标准表骨架见模板；表列语义与判据见 `contract.md`
- TASKS 的任务 = 一个提交粒度，被依赖者排前；覆盖列写验收条目编号，每条验收至少被一个任务覆盖
- `完成`列由 sdd:start 填：任务对应 commit 的 hash（治理侧私留映射，公开面零治理）
- REGISTRY 状态同步：spec 定稿 → 待实现；任务全完成 → 待验收
