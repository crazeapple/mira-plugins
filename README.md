# mira-plugins

[![CI](https://github.com/crazeapple/mira-plugins/actions/workflows/ci.yml/badge.svg)](https://github.com/crazeapple/mira-plugins/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/github/v/tag/crazeapple/mira-plugins)](https://github.com/crazeapple/mira-plugins/tags)

收录需求治理插件 sdd@mira-plugins 的 Claude Code 插件市场——本仓库即插件清单，clone 即用。

## sdd — 需求治理技能集

需求治理层插件：管「一堆事之间谁先谁后、承诺过什么、凭什么算完」——受理、规格、实现、验收、发布全程留痕。纯技能集，无 slash commands、零运行时依赖，装好后会话开始自动注入治理纪律与路由，不需要记任何命令。

产品介绍、安装、治理树形态、技能一览：见 [sdd/README.md](sdd/README.md)。完整设计：[docs/sdd-plugin-design.md](docs/sdd-plugin-design.md)。

## 插件族路线图

- 规划中

## 验证

CI（push / PR）与本地同一入口跑统一门禁：`bash scripts/check.sh`（依赖 node 与 claude CLI）。

## 更新日志

见 [CHANGELOG.md](CHANGELOG.md)。

## 许可

MIT — 见 [LICENSE](LICENSE)。
