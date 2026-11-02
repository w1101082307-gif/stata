# 气候风险与企业金融化 — 复现代码

本仓库收录论文 *Climate Risk and Corporate Financialization: Evidence from Adjustments in the Financial Asset Maturity Structure* 的 Stata 复现代码。

## 文件

| 文件 | 说明 |
|---|---|
| `最终代码.do` | 单文件复现代码。读取 `datanew1.dta`，依次输出描述性统计、基准回归、工具变量与事件研究、机制与 Bootstrap、异质性、稳健性与替代口径的全部结果。 |

## 运行方式

1. 将 `datanew1.dta` 与本文件放在同一目录（或修改 `最终代码.do` 第 11 行的 `use` 路径）。
2. 在 Stata 18 中运行：

```stata
do 最终代码.do
```

3. 仅检查代码能否跑通时，可传入较小的 Bootstrap 次数：

```stata
do 最终代码.do 200
```

## 依赖

- Stata 18.0（`version 18.0`）
- 用户自编命令：`reghdfe`、`ivreghdfe`、`winsor2`、`psacalc`、`ftools`

## 数据说明

分析数据 `datanew1.dta`（23,203 个企业—年度，2010—2024 年）由 CSMAR 财务与治理数据以及商业文本数据库的派生指标整理而成，属于授权数据的观测层衍生文件。本仓库仅收录代码；具备合法授权的使用者可将该文件置于同目录后直接运行。

## 结果说明

代码以 `datanew1.dta` 为唯一输入，`isid stkcd year` 与 `assert _N == 23203` 会对数据做入口校验，因此样本规模不符时会立即报错，不会在错误样本上静默运行。
