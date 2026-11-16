---
name: accept
description: 当提案开发完成进入验收（unattended 流水线自动推进；verification=manual 时等用户发起）；执行契约验证与证据核验；验证失败修复重验；验收通过执行发布链（合并、bump、CHANGELOG、tag）。
---

# sdd:accept — 验收与发布

对契约逐条指认证据，全绿后走发布链。本技能拥有从「验收」到「tag」的完整链条，不可拆。

## 流程

### 0. 前置

REGISTRY 状态 = 待验收 + 验收位空闲。验收位协议（互斥资源，含无主分支处置）：见 `sdd:skills/start/references/git-flow.md`——**流水线永不处置它没创建的分支**。

### 1. 占位

从 main 拉 `test/<codename>` → 合入 `dev/<codename>`（基线 = 当前 main；冲突在此解决，解不了挂起问人）→ REGISTRY 状态：验收中。占位期间 main 冻结。

### 2. 验证（正式闸门，全提案唯一一道）

按 SPEC.md 验收标准表**逐条**执行绑定命令——verification: manual 时先等用户发起，用户执行的也是这些命令，不是手动操作 UI：

- 每条在表内填：结果（过/败）+ **证据**（命令名、关键输出摘要、用例名）
- **指认不出 = 败**。「应该过了」「看起来没问题」不是证据

### 3. 失败 → 修复 → 重验

- 修复落 `test/<codename>`（验收期一切修复随本提案发布），过门禁后重验失败项
- verification=auto：重验上限 **3 次**，达上限 → 提案挂起（挂起原因入 REGISTRY）、**释放验收位**（main 解冻，其他提案继续）
- verification=manual：**无上限**——节奏归人，人判几次就修几次

### 4. 挂起后恢复

删旧 `test/<codename>` → 从**最新 main** 重拉创建 → 合入 `dev/<codename>` → 走同一验证循环。（挂起即释放验收位 → main 已前进 → 旧基线失真，恢复必须重立基线——互锁）

### 5. 发布链（全绿后）

合并 `test/<codename>` → main（解冻）→ 按配置 `versioning` bump 版本 → 写 CHANGELOG（规范见 `references/release.md`）→ 发布提交 → 打 tag。

mode 只表明推进过程中需不需要交互（interactive 交互式 / unattended 无人自动化）——**阶段内不设二次确认**，发布直接执行 + 回报。

### 6. 清理与完结

删 `test/<codename>`、`dev/<codename>`、对应 worktree → REGISTRY：完结（填完结日期）→ 按 REGISTRY `intent` 列查兄弟提案：名下提案全完结则 INTENT 区块回写完结 → unattended 回 sdd:start 取下一个。

## 常见误区

| 你会想 | 事实 |
|---|---|
| 「命令跑过了，证据摘要就不贴了吧」 | 证据是治理记录不是仪式；不贴 = 事后无从查证 |
| 「就差一条，先发布后面补」 | 契约全绿是发布的前置；差一条 = 没过，走失败循环 |
| 「修复直接落 main 快一些」 | 验收期 main 冻结，修复落 `test/<codename>` 随本提案发布——这是基线一致性的保证 |
| 「旧 test 分支没用了顺手删掉」 | 无主分支一律不碰——它可能是人自己的工作 |

## references

- `release.md` — 发布链程序、CHANGELOG 规范、恢复基线程序
- 验证程序与证据指认规则：见 `sdd:skills/spec/references/contract.md`，不复制
