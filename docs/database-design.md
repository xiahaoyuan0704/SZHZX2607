# 工程提资系统 MySQL 数据库设计

## 设计原则

当前页面里只有 `E列：用户填写` 是用户真正录入的数据，其余字段属于提资表模板。因此数据库应拆成两类数据：

1. **模板数据**：序号、项目名称、工程内容、单位、说明等固定展示字段。
2. **项目填写数据**：某个项目、某张提资表、某一行对应的 E 列填写值。

这样做的好处是：模板可以复用、可以版本化；不同项目只保存用户填写值，避免重复存储大量固定文本。

## 表结构说明

| 表名 | 作用 |
| --- | --- |
| `projects` | 项目主表，保存项目编号、项目名称、阶段、状态。 |
| `handover_templates` | 提资表模板，例如“总平面工程量”，支持模板编码和版本。 |
| `handover_template_items` | 模板行数据，保存序号、项目名称、工程内容、单位、默认值、说明等展示字段。 |
| `project_handover_sheets` | 某个项目使用某个模板生成的一张提资表。 |
| `project_handover_values` | 用户实际填写的 E 列数据；通过 `sheet_id + template_item_id` 精确定位到某项目某行。 |

## 为什么不把所有字段放在一张表里？

不推荐把序号、项目名称、单位、说明、用户填写值全部存在一张大表里，因为：

- 固定展示字段会在每个项目里重复保存，浪费空间。
- 后续模板改版困难，无法区分旧项目使用的是哪个版本模板。
- 难以支持多个提资表类型，例如后续增加“电气工程量”“建筑工程量”。
- 难以做权限、提交、审核、收口等状态流转。

推荐的方式是：模板行只维护一份，项目只保存自己的填写值。

## 前端读取数据的典型 SQL

页面加载时，可以用下面的 SQL 一次性拿到当前项目的表格数据：

```sql
SELECT
  i.id AS template_item_id,
  i.row_no,
  i.project_name,
  i.work_content,
  i.unit,
  COALESCE(v.input_value, i.default_value) AS input_value,
  COALESCE(v.input_text, i.default_text) AS input_text,
  i.remark,
  i.row_type,
  i.sort_order
FROM project_handover_sheets s
JOIN handover_template_items i ON i.template_id = s.template_id
LEFT JOIN project_handover_values v
  ON v.sheet_id = s.id
 AND v.template_item_id = i.id
WHERE s.id = ?
ORDER BY i.sort_order;
```

## 保存 E 列数据的典型 SQL

用户编辑 E 列时，建议使用 `INSERT ... ON DUPLICATE KEY UPDATE` 做保存：

```sql
INSERT INTO project_handover_values
  (sheet_id, template_item_id, input_value, input_text, updated_by)
VALUES
  (?, ?, ?, ?, ?)
ON DUPLICATE KEY UPDATE
  input_value = VALUES(input_value),
  input_text = VALUES(input_text),
  updated_by = VALUES(updated_by),
  updated_at = CURRENT_TIMESTAMP;
```

其中 `project_handover_values` 上的唯一索引 `uk_sheet_item(sheet_id, template_item_id)` 可以保证同一张项目提资表的同一行只有一条填写记录。

## 初始化流程建议

1. 执行 `database/schema.sql` 创建数据库、表和“总平面工程量”模板初始数据。
2. 新建项目时，先向 `projects` 插入项目记录。
3. 为该项目生成提资表时，向 `project_handover_sheets` 插入一条记录，关联项目和模板。
4. 前端打开提资表时，读取模板行 + 用户填写值。
5. 用户修改 E 列后，只写入 `project_handover_values`。

## 后续扩展

后续如果要增加更多业务能力，可以继续添加：

- `users`：用户表。
- `handover_attachments`：附件表，用于保存导入文件、图纸、证明材料。
- `handover_audit_logs`：审核/提交/退回记录。
- `handover_template_versions`：如果模板版本管理更复杂，可以拆出独立版本表。
