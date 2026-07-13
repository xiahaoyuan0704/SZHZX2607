# 工程提资系统桌面端原型

这是一个基于 Electron + Vue 3 + Vite 的工程提资软件初始原型，当前聚焦界面和数据录入体验：

- 左侧为多级业务菜单。
- 顶部为项目中心、标签页和常用操作入口。
- 右侧主体展示提资表格。
- 表格中仅“E列：用户填写”为可编辑输入项，其余列用于展示和辅助核对。

## 本地运行

```bash
npm install
npm run electron:dev
```

## 构建

```bash
npm run build
```
## 数据库设计

当前版本已补充 MySQL 设计文档和初始化脚本：

- `docs/database-design.md`：说明为什么要拆分模板数据和用户填写数据，以及读取/保存 E 列的典型 SQL。
- `database/schema.sql`：创建 `projects`、`handover_templates`、`handover_template_items`、`project_handover_sheets`、`project_handover_values` 等表，并初始化“总平面工程量”模板数据。

