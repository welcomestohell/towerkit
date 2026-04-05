## 设计指南

尚未最终确定

- 模块名称将使用 `PascalCase` 表示类/类型导出，`camelCase` 表示其他库

- 库的设计目标是扁平化，您只需引入 `ReplicatedStorage.Libs.X`，无需更深层依赖

- 任何内容都不应依赖于 `std`