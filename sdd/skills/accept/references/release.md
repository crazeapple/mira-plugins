# release.md — 发布链程序

## 发布链顺序（不可调换）

```text
合并 test/<codename> → main（解冻）
→ 版本 bump（按 REGISTRY 配置 versioning）
→ 写 CHANGELOG
→ 发布提交（仅版本号 + CHANGELOG 变更）
→ 打 tag（tag 名跟随既有版本 tag 形态）
→ 清理（删 test/<codename>、dev/<codename>、worktree）
```

### 版本 bump

- `semver`（默认）：语义化递增——提案含破坏性变更升主版本，新能力升次版本，修复升补丁；按 SPEC 范围内条目判断级别，判断不了问用户（interactive）或按次版本（unattended）
- `calver`：`YYYY.MM.DD`（发布日）；同日再次发布追加序号 `YYYY.MM.DD.N`（N 从 2 起，查当日已有 tag 接续）

### CHANGELOG 规范

- **用户语言**：写给使用者/协作者看，不以实现视角罗列过程
- **零治理信息**：不出现 P-XXX、codename、治理术语（公开面零治理，P7）——按「能力/修复/变更」等面向用户的类别组织，每版本一节
- 单次写入成文：一个发布一节，一次写完，不追加碎条目
- 新版本节插在文件顶部（最新在上）

### 发布提交

提交内容仅：版本号变更 + CHANGELOG。主题行如 `Release <版本>`——零治理信息，过 gate.md 清单。

### tag

`git tag <tag 名>` 于发布提交；tag 名跟随既有版本 tag 形态（`git tag -l` 查最近版本 tag 的形态；无既有版本 tag 用裸版本号）；无附加说明需求时用轻量 tag。

## 挂起恢复程序（验证失败达上限后，人工介入恢复时）

1. 读 REGISTRY 挂起原因与上次进展（SPEC 契约表的结果/证据列即断点）
2. 删旧 `test/<codename>` → 从**最新 main** 重拉 → 合入 `dev/<codename>`（挂起期间 main 已前进，旧基线失真）
3. 从失败条目继续走验证循环（auto 重新计数上限；manual 无上限）
4. 全绿 → 发布链照常

## 完结回报

发布完成后回报：版本号、tag、CHANGELOG 节位置、清理结果、REGISTRY 完结状态——unattended 方式下，此回报即流水线推进回到 start 的信号。
