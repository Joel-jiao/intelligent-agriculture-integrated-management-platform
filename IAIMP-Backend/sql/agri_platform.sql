-- =====================================================================
-- 智慧农业综合管理平台 · MySQL 数据库建表脚本（根据 db.json 结构化设计）
-- 数据库版本：MySQL 8.0+
--
-- 说明：
--   1. 本脚本根据前端 json-server 的 db.json 全部 48 个集合，逐集合设计成
--      一张关系表；表名 = 集合名（camelCase 原样），字段名 = db.json 字段名。
--   2. 类型映射规则：
--        - 字符串          -> VARCHAR(合理长度)，长文本 -> TEXT
--        - 整数            -> INT / BIGINT
--        - 小数            -> DECIMAL(10,2)
--        - 布尔            -> TINYINT(1)
--        - 日期/时间       -> DATE / DATETIME（"YYYY-MM-DD"、"YYYY-MM-DD HH:MM[:SS]"）
--        - 数组/嵌套对象   -> JSON（多边形 polygon、权限 permissions、字典 items、
--                             环境曲线、天气 forecast 等）
--   3. 展示型字符串（如 "428 MB"、"32 分钟"、"1,260 kg"、"4.2 m"）保持 VARCHAR。
--   4. 数组集合的 `id` 为业务主键（VARCHAR）；单例对象集合（park/weather 等）
--      以自增 id 作为主键。
--
-- 执行方式：
--   mysql -u root -p < sql/agri_platform.sql
--   或直接在 Navicat / DataGrip 中打开并执行。
-- =====================================================================

CREATE DATABASE IF NOT EXISTS `agri_platform`
    DEFAULT CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE `agri_platform`;

-- =====================================================================
-- 一、认证与账号（accounts）
-- =====================================================================
CREATE TABLE IF NOT EXISTS `accounts` (
    `id`       VARCHAR(64)  NOT NULL COMMENT '账号ID（A-001）',
    `portal`   VARCHAR(16)  NOT NULL COMMENT '门户：admin/ops/sup/app',
    `account`  VARCHAR(64)  NOT NULL COMMENT '登录账号',
    `password` VARCHAR(100) NOT NULL COMMENT 'BCrypt 密码哈希',
    `name`     VARCHAR(64)  NOT NULL COMMENT '姓名',
    `role`     VARCHAR(64)  NOT NULL COMMENT '角色',
    `status`   VARCHAR(16)  NOT NULL DEFAULT '启用' COMMENT '启用/停用',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_portal_account` (`portal`, `account`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '登录账号（accounts）';

-- =====================================================================
-- 二、园区概览与系统信息
-- =====================================================================
CREATE TABLE IF NOT EXISTS `park` (
    `id`        BIGINT       NOT NULL AUTO_INCREMENT,
    `name`      VARCHAR(64)  NOT NULL COMMENT '园区名称',
    `shortName` VARCHAR(32)  NOT NULL COMMENT '简称',
    `location`  VARCHAR(128) NOT NULL COMMENT '地址',
    `area`      INT          NOT NULL DEFAULT 0 COMMENT '园区面积（亩）',
    `plots`     INT          NOT NULL DEFAULT 0 COMMENT '地块数',
    `farmers`   INT          NOT NULL DEFAULT 0 COMMENT '农户数',
    `manager`   VARCHAR(32)  NOT NULL COMMENT '负责人',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '园区概览（park，单例）';

CREATE TABLE IF NOT EXISTS `sysInfo` (
    `id`           BIGINT       NOT NULL AUTO_INCREMENT,
    `version`      VARCHAR(32)  NOT NULL COMMENT '系统版本',
    `env`          VARCHAR(32)  NOT NULL COMMENT '环境',
    `db`           VARCHAR(64)  NOT NULL COMMENT '数据库',
    `api`          VARCHAR(64)  NOT NULL COMMENT 'API 框架',
    `uptime`       VARCHAR(32)  NOT NULL COMMENT '运行时长（展示串）',
    `cpu`          INT          NOT NULL DEFAULT 0 COMMENT 'CPU 使用率',
    `memory`       INT          NOT NULL DEFAULT 0 COMMENT '内存使用率',
    `disk`         INT          NOT NULL DEFAULT 0 COMMENT '磁盘使用率',
    `onlineUsers`  INT          NOT NULL DEFAULT 0 COMMENT '在线用户数',
    `mqttMessages` BIGINT       NOT NULL DEFAULT 0 COMMENT 'MQTT 消息数',
    `apiCalls`     INT          NOT NULL DEFAULT 0 COMMENT 'API 调用数',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '系统信息（sysInfo，单例）';

CREATE TABLE IF NOT EXISTS `weather` (
    `id`          BIGINT        NOT NULL AUTO_INCREMENT,
    `temperature` INT           NOT NULL DEFAULT 0 COMMENT '温度',
    `humidity`    INT           NOT NULL DEFAULT 0 COMMENT '湿度',
    `condition`   VARCHAR(32)   NOT NULL COMMENT '天气状况',
    `wind`        VARCHAR(32)   NOT NULL COMMENT '风力风向',
    `rainfall`    DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT '降雨量',
    `forecast`    JSON          NOT NULL COMMENT '预报数组',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '实时天气（weather，单例）';

CREATE TABLE IF NOT EXISTS `screenConfig` (
    `id`           BIGINT      NOT NULL AUTO_INCREMENT,
    `sections`     JSON        NOT NULL COMMENT '大屏分区配置',
    `interval`     INT         NOT NULL DEFAULT 15 COMMENT '刷新间隔（秒）',
    `theme`        VARCHAR(32) NOT NULL COMMENT '主题',
    `resolution`   VARCHAR(32) NOT NULL COMMENT '分辨率',
    `defaultScope` VARCHAR(32) NOT NULL COMMENT '默认范围',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '大屏展示配置（screenConfig，单例）';

-- =====================================================================
-- 三、农场与地块
-- =====================================================================
CREATE TABLE IF NOT EXISTS `plots` (
    `id`              VARCHAR(64)   NOT NULL COMMENT '地块ID（P-01）',
    `code`            VARCHAR(32)   NOT NULL COMMENT '地块编码',
    `name`            VARCHAR(64)   NOT NULL COMMENT '地块名称',
    `crop`            VARCHAR(32)   NOT NULL COMMENT '作物',
    `variety`         VARCHAR(64)   NOT NULL COMMENT '品种',
    `area`            DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT '面积',
    `greenhouse`      VARCHAR(64)   NOT NULL COMMENT '温室类型',
    `stage`           VARCHAR(32)   NOT NULL COMMENT '生长阶段',
    `soil`            VARCHAR(32)   NOT NULL COMMENT '土壤',
    `manager`         VARCHAR(32)   NOT NULL COMMENT '负责人',
    `plantedAt`       DATE          NULL COMMENT '定植日期',
    `expectedHarvest` DATE          NULL COMMENT '预计采收',
    `status`          VARCHAR(16)   NOT NULL COMMENT '状态：正常/预警/休耕',
    `color`           VARCHAR(16)   NOT NULL COMMENT '地图颜色',
    `polygon`         JSON          NULL COMMENT '边界多边形坐标',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '地块档案（plots）';

CREATE TABLE IF NOT EXISTS `plotAudits` (
    `id`             VARCHAR(64)   NOT NULL COMMENT '审核ID（PA-01）',
    `plotCode`       VARCHAR(32)   NOT NULL COMMENT '地块编码',
    `plotName`       VARCHAR(64)   NOT NULL COMMENT '地块名称',
    `crop`           VARCHAR(32)   NOT NULL COMMENT '作物',
    `variety`        VARCHAR(64)   NOT NULL COMMENT '品种',
    `area`           DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT '面积',
    `greenhouse`     VARCHAR(64)   NOT NULL COMMENT '温室类型',
    `submitBy`       VARCHAR(32)   NOT NULL COMMENT '提交人',
    `farmerId`       VARCHAR(64)   NOT NULL COMMENT '农户ID',
    `submittedAt`    DATETIME      NULL COMMENT '提交时间',
    `status`         VARCHAR(16)   NOT NULL COMMENT '状态：待审核/已通过/已驳回',
    `boundaryClosed` TINYINT(1)    NOT NULL DEFAULT 0 COMMENT '边界是否闭合',
    `polygon`        JSON          NULL COMMENT '边界多边形',
    `rejectReason`   VARCHAR(255)  NULL COMMENT '驳回原因',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '地块档案审核（plotAudits）';

CREATE TABLE IF NOT EXISTS `farmerPlots` (
    `id`              VARCHAR(64)   NOT NULL COMMENT '地块ID',
    `name`            VARCHAR(64)   NOT NULL COMMENT '地块名称',
    `crop`            VARCHAR(32)   NOT NULL COMMENT '作物',
    `variety`         VARCHAR(64)   NOT NULL COMMENT '品种',
    `area`            DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT '面积',
    `greenhouse`      VARCHAR(64)   NOT NULL COMMENT '温室类型',
    `plantedAt`       DATE          NULL COMMENT '定植日期',
    `expectedHarvest` DATE          NULL COMMENT '预计采收',
    `auditStatus`     VARCHAR(16)   NOT NULL COMMENT '审核状态',
    `rejectReason`    VARCHAR(255)  NULL COMMENT '驳回原因',
    `deviceCount`     INT           NOT NULL DEFAULT 0 COMMENT '设备数',
    `envTemp`         DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT '环境温度',
    `envHumidity`     INT           NOT NULL DEFAULT 0 COMMENT '环境湿度',
    `polygon`         JSON          NULL COMMENT '边界多边形',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '农户地块（farmerPlots）';

CREATE TABLE IF NOT EXISTS `harvests` (
    `id`          VARCHAR(64) NOT NULL COMMENT '采收ID（HR-01）',
    `batchNo`     VARCHAR(64) NOT NULL COMMENT '批次号',
    `plot`        VARCHAR(64) NOT NULL COMMENT '地块',
    `crop`        VARCHAR(32) NOT NULL COMMENT '作物',
    `weight`      INT         NOT NULL DEFAULT 0 COMMENT '重量（kg）',
    `grade`       VARCHAR(16) NOT NULL COMMENT '等级：特级/一级/二级',
    `harvestedAt` DATETIME    NULL COMMENT '采收时间',
    `operator`    VARCHAR(32) NOT NULL COMMENT '操作人',
    `status`      VARCHAR(16) NOT NULL COMMENT '状态：待入库/已入库',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '采收登记（harvests）';

CREATE TABLE IF NOT EXISTS `materials` (
    `id`        VARCHAR(64)  NOT NULL COMMENT '农资ID（MAT-01）',
    `name`      VARCHAR(128) NOT NULL COMMENT '名称',
    `category`  VARCHAR(16)  NOT NULL COMMENT '分类：种子/化肥/农药/农膜/工具',
    `unit`      VARCHAR(16)  NOT NULL COMMENT '单位',
    `stock`     INT          NOT NULL DEFAULT 0 COMMENT '库存',
    `safeStock` INT          NOT NULL DEFAULT 0 COMMENT '安全库存',
    `supplier`  VARCHAR(64)  NOT NULL COMMENT '供应商',
    `batchNo`   VARCHAR(64)  NOT NULL COMMENT '批次号',
    `updatedAt` DATETIME     NULL COMMENT '更新时间',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '农资库存（materials）';

CREATE TABLE IF NOT EXISTS `workOrders` (
    `id`          VARCHAR(64)  NOT NULL COMMENT '工单ID（WO-...）',
    `title`       VARCHAR(128) NOT NULL COMMENT '标题',
    `plot`        VARCHAR(64)  NOT NULL COMMENT '地块',
    `crop`        VARCHAR(32)  NOT NULL COMMENT '作物',
    `type`        VARCHAR(32)  NOT NULL COMMENT '类型',
    `assignee`    VARCHAR(32)  NOT NULL COMMENT '执行人',
    `phone`       VARCHAR(32)  NOT NULL COMMENT '联系电话',
    `createdAt`   DATETIME     NULL COMMENT '创建时间',
    `deadline`    DATETIME     NULL COMMENT '截止时间',
    `status`      VARCHAR(16)  NOT NULL COMMENT '状态：待接单/进行中/待验收/已完成',
    `priority`    VARCHAR(16)  NOT NULL COMMENT '优先级：高/中/低',
    `progress`    INT          NOT NULL DEFAULT 0 COMMENT '进度（%）',
    `requirement` TEXT         NULL COMMENT '作业要求',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '农事工单（workOrders）';

CREATE TABLE IF NOT EXISTS `workOrderCheckins` (
    `id`       INT         NOT NULL COMMENT '打卡ID',
    `time`     DATETIME    NULL COMMENT '打卡时间',
    `lat`      VARCHAR(32) NOT NULL COMMENT '纬度',
    `lng`      VARCHAR(32) NOT NULL COMMENT '经度',
    `distance` VARCHAR(32) NOT NULL COMMENT '与地块距离（展示串）',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '工单打卡记录（workOrderCheckins）';

-- =====================================================================
-- 四、物联网
-- =====================================================================
CREATE TABLE IF NOT EXISTS `devices` (
    `id`       VARCHAR(64)   NOT NULL COMMENT '设备ID（DEV-101）',
    `name`     VARCHAR(64)   NOT NULL COMMENT '设备名称',
    `type`     VARCHAR(32)   NOT NULL COMMENT '类型',
    `plotId`   VARCHAR(64)   NOT NULL COMMENT '所属地块',
    `status`   VARCHAR(16)   NOT NULL COMMENT '状态：在线/离线/故障',
    `running`  TINYINT(1)    NOT NULL DEFAULT 0 COMMENT '是否运行中',
    `lastSeen` DATETIME      NULL COMMENT '最后在线时间',
    `protocol` VARCHAR(32)   NOT NULL COMMENT '协议',
    `power`    DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT '功率/能耗',
    `battery`  INT           NULL COMMENT '电量（%）',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '设备（devices）';

CREATE TABLE IF NOT EXISTS `cameras` (
    `id`         VARCHAR(64)  NOT NULL COMMENT '摄像头ID（CAM-01）',
    `name`       VARCHAR(64)  NOT NULL COMMENT '名称',
    `plot`       VARCHAR(64)  NOT NULL COMMENT '所属地块',
    `status`     VARCHAR(16)  NOT NULL COMMENT '状态：在线/离线',
    `resolution` VARCHAR(32)  NOT NULL COMMENT '分辨率',
    `stream`     VARCHAR(128) NOT NULL COMMENT '视频流地址',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '摄像头（cameras）';

CREATE TABLE IF NOT EXISTS `envSeries` (
    `id`               BIGINT NOT NULL AUTO_INCREMENT,
    `labels`           JSON   NOT NULL COMMENT '时间轴标签',
    `temperature`      JSON   NOT NULL COMMENT '温度曲线',
    `humidity`         JSON   NOT NULL COMMENT '湿度曲线',
    `soilTemperature`  JSON   NOT NULL COMMENT '土壤温度曲线',
    `soilMoisture`     JSON   NOT NULL COMMENT '土壤湿度曲线',
    `co2`              JSON   NOT NULL COMMENT 'CO2 曲线',
    `light`            JSON   NOT NULL COMMENT '光照曲线',
    `ph`               JSON   NOT NULL COMMENT 'pH 曲线',
    `waterTemperature` JSON   NOT NULL COMMENT '水温曲线',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '环境监测曲线（envSeries，单例）';

CREATE TABLE IF NOT EXISTS `deviceOpRecords` (
    `id`   INT          NOT NULL COMMENT '记录ID',
    `time` DATETIME     NULL COMMENT '操作时间',
    `text` VARCHAR(255) NOT NULL COMMENT '操作内容',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '设备操作记录（deviceOpRecords）';

CREATE TABLE IF NOT EXISTS `videoReplays` (
    `id`         VARCHAR(64) NOT NULL COMMENT '录像ID（R-01）',
    `cameraId`   VARCHAR(64) NOT NULL COMMENT '摄像头ID',
    `cameraName` VARCHAR(64) NOT NULL COMMENT '摄像头名称',
    `start`      DATETIME    NULL COMMENT '开始时间',
    `duration`   VARCHAR(32) NOT NULL COMMENT '时长（展示串）',
    `size`       VARCHAR(32) NOT NULL COMMENT '大小（展示串）',
    `daysAgo`    INT         NOT NULL DEFAULT 0 COMMENT '几天前',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '视频录像回放（videoReplays）';

-- =====================================================================
-- 五、能源
-- =====================================================================
CREATE TABLE IF NOT EXISTS `waterElectric` (
    `id`       BIGINT NOT NULL AUTO_INCREMENT,
    `months`   JSON   NOT NULL COMMENT '月份轴',
    `water`    JSON   NOT NULL COMMENT '用水量',
    `electric` JSON   NOT NULL COMMENT '用电量',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '水电计量统计（waterElectric，单例）';

-- =====================================================================
-- 六、告警与消息
-- =====================================================================
CREATE TABLE IF NOT EXISTS `alarms` (
    `id`        VARCHAR(64)  NOT NULL COMMENT '告警ID（ALM-...）',
    `level`     VARCHAR(16)  NOT NULL COMMENT '级别：紧急/重要/一般',
    `title`     VARCHAR(128) NOT NULL COMMENT '标题',
    `source`    VARCHAR(32)  NOT NULL COMMENT '来源',
    `device`    VARCHAR(64)  NOT NULL COMMENT '设备',
    `plot`      VARCHAR(64)  NOT NULL COMMENT '地块',
    `createdAt` DATETIME     NULL COMMENT '发生时间',
    `status`    VARCHAR(16)  NOT NULL COMMENT '状态：待确认/处置中/已归档',
    `value`     VARCHAR(64)  NOT NULL COMMENT '当前值',
    `threshold` VARCHAR(64)  NOT NULL COMMENT '阈值',
    `handler`   VARCHAR(32)  NOT NULL COMMENT '处理人',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '告警记录（alarms）';

CREATE TABLE IF NOT EXISTS `messages` (
    `id`    VARCHAR(64)  NOT NULL COMMENT '消息ID（MSG-01）',
    `title` VARCHAR(128) NOT NULL COMMENT '标题',
    `body`  TEXT         NULL COMMENT '内容',
    `time`  DATETIME     NULL COMMENT '时间',
    `level` VARCHAR(16)  NOT NULL COMMENT '级别：紧急/重要/一般',
    `read`  TINYINT(1)   NOT NULL DEFAULT 0 COMMENT '是否已读',
    `from`  VARCHAR(64)  NOT NULL COMMENT '来源',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '站内消息（messages）';

-- =====================================================================
-- 七、设备控制
-- =====================================================================
CREATE TABLE IF NOT EXISTS `controlLogs` (
    `id`     VARCHAR(64) NOT NULL COMMENT '日志ID（LOG-001）',
    `time`   DATETIME    NULL COMMENT '时间',
    `device` VARCHAR(64) NOT NULL COMMENT '设备',
    `action` VARCHAR(32) NOT NULL COMMENT '动作',
    `result` VARCHAR(16) NOT NULL COMMENT '结果',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '控制日志（controlLogs）';

CREATE TABLE IF NOT EXISTS `linkageStrategies` (
    `id`            VARCHAR(64) NOT NULL COMMENT '策略ID（LS-01）',
    `name`          VARCHAR(64) NOT NULL COMMENT '策略名称',
    `plotId`        VARCHAR(64) NOT NULL COMMENT '地块ID',
    `tempMin`       INT         NULL COMMENT '温度下限',
    `tempMax`       INT         NULL COMMENT '温度上限',
    `humidityMin`   INT         NULL COMMENT '湿度下限',
    `humidityMax`   INT         NULL COMMENT '湿度上限',
    `soilMin`       INT         NULL COMMENT '土壤湿度下限',
    `action`        VARCHAR(64) NOT NULL COMMENT '触发动作',
    `window`        VARCHAR(32) NOT NULL COMMENT '生效时段',
    `enabled`       TINYINT(1)  NOT NULL DEFAULT 1 COMMENT '是否启用',
    `lastTriggered` DATETIME    NULL COMMENT '最近触发时间',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '自动联动策略（linkageStrategies）';

CREATE TABLE IF NOT EXISTS `linkageLogs` (
    `id`       VARCHAR(64)  NOT NULL COMMENT '日志ID（EL-01）',
    `time`     DATETIME     NULL COMMENT '触发时间',
    `strategy` VARCHAR(64)  NOT NULL COMMENT '策略名称',
    `detail`   VARCHAR(255) NOT NULL COMMENT '触发详情',
    `result`   VARCHAR(16)  NOT NULL COMMENT '结果',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '联动执行日志（linkageLogs）';

CREATE TABLE IF NOT EXISTS `irrigationPlots` (
    `id`       VARCHAR(64) NOT NULL COMMENT '灌溉记录ID（IR-01）',
    `plotId`   VARCHAR(64) NOT NULL COMMENT '地块ID',
    `moisture` INT         NOT NULL DEFAULT 0 COMMENT '土壤湿度',
    `planned`  INT         NOT NULL DEFAULT 0 COMMENT '计划灌溉量',
    `status`   VARCHAR(16) NOT NULL COMMENT '状态',
    `lastRun`  DATETIME    NULL COMMENT '最近灌溉时间',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '灌溉地块明细（irrigationPlots）';

CREATE TABLE IF NOT EXISTS `irrigationSummary` (
    `id`         BIGINT        NOT NULL AUTO_INCREMENT,
    `todayWater` INT           NOT NULL DEFAULT 0 COMMENT '今日灌溉量',
    `todayArea`  DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT '今日灌溉面积',
    `savingRate` DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT '节水率（%）',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '灌溉今日统计（irrigationSummary，单例）';

-- =====================================================================
-- 八、产品溯源
-- =====================================================================
CREATE TABLE IF NOT EXISTS `batches` (
    `id`          VARCHAR(64) NOT NULL COMMENT '批次ID（TB-01）',
    `batchNo`     VARCHAR(64) NOT NULL COMMENT '批次号',
    `plot`        VARCHAR(64) NOT NULL COMMENT '地块',
    `crop`        VARCHAR(32) NOT NULL COMMENT '作物',
    `variety`     VARCHAR(64) NOT NULL COMMENT '品种',
    `plantedAt`   DATE        NULL COMMENT '定植日期',
    `harvestedAt` DATE        NULL COMMENT '采收日期',
    `weight`      INT         NOT NULL DEFAULT 0 COMMENT '重量（kg）',
    `grade`       VARCHAR(16) NOT NULL COMMENT '等级',
    `status`      VARCHAR(16) NOT NULL COMMENT '状态：已赋码/待赋码/已召回',
    `qrCount`     INT         NOT NULL DEFAULT 0 COMMENT '赋码数量',
    `scans`       INT         NOT NULL DEFAULT 0 COMMENT '扫码次数',
    PRIMARY KEY (`id`),
    KEY `idx_batch_no` (`batchNo`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '溯源批次档案（batches）';

CREATE TABLE IF NOT EXISTS `inspections` (
    `id`         VARCHAR(64)  NOT NULL COMMENT '检测ID（IR-01）',
    `batchNo`    VARCHAR(64)  NOT NULL COMMENT '批次号',
    `crop`       VARCHAR(32)  NOT NULL COMMENT '作物',
    `reportNo`   VARCHAR(64)  NOT NULL COMMENT '报告编号',
    `agency`     VARCHAR(128) NOT NULL COMMENT '检测机构',
    `testedAt`   DATE         NULL COMMENT '检测日期',
    `pesticide`  VARCHAR(64)  NOT NULL COMMENT '农药残留',
    `heavyMetal` VARCHAR(32)  NOT NULL COMMENT '重金属',
    `result`     VARCHAR(16)  NOT NULL COMMENT '结果：合格/不合格',
    `file`       VARCHAR(128) NOT NULL COMMENT '报告文件',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '检测报告（inspections）';

CREATE TABLE IF NOT EXISTS `recalls` (
    `id`        VARCHAR(64)  NOT NULL COMMENT '召回ID（RC-01）',
    `batchNo`   VARCHAR(64)  NOT NULL COMMENT '批次号',
    `crop`      VARCHAR(32)  NOT NULL COMMENT '作物',
    `reason`    VARCHAR(255) NOT NULL COMMENT '召回原因',
    `level`     VARCHAR(16)  NOT NULL COMMENT '级别：一级/二级',
    `createdAt` DATETIME     NULL COMMENT '发起时间',
    `affected`  INT          NOT NULL DEFAULT 0 COMMENT '受影响数量',
    `recovered` INT          NOT NULL DEFAULT 0 COMMENT '已召回数量',
    `status`    VARCHAR(16)  NOT NULL COMMENT '状态：通知中/召回中/已完成',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '产品召回记录（recalls）';

CREATE TABLE IF NOT EXISTS `traceDetail` (
    `id`          BIGINT       NOT NULL AUTO_INCREMENT,
    `batchNo`     VARCHAR(64)  NOT NULL COMMENT '批次号',
    `crop`        VARCHAR(32)  NOT NULL COMMENT '作物',
    `variety`     VARCHAR(64)  NOT NULL COMMENT '品种',
    `origin`      VARCHAR(128) NOT NULL COMMENT '产地',
    `grade`       VARCHAR(16)  NOT NULL COMMENT '等级',
    `weight`      VARCHAR(32)  NOT NULL COMMENT '重量（展示串）',
    `harvestedAt` DATE         NULL COMMENT '采收日期',
    `farmer`      VARCHAR(32)  NOT NULL COMMENT '农户',
    `plot`        VARCHAR(64)  NOT NULL COMMENT '地块',
    `scans`       INT          NOT NULL DEFAULT 0 COMMENT '扫码次数',
    `inspect`     JSON         NOT NULL COMMENT '检测信息',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '溯源详情（traceDetail，单例）';

CREATE TABLE IF NOT EXISTS `traceTimeline` (
    `id`    VARCHAR(64) NOT NULL COMMENT '时间线ID',
    `date`  DATE        NULL COMMENT '日期',
    `title` VARCHAR(64) NOT NULL COMMENT '节点标题',
    `desc`  TEXT        NULL COMMENT '节点描述',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '溯源时间线（traceTimeline）';

-- =====================================================================
-- 九、质量安全
-- =====================================================================
CREATE TABLE IF NOT EXISTS `qualityOverview` (
    `id`               BIGINT        NOT NULL AUTO_INCREMENT,
    `passRate`         DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT '合格率（%）',
    `inspectedBatches` INT           NOT NULL DEFAULT 0 COMMENT '检测批次数',
    `qualified`        INT           NOT NULL DEFAULT 0 COMMENT '合格批次',
    `unqualified`      INT           NOT NULL DEFAULT 0 COMMENT '不合格批次',
    `recalls`          INT           NOT NULL DEFAULT 0 COMMENT '召回次数',
    `pesticideChecks`  INT           NOT NULL DEFAULT 0 COMMENT '农残抽检次数',
    `trend`            JSON          NOT NULL COMMENT '趋势数组',
    `categories`       JSON          NOT NULL COMMENT '分类统计',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '质量安全总览（qualityOverview，单例）';

CREATE TABLE IF NOT EXISTS `pesticideLedger` (
    `id`         VARCHAR(64)  NOT NULL COMMENT '台账ID（PL-01）',
    `date`       DATE         NULL COMMENT '用药日期',
    `plot`       VARCHAR(64)  NOT NULL COMMENT '地块',
    `crop`       VARCHAR(32)  NOT NULL COMMENT '作物',
    `name`       VARCHAR(128) NOT NULL COMMENT '农药名称',
    `amount`     VARCHAR(32)  NOT NULL COMMENT '用量（展示串）',
    `operator`   VARCHAR(32)  NOT NULL COMMENT '操作人',
    `method`     VARCHAR(32)  NOT NULL COMMENT '施药方式',
    `safetyDays` INT          NOT NULL DEFAULT 0 COMMENT '安全间隔期（天）',
    `compliant`  TINYINT(1)   NOT NULL DEFAULT 1 COMMENT '是否合规',
    `note`       VARCHAR(255) NULL COMMENT '备注',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '农药农资使用台账（pesticideLedger）';

-- =====================================================================
-- 十、监管
-- =====================================================================
CREATE TABLE IF NOT EXISTS `supWarnings` (
    `id`        VARCHAR(64)  NOT NULL COMMENT '预警ID（SW-01）',
    `title`     VARCHAR(255) NOT NULL COMMENT '标题',
    `type`      VARCHAR(32)  NOT NULL COMMENT '类型',
    `entity`    VARCHAR(128) NOT NULL COMMENT '主体',
    `level`     VARCHAR(16)  NOT NULL COMMENT '级别：高/中/低',
    `createdAt` DATETIME     NULL COMMENT '发生时间',
    `status`    VARCHAR(16)  NOT NULL COMMENT '状态：待处理/处理中/已办结',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '监管预警（supWarnings）';

-- =====================================================================
-- 十一、系统管理
-- =====================================================================
CREATE TABLE IF NOT EXISTS `users` (
    `id`        VARCHAR(64) NOT NULL COMMENT '用户ID（U-001）',
    `account`   VARCHAR(64) NOT NULL COMMENT '账号',
    `name`      VARCHAR(64) NOT NULL COMMENT '姓名',
    `role`      VARCHAR(64) NOT NULL COMMENT '角色',
    `phone`     VARCHAR(32) NOT NULL COMMENT '手机号',
    `plotScope` VARCHAR(64) NOT NULL COMMENT '地块范围',
    `status`    VARCHAR(16) NOT NULL COMMENT '状态：启用/停用',
    `lastLogin` DATETIME    NULL COMMENT '最近登录',
    `createdAt` DATE        NULL COMMENT '创建日期',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '系统用户（users）';

CREATE TABLE IF NOT EXISTS `roles` (
    `id`          VARCHAR(64)  NOT NULL COMMENT '角色ID（R-01）',
    `name`        VARCHAR(64)  NOT NULL COMMENT '角色名',
    `code`        VARCHAR(32)  NOT NULL COMMENT '角色编码',
    `members`     INT          NOT NULL DEFAULT 0 COMMENT '成员数',
    `description` VARCHAR(255) NOT NULL COMMENT '描述',
    `permissions` JSON         NOT NULL COMMENT '权限列表',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '角色权限（roles）';

CREATE TABLE IF NOT EXISTS `loginLogs` (
    `id`      VARCHAR(64) NOT NULL COMMENT '日志ID（LL-...）',
    `account` VARCHAR(64) NOT NULL COMMENT '账号',
    `name`    VARCHAR(64) NOT NULL COMMENT '姓名',
    `action`  VARCHAR(64) NOT NULL COMMENT '动作',
    `module`  VARCHAR(32) NOT NULL COMMENT '模块',
    `ip`      VARCHAR(64) NOT NULL COMMENT 'IP',
    `time`    DATETIME    NULL COMMENT '时间',
    `result`  VARCHAR(16) NOT NULL COMMENT '结果：成功/失败',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '登录日志（loginLogs）';

CREATE TABLE IF NOT EXISTS `operationLogs` (
    `id`      VARCHAR(64)  NOT NULL COMMENT '日志ID（OL-01）',
    `account` VARCHAR(64)  NOT NULL COMMENT '账号',
    `name`    VARCHAR(64)  NOT NULL COMMENT '姓名',
    `action`  VARCHAR(128) NOT NULL COMMENT '动作',
    `module`  VARCHAR(32)  NOT NULL COMMENT '模块',
    `ip`      VARCHAR(64)  NOT NULL COMMENT 'IP',
    `time`    DATETIME     NULL COMMENT '时间',
    `result`  VARCHAR(16)  NOT NULL COMMENT '结果：成功/失败',
    `detail`  VARCHAR(255) NULL COMMENT '详情',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '操作审计日志（operationLogs）';

CREATE TABLE IF NOT EXISTS `backups` (
    `id`        VARCHAR(64)  NOT NULL COMMENT '备份ID（BK-01）',
    `name`      VARCHAR(128) NOT NULL COMMENT '备份文件名',
    `size`      VARCHAR(32)  NOT NULL COMMENT '大小（展示串）',
    `type`      VARCHAR(16)  NOT NULL COMMENT '类型：自动/手动',
    `createdAt` DATETIME     NULL COMMENT '创建时间',
    `status`    VARCHAR(16)  NOT NULL COMMENT '状态：成功/进行中/失败',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '数据库备份记录（backups）';

CREATE TABLE IF NOT EXISTS `openApis` (
    `id`        VARCHAR(64)  NOT NULL COMMENT '接口ID（API-01）',
    `name`      VARCHAR(128) NOT NULL COMMENT '名称',
    `path`      VARCHAR(128) NOT NULL COMMENT '路径',
    `method`    VARCHAR(16)  NOT NULL COMMENT '方法',
    `target`    VARCHAR(64)  NOT NULL COMMENT '目标服务',
    `enabled`   TINYINT(1)   NOT NULL DEFAULT 1 COMMENT '是否启用',
    `calls`     INT          NOT NULL DEFAULT 0 COMMENT '调用次数',
    `updatedAt` DATETIME     NULL COMMENT '更新时间',
    `key`       VARCHAR(64)  NOT NULL COMMENT '密钥',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '开放接口配置（openApis）';

CREATE TABLE IF NOT EXISTS `files` (
    `id`         VARCHAR(64)  NOT NULL COMMENT '文件ID（F-01）',
    `name`       VARCHAR(128) NOT NULL COMMENT '文件名',
    `type`       VARCHAR(16)  NOT NULL COMMENT '类型：图片/文档/视频',
    `size`       VARCHAR(32)  NOT NULL COMMENT '大小（展示串）',
    `uploader`   VARCHAR(64)  NOT NULL COMMENT '上传人',
    `uploadedAt` DATETIME     NULL COMMENT '上传时间',
    `url`        VARCHAR(255) NOT NULL COMMENT '访问地址',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '文件存储（files）';

CREATE TABLE IF NOT EXISTS `tenants` (
    `id`            VARCHAR(64)  NOT NULL COMMENT '租户ID（T-01）',
    `name`          VARCHAR(128) NOT NULL COMMENT '租户名称',
    `code`          VARCHAR(32)  NOT NULL COMMENT '租户编码',
    `contact`       VARCHAR(32)  NOT NULL COMMENT '联系人',
    `phone`         VARCHAR(32)  NOT NULL COMMENT '联系电话',
    `resourceQuota` VARCHAR(128) NOT NULL COMMENT '资源配额',
    `userCount`     INT          NOT NULL DEFAULT 0 COMMENT '用户数',
    `deviceCount`   INT          NOT NULL DEFAULT 0 COMMENT '设备数',
    `status`        VARCHAR(16)  NOT NULL COMMENT '状态：启用/停用',
    `createdAt`     DATE         NULL COMMENT '创建日期',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '租户信息（tenants）';

CREATE TABLE IF NOT EXISTS `dictTypes` (
    `id`    VARCHAR(64)  NOT NULL COMMENT '字典ID（DT-01）',
    `code`  VARCHAR(64)  NOT NULL COMMENT '字典编码',
    `name`  VARCHAR(64)  NOT NULL COMMENT '字典名称',
    `desc`  VARCHAR(255) NOT NULL COMMENT '描述',
    `items` JSON         NOT NULL COMMENT '字典项列表',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '数据字典（dictTypes）';

CREATE TABLE IF NOT EXISTS `loginDevices` (
    `id`      VARCHAR(64)  NOT NULL COMMENT '设备ID（D-01）',
    `name`    VARCHAR(128) NOT NULL COMMENT '设备名',
    `client`  VARCHAR(128) NOT NULL COMMENT '客户端',
    `ip`      VARCHAR(64)  NOT NULL COMMENT 'IP',
    `time`    DATETIME     NULL COMMENT '登录时间',
    `current` TINYINT(1)   NOT NULL DEFAULT 0 COMMENT '是否当前设备',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '登录设备（loginDevices）';

CREATE TABLE IF NOT EXISTS `opApiKeys` (
    `id`        VARCHAR(64)  NOT NULL COMMENT '密钥ID（K-01）',
    `name`      VARCHAR(64)  NOT NULL COMMENT '名称',
    `key`       VARCHAR(64)  NOT NULL COMMENT '密钥',
    `scope`     VARCHAR(128) NOT NULL COMMENT '权限范围',
    `createdAt` DATETIME     NULL COMMENT '创建时间',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '运维 API 密钥（opApiKeys）';

CREATE TABLE IF NOT EXISTS `opSessions` (
    `id`       VARCHAR(64)  NOT NULL COMMENT '会话ID（D-01）',
    `device`   VARCHAR(64)  NOT NULL COMMENT '设备',
    `browser`  VARCHAR(128) NOT NULL COMMENT '浏览器',
    `ip`       VARCHAR(64)  NOT NULL COMMENT 'IP',
    `location` VARCHAR(64)  NOT NULL COMMENT '位置',
    `time`     DATETIME     NULL COMMENT '时间',
    `current`  TINYINT(1)   NOT NULL DEFAULT 0 COMMENT '是否当前会话',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '运维在线会话（opSessions）';

CREATE TABLE IF NOT EXISTS `serviceHealth` (
    `id`      BIGINT       NOT NULL AUTO_INCREMENT,
    `name`    VARCHAR(64)  NOT NULL COMMENT '服务名',
    `desc`    VARCHAR(128) NOT NULL COMMENT '服务描述',
    `port`    INT          NOT NULL DEFAULT 0 COMMENT '端口',
    `version` VARCHAR(32)  NOT NULL COMMENT '版本',
    `uptime`  VARCHAR(32)  NOT NULL COMMENT '运行时长（展示串）',
    `latency` INT          NOT NULL DEFAULT 0 COMMENT '延迟（ms）',
    `status`  VARCHAR(16)  NOT NULL COMMENT '状态',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '服务健康（serviceHealth）';

-- =====================================================================
-- 十二、综合报表
-- =====================================================================
CREATE TABLE IF NOT EXISTS `monthlyReport` (
    `id`       VARCHAR(64) NOT NULL COMMENT '报表行ID',
    `month`    VARCHAR(16) NOT NULL COMMENT '月份',
    `water`    INT         NOT NULL DEFAULT 0 COMMENT '用水量',
    `electric` INT         NOT NULL DEFAULT 0 COMMENT '用电量',
    `cost`     INT         NOT NULL DEFAULT 0 COMMENT '成本',
    `alarms`   INT         NOT NULL DEFAULT 0 COMMENT '告警数',
    `orders`   INT         NOT NULL DEFAULT 0 COMMENT '工单数',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '月度报表（monthlyReport）';

CREATE TABLE IF NOT EXISTS `exportRecords` (
    `id`       INT          NOT NULL COMMENT '导出ID',
    `name`     VARCHAR(128) NOT NULL COMMENT '文件名',
    `format`   VARCHAR(32)  NOT NULL COMMENT '格式',
    `time`     DATETIME     NULL COMMENT '导出时间',
    `rows`     INT          NOT NULL DEFAULT 0 COMMENT '行数',
    `operator` VARCHAR(32)  NOT NULL COMMENT '操作人',
    `status`   VARCHAR(16)  NOT NULL COMMENT '状态',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '报表导出记录（exportRecords）';
