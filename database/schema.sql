-- MySQL 8.x schema for 工程提资系统
-- Design goal: keep table/template metadata separate from user-entered E-column values.

CREATE DATABASE IF NOT EXISTS engineering_handover
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;

USE engineering_handover;

CREATE TABLE IF NOT EXISTS projects (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '项目ID',
  code VARCHAR(64) NOT NULL COMMENT '项目编号 / WBS编码',
  name VARCHAR(255) NOT NULL COMMENT '项目名称',
  stage VARCHAR(64) NOT NULL DEFAULT '基建初设' COMMENT '项目阶段',
  status VARCHAR(32) NOT NULL DEFAULT 'draft' COMMENT '状态：draft/submitted/closed',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_projects_code (code)
) ENGINE=InnoDB COMMENT='工程项目主表';

CREATE TABLE IF NOT EXISTS handover_templates (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '提资模板ID',
  code VARCHAR(64) NOT NULL COMMENT '模板编码',
  name VARCHAR(255) NOT NULL COMMENT '模板名称，例如：总平面工程量',
  version VARCHAR(32) NOT NULL DEFAULT '1.0.0' COMMENT '模板版本',
  is_active TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否启用',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_handover_templates_code_version (code, version)
) ENGINE=InnoDB COMMENT='提资表模板';

CREATE TABLE IF NOT EXISTS handover_template_items (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '模板行ID',
  template_id BIGINT UNSIGNED NOT NULL COMMENT '所属模板ID',
  parent_id BIGINT UNSIGNED NULL COMMENT '父级行ID，用于章节/分组，例如：十五',
  row_no VARCHAR(32) NOT NULL COMMENT '序号，例如：1.1、2.3',
  project_name VARCHAR(255) NOT NULL COMMENT '项目名称列，例如：围墙、道路',
  work_content TEXT NULL COMMENT '工程内容列',
  unit VARCHAR(32) NULL COMMENT '单位',
  default_value DECIMAL(18, 4) NULL COMMENT 'E列默认值，可为空',
  default_text VARCHAR(255) NULL COMMENT 'E列非数字默认值或预留文本',
  remark TEXT NULL COMMENT '说明/备注',
  row_type VARCHAR(32) NOT NULL DEFAULT 'item' COMMENT '行类型：group/item',
  sort_order INT NOT NULL DEFAULT 0 COMMENT '排序号',
  is_required TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'E列是否必填',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_template_row_no (template_id, row_no),
  KEY idx_template_sort (template_id, sort_order),
  KEY idx_template_project_name (template_id, project_name),
  CONSTRAINT fk_items_template FOREIGN KEY (template_id) REFERENCES handover_templates (id),
  CONSTRAINT fk_items_parent FOREIGN KEY (parent_id) REFERENCES handover_template_items (id)
) ENGINE=InnoDB COMMENT='提资模板行，保存除用户填写值以外的展示字段';

CREATE TABLE IF NOT EXISTS project_handover_sheets (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '项目提资表ID',
  project_id BIGINT UNSIGNED NOT NULL COMMENT '项目ID',
  template_id BIGINT UNSIGNED NOT NULL COMMENT '模板ID',
  name VARCHAR(255) NOT NULL COMMENT '项目内提资表名称',
  status VARCHAR(32) NOT NULL DEFAULT 'draft' COMMENT '状态：draft/submitted/approved/closed',
  created_by VARCHAR(64) NULL COMMENT '创建人',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_project_template (project_id, template_id),
  KEY idx_sheet_status (status),
  CONSTRAINT fk_sheets_project FOREIGN KEY (project_id) REFERENCES projects (id),
  CONSTRAINT fk_sheets_template FOREIGN KEY (template_id) REFERENCES handover_templates (id)
) ENGINE=InnoDB COMMENT='某个项目使用某个模板生成的提资表';

CREATE TABLE IF NOT EXISTS project_handover_values (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '项目提资值ID',
  sheet_id BIGINT UNSIGNED NOT NULL COMMENT '项目提资表ID',
  template_item_id BIGINT UNSIGNED NOT NULL COMMENT '模板行ID',
  input_value DECIMAL(18, 4) NULL COMMENT '用户填写的E列数值',
  input_text VARCHAR(255) NULL COMMENT '用户填写的E列文本，非数值时使用',
  updated_by VARCHAR(64) NULL COMMENT '最后填写/修改人',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_sheet_item (sheet_id, template_item_id),
  KEY idx_value_item (template_item_id),
  CONSTRAINT fk_values_sheet FOREIGN KEY (sheet_id) REFERENCES project_handover_sheets (id) ON DELETE CASCADE,
  CONSTRAINT fk_values_item FOREIGN KEY (template_item_id) REFERENCES handover_template_items (id)
) ENGINE=InnoDB COMMENT='用户实际填写的E列数据';

INSERT INTO handover_templates (code, name, version)
VALUES ('GENERAL_PLAN_QUANTITY', '总平面工程量', '1.0.0')
ON DUPLICATE KEY UPDATE name = VALUES(name), is_active = 1;

SET @template_id := (
  SELECT id FROM handover_templates
  WHERE code = 'GENERAL_PLAN_QUANTITY' AND version = '1.0.0'
);

INSERT INTO handover_template_items
(template_id, parent_id, row_no, project_name, work_content, unit, default_value, default_text, remark, row_type, sort_order, is_required)
VALUES
(@template_id, NULL, '十五', '总平面工程量', NULL, NULL, NULL, NULL, NULL, 'group', 1500, 0),
(@template_id, NULL, '1.1', '站址总用地面积', NULL, 'hm²', 0.9255, NULL, '13.8825亩', 'item', 1510, 1),
(@template_id, NULL, '1.2', '围墙内占地面积', NULL, 'hm²', 0.7943, NULL, '11.9145亩', 'item', 1520, 1),
(@template_id, NULL, '1.3', '进站道路占地面积', NULL, 'hm²', 0.0225, NULL, '0.3375亩', 'item', 1530, 1),
(@template_id, NULL, '1.4', '边坡挡墙占地面积', NULL, 'hm²', 0.1087, NULL, '1.6305亩', 'item', 1540, 1),
(@template_id, NULL, '2.1', '围墙', '围墙长度', 'm', 357.0000, NULL, '装配式围墙，一体化墙板，2.5m高', 'item', 1550, 1),
(@template_id, NULL, '2.2', '围墙', '单个基础量（含基础连梁）：2.3方', '个', 0.0000, NULL, '埋设-1.5m，基底尺寸2×2，C30钢筋混凝土（仅考虑部分区域）', 'item', 1560, 1),
(@template_id, NULL, '2.3', '围墙', '钢柱：HW200×200×8×12镀锌钢柱（防腐处理）+4M×16螺栓，160kg/个', '个', 122.0000, NULL, NULL, 'item', 1570, 1),
(@template_id, NULL, '2.4', '围墙', '基础地脚螺栓4M20螺栓', 'kg', 1300.0000, NULL, NULL, 'item', 1580, 1),
(@template_id, NULL, '2.5', '围墙', '钢柱：HW200×100×5.5×8镀锌钢柱（防腐处理）+4M×16螺栓，160kg/个', '个', 50.0000, NULL, '考虑变形缝', 'item', 1590, 1),
(@template_id, NULL, '3.1', '道路', '站内道路面积', 'm²', 1750.0000, NULL, '沥青混凝土道路，做法：从上至下为100厚沥青混凝土（B级70号石油沥青）；200厚C30混凝土面层（内掺抗裂纤维）', 'item', 1600, 1),
(@template_id, NULL, '3.2', '道路', '新建进站道路面积', 'm²', 280.0000, NULL, '180厚6%水泥稳定碎石基层；200厚级配碎石底基层；500厚三七灰土垫层（压实度≥95%）', 'item', 1610, 1),
(@template_id, NULL, '3.3', '道路', '临时进站道路面积', 'm²', 0.0000, NULL, '沥青混凝土路面：做法同上', 'item', 1620, 1),
(@template_id, NULL, '3.4', '道路', '花岗岩路缘石', 'm', 800.0000, NULL, '1000×300×120花岗岩路缘石', 'item', 1630, 1)
ON DUPLICATE KEY UPDATE
  project_name = VALUES(project_name),
  work_content = VALUES(work_content),
  unit = VALUES(unit),
  default_value = VALUES(default_value),
  default_text = VALUES(default_text),
  remark = VALUES(remark),
  row_type = VALUES(row_type),
  sort_order = VALUES(sort_order),
  is_required = VALUES(is_required);
