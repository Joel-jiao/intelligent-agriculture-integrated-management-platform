-- =====================================================================
-- 智慧农业综合管理平台 · 假数据 INSERT 脚本（由 db.json 自动生成）
-- 执行前请先执行 sql/agri_platform.sql 完成建库建表。
-- 说明：accounts.password 已转为 BCrypt 哈希，可直接用于后端登录。
-- 执行方式：mysql -u root -p agri_platform < sql/agri_platform_data.sql
-- =====================================================================

USE `agri_platform`;

-- ============ park（单例） ============
INSERT INTO `park` (`name`, `shortName`, `location`, `area`, `plots`, `farmers`, `manager`) VALUES ('云岭智慧农业示范园', '云岭农业', '重庆市璧山区现代农业园区', 286, 6, 12, '李明');

-- ============ accounts（4 条） ============
INSERT INTO `accounts` (`id`, `portal`, `account`, `password`, `name`, `role`, `status`) VALUES ('A-001', 'admin', 'admin', '$2a$10$2igZiWXZ64tfZ8zp2SrYN.IgE0z11xOAw/DhYZzdAvH/Ba0gkR3vC', '李明', '园区管理员', '启用');
INSERT INTO `accounts` (`id`, `portal`, `account`, `password`, `name`, `role`, `status`) VALUES ('A-002', 'ops', 'ops', '$2a$10$btAfrD7f1vY4J2jzc1t35eqBMDv.UnF.Oh3I8CzubZU.S7lCqv7T6', '张运维', '系统运维', '启用');
INSERT INTO `accounts` (`id`, `portal`, `account`, `password`, `name`, `role`, `status`) VALUES ('A-003', 'sup', 'sup01', '$2a$10$TCpHN2v6eYLjLoLnjVbsB.ejpdIkMr.LQPQGgbYGSFiz33akWDATa', '黄洁', '监管人员', '启用');
INSERT INTO `accounts` (`id`, `portal`, `account`, `password`, `name`, `role`, `status`) VALUES ('A-004', 'app', 'wangq', '$2a$10$FhJi4RnCascDq0sivIBozOUk7WV.tYvsky6O0elBH271zvAbURwk2', '王强', '农户', '启用');

-- ============ weather（单例） ============
INSERT INTO `weather` (`temperature`, `humidity`, `condition`, `wind`, `rainfall`, `forecast`) VALUES (26, 68, '多云转晴', '东南风 2级', 0.4, '[{"day":"今天","high":27,"low":18,"icon":"云"},{"day":"明天","high":29,"low":19,"icon":"晴"},{"day":"后天","high":25,"low":17,"icon":"雨"}]');

-- ============ plots（6 条） ============
INSERT INTO `plots` (`id`, `code`, `name`, `crop`, `variety`, `area`, `greenhouse`, `stage`, `soil`, `manager`, `plantedAt`, `expectedHarvest`, `status`, `color`, `polygon`) VALUES ('P-01', 'P-01', '1号智能大棚', '番茄', '云粉 9 号', 12.8, '连栋薄膜温室', '结果期', '壤土', '王强', '2026-08-12', '2026-11-20', '正常', '#4fae74', '[{"x":78,"y":92},{"x":298,"y":82},{"x":320,"y":236},{"x":92,"y":252}]');
INSERT INTO `plots` (`id`, `code`, `name`, `crop`, `variety`, `area`, `greenhouse`, `stage`, `soil`, `manager`, `plantedAt`, `expectedHarvest`, `status`, `color`, `polygon`) VALUES ('P-02', 'P-02', '2号草莓棚', '草莓', '红颜', 8.6, '日光温室', '开花期', '砂壤土', '赵敏', '2026-09-02', '2026-12-10', '正常', '#d56b6b', '[{"x":342,"y":78},{"x":546,"y":86},{"x":556,"y":232},{"x":352,"y":244}]');
INSERT INTO `plots` (`id`, `code`, `name`, `crop`, `variety`, `area`, `greenhouse`, `stage`, `soil`, `manager`, `plantedAt`, `expectedHarvest`, `status`, `color`, `polygon`) VALUES ('P-03', 'P-03', '3号黄瓜棚', '黄瓜', '津优 35', 10.2, '连栋薄膜温室', '采收期', '壤土', '陈刚', '2026-07-26', '2026-10-30', '预警', '#3d8f5c', '[{"x":602,"y":88},{"x":820,"y":92},{"x":842,"y":246},{"x":612,"y":258}]');
INSERT INTO `plots` (`id`, `code`, `name`, `crop`, `variety`, `area`, `greenhouse`, `stage`, `soil`, `manager`, `plantedAt`, `expectedHarvest`, `status`, `color`, `polygon`) VALUES ('P-04', 'P-04', '露天 A 区果园', '柑橘', '爱媛 38', 32.5, '露天种植', '果实膨大期', '紫色土', '周涛', '2024-03-18', '2026-12-05', '正常', '#c9973f', '[{"x":102,"y":322},{"x":330,"y":310},{"x":352,"y":486},{"x":112,"y":498}]');
INSERT INTO `plots` (`id`, `code`, `name`, `crop`, `variety`, `area`, `greenhouse`, `stage`, `soil`, `manager`, `plantedAt`, `expectedHarvest`, `status`, `color`, `polygon`) VALUES ('P-05', 'P-05', '露天 B 区稻田', '水稻', '宜香优 2115', 48.2, '露天种植', '灌浆期', '水稻土', '刘洋', '2026-05-20', '2026-10-28', '正常', '#6a9e3f', '[{"x":398,"y":300},{"x":702,"y":296},{"x":712,"y":498},{"x":410,"y":504}]');
INSERT INTO `plots` (`id`, `code`, `name`, `crop`, `variety`, `area`, `greenhouse`, `stage`, `soil`, `manager`, `plantedAt`, `expectedHarvest`, `status`, `color`, `polygon`) VALUES ('P-06', 'P-06', '育苗棚', '辣椒苗', '螺丝椒', 3.4, '育苗温室', '苗期', '基质土', '赵敏', '2026-10-12', '2026-12-28', '休耕', '#8fb05f', '[{"x":748,"y":320},{"x":900,"y":318},{"x":912,"y":468},{"x":758,"y":478}]');

-- ============ cameras（6 条） ============
INSERT INTO `cameras` (`id`, `name`, `plot`, `status`, `resolution`, `stream`) VALUES ('CAM-01', '1号大棚 · 东侧', 'P-01', '在线', '1920×1080', 'rtsp://cam01/live');
INSERT INTO `cameras` (`id`, `name`, `plot`, `status`, `resolution`, `stream`) VALUES ('CAM-02', '1号大棚 · 西侧', 'P-01', '在线', '1920×1080', 'rtsp://cam02/live');
INSERT INTO `cameras` (`id`, `name`, `plot`, `status`, `resolution`, `stream`) VALUES ('CAM-03', '2号草莓棚 · 入口', 'P-02', '在线', '1280×720', 'rtsp://cam03/live');
INSERT INTO `cameras` (`id`, `name`, `plot`, `status`, `resolution`, `stream`) VALUES ('CAM-04', '3号黄瓜棚 · 中部', 'P-03', '在线', '1920×1080', 'rtsp://cam04/live');
INSERT INTO `cameras` (`id`, `name`, `plot`, `status`, `resolution`, `stream`) VALUES ('CAM-05', '露天果园 · 全景', 'P-04', '离线', '2560×1440', 'rtsp://cam05/live');
INSERT INTO `cameras` (`id`, `name`, `plot`, `status`, `resolution`, `stream`) VALUES ('CAM-06', '稻田 · 灌渠', 'P-05', '在线', '1920×1080', 'rtsp://cam06/live');

-- ============ devices（17 条） ============
INSERT INTO `devices` (`id`, `name`, `type`, `plotId`, `status`, `running`, `lastSeen`, `protocol`, `power`, `battery`) VALUES ('DEV-101', '1号棚水泵', '水泵', 'P-01', '在线', 1, '2026-11-06 09:42:18', 'MQTT', 2.2, NULL);
INSERT INTO `devices` (`id`, `name`, `type`, `plotId`, `status`, `running`, `lastSeen`, `protocol`, `power`, `battery`) VALUES ('DEV-102', '1号棚环流风机', '风机', 'P-01', '在线', 1, '2026-11-06 09:42:10', 'MQTT', 1.5, NULL);
INSERT INTO `devices` (`id`, `name`, `type`, `plotId`, `status`, `running`, `lastSeen`, `protocol`, `power`, `battery`) VALUES ('DEV-103', '1号棚外遮阳卷帘', '卷帘', 'P-01', '在线', 0, '2026-11-06 09:41:58', 'Modbus', 0.75, NULL);
INSERT INTO `devices` (`id`, `name`, `type`, `plotId`, `status`, `running`, `lastSeen`, `protocol`, `power`, `battery`) VALUES ('DEV-104', '1号棚补光灯组', '补光灯', 'P-01', '在线', 0, '2026-11-06 09:42:01', 'MQTT', 3.6, NULL);
INSERT INTO `devices` (`id`, `name`, `type`, `plotId`, `status`, `running`, `lastSeen`, `protocol`, `power`, `battery`) VALUES ('DEV-105', '2号棚滴灌电磁阀', '电磁阀', 'P-02', '在线', 1, '2026-11-06 09:42:22', 'MQTT', 0.3, NULL);
INSERT INTO `devices` (`id`, `name`, `type`, `plotId`, `status`, `running`, `lastSeen`, `protocol`, `power`, `battery`) VALUES ('DEV-106', '2号棚加温风机', '风机', 'P-02', '在线', 0, '2026-11-06 09:42:02', 'MQTT', 1.5, NULL);
INSERT INTO `devices` (`id`, `name`, `type`, `plotId`, `status`, `running`, `lastSeen`, `protocol`, `power`, `battery`) VALUES ('DEV-107', '3号棚水泵', '水泵', 'P-03', '故障', 0, '2026-11-06 08:56:33', 'MQTT', 2.2, NULL);
INSERT INTO `devices` (`id`, `name`, `type`, `plotId`, `status`, `running`, `lastSeen`, `protocol`, `power`, `battery`) VALUES ('DEV-108', '3号棚内遮阳卷帘', '卷帘', 'P-03', '在线', 0, '2026-11-06 09:42:05', 'Modbus', 0.75, NULL);
INSERT INTO `devices` (`id`, `name`, `type`, `plotId`, `status`, `running`, `lastSeen`, `protocol`, `power`, `battery`) VALUES ('DEV-109', 'A区灌溉泵', '水泵', 'P-04', '在线', 0, '2026-11-06 09:41:49', 'Modbus', 5.5, NULL);
INSERT INTO `devices` (`id`, `name`, `type`, `plotId`, `status`, `running`, `lastSeen`, `protocol`, `power`, `battery`) VALUES ('DEV-110', 'A区电磁阀 1', '电磁阀', 'P-04', '在线', 0, '2026-11-06 09:41:51', 'Modbus', 0.3, NULL);
INSERT INTO `devices` (`id`, `name`, `type`, `plotId`, `status`, `running`, `lastSeen`, `protocol`, `power`, `battery`) VALUES ('DEV-111', 'B区排灌泵', '水泵', 'P-05', '在线', 1, '2026-11-06 09:42:14', 'MQTT', 7.5, NULL);
INSERT INTO `devices` (`id`, `name`, `type`, `plotId`, `status`, `running`, `lastSeen`, `protocol`, `power`, `battery`) VALUES ('DEV-112', '育苗棚补光灯', '补光灯', 'P-06', '在线', 0, '2026-11-06 09:41:55', 'MQTT', 2.4, NULL);
INSERT INTO `devices` (`id`, `name`, `type`, `plotId`, `status`, `running`, `lastSeen`, `protocol`, `power`, `battery`) VALUES ('DEV-201', '1号棚环境传感器', '传感器', 'P-01', '在线', 1, '2026-11-06 09:42:24', 'RS485', 0.1, 92);
INSERT INTO `devices` (`id`, `name`, `type`, `plotId`, `status`, `running`, `lastSeen`, `protocol`, `power`, `battery`) VALUES ('DEV-202', '2号棚环境传感器', '传感器', 'P-02', '在线', 1, '2026-11-06 09:42:21', 'RS485', 0.1, 88);
INSERT INTO `devices` (`id`, `name`, `type`, `plotId`, `status`, `running`, `lastSeen`, `protocol`, `power`, `battery`) VALUES ('DEV-203', '3号棚环境传感器', '传感器', 'P-03', '在线', 1, '2026-11-06 09:42:17', 'RS485', 0.1, 76);
INSERT INTO `devices` (`id`, `name`, `type`, `plotId`, `status`, `running`, `lastSeen`, `protocol`, `power`, `battery`) VALUES ('DEV-204', 'B区水质传感器', '传感器', 'P-05', '离线', 0, '2026-11-06 07:12:08', 'RS485', 0.1, 12);
INSERT INTO `devices` (`id`, `name`, `type`, `plotId`, `status`, `running`, `lastSeen`, `protocol`, `power`, `battery`) VALUES ('DEV-301', '园区主网关', '网关', 'P-01', '在线', 1, '2026-11-06 09:42:25', 'MQTT', 12, NULL);

-- ============ alarms（8 条） ============
INSERT INTO `alarms` (`id`, `level`, `title`, `source`, `device`, `plot`, `createdAt`, `status`, `value`, `threshold`, `handler`) VALUES ('ALM-20261106-01', '紧急', '3号黄瓜棚水泵故障停机', '设备状态', 'DEV-107', 'P-03', '2026-11-06 08:56', '待确认', '运行电流 0 A', '额定 ≥ 3.2 A', '—');
INSERT INTO `alarms` (`id`, `level`, `title`, `source`, `device`, `plot`, `createdAt`, `status`, `value`, `threshold`, `handler`) VALUES ('ALM-20261106-02', '重要', '3号棚空气温度超过上限', '环境监测', 'DEV-203', 'P-03', '2026-11-06 09:12', '处置中', '36.4 ℃', '上限 32 ℃', '李明');
INSERT INTO `alarms` (`id`, `level`, `title`, `source`, `device`, `plot`, `createdAt`, `status`, `value`, `threshold`, `handler`) VALUES ('ALM-20261106-03', '重要', 'B区水质传感器电量不足', '设备状态', 'DEV-204', 'P-05', '2026-11-06 07:15', '待确认', '电量 12%', '预警 < 20%', '—');
INSERT INTO `alarms` (`id`, `level`, `title`, `source`, `device`, `plot`, `createdAt`, `status`, `value`, `threshold`, `handler`) VALUES ('ALM-20261105-04', '一般', '2号草莓棚土壤湿度偏低', '环境监测', 'DEV-202', 'P-02', '2026-11-05 16:40', '已归档', '土壤湿度 38%', '下限 45%', '赵敏');
INSERT INTO `alarms` (`id`, `level`, `title`, `source`, `device`, `plot`, `createdAt`, `status`, `value`, `threshold`, `handler`) VALUES ('ALM-20261105-05', '一般', '1号棚 CO₂ 浓度偏低', '环境监测', 'DEV-201', 'P-01', '2026-11-05 14:22', '已归档', '412 ppm', '下限 450 ppm', '王强');
INSERT INTO `alarms` (`id`, `level`, `title`, `source`, `device`, `plot`, `createdAt`, `status`, `value`, `threshold`, `handler`) VALUES ('ALM-20261105-06', '紧急', 'A区摄像头离线', '视频监控', 'CAM-05', 'P-04', '2026-11-05 11:08', '已归档', '连接超时', '在线', '运维组');
INSERT INTO `alarms` (`id`, `level`, `title`, `source`, `device`, `plot`, `createdAt`, `status`, `value`, `threshold`, `handler`) VALUES ('ALM-20261104-07', '重要', 'A区灌溉泵累计运行超时', '能耗监测', 'DEV-109', 'P-04', '2026-11-04 19:36', '已归档', '连续运行 4.2 h', '上限 3 h', '周涛');
INSERT INTO `alarms` (`id`, `level`, `title`, `source`, `device`, `plot`, `createdAt`, `status`, `value`, `threshold`, `handler`) VALUES ('ALM-20261104-08', '一般', '育苗棚光照强度不足', '环境监测', 'DEV-203', 'P-06', '2026-11-04 09:05', '已归档', '光照 860 lux', '下限 1200 lux', '赵敏');

-- ============ workOrders（8 条） ============
INSERT INTO `workOrders` (`id`, `title`, `plot`, `crop`, `type`, `assignee`, `phone`, `createdAt`, `deadline`, `status`, `priority`, `progress`, `requirement`) VALUES ('WO-20261106-01', '3号棚黄瓜采收与分级', 'P-03', '黄瓜', '采收作业', '陈刚', '138****6210', '2026-11-06 08:20', '2026-11-06 18:00', '进行中', '高', 55, '完成 3 号棚东侧 6 垄黄瓜采收，按特级、一级、二级分筐装运，采收后同步记录单筐重量。');
INSERT INTO `workOrders` (`id`, `title`, `plot`, `crop`, `type`, `assignee`, `phone`, `createdAt`, `deadline`, `status`, `priority`, `progress`, `requirement`) VALUES ('WO-20261106-02', '1号棚番茄打叶与绑蔓', 'P-01', '番茄', '植株管理', '王强', '139****8832', '2026-11-06 07:50', '2026-11-07 12:00', '进行中', '中', 30, '清除下部老叶与病叶，绑蔓高度控制在 1.6 米，作业后上传现场照片。');
INSERT INTO `workOrders` (`id`, `title`, `plot`, `crop`, `type`, `assignee`, `phone`, `createdAt`, `deadline`, `status`, `priority`, `progress`, `requirement`) VALUES ('WO-20261106-03', '2号棚滴灌系统巡检', 'P-02', '草莓', '设备巡检', '赵敏', '137****4109', '2026-11-06 07:30', '2026-11-06 15:00', '待接单', '中', 0, '检查滴灌带出水均匀度，清理过滤器，记录主管压力与流量。');
INSERT INTO `workOrders` (`id`, `title`, `plot`, `crop`, `type`, `assignee`, `phone`, `createdAt`, `deadline`, `status`, `priority`, `progress`, `requirement`) VALUES ('WO-20261106-04', 'B区稻田灌浆期水肥管理', 'P-05', '水稻', '水肥管理', '刘洋', '136****7521', '2026-11-05 16:10', '2026-11-07 10:00', '进行中', '高', 42, '保持浅水层 3-5 cm，追施磷酸二氢钾 2 kg/亩，注意避免倒伏。');
INSERT INTO `workOrders` (`id`, `title`, `plot`, `crop`, `type`, `assignee`, `phone`, `createdAt`, `deadline`, `status`, `priority`, `progress`, `requirement`) VALUES ('WO-20261105-05', 'A区柑橘果园病枝清理', 'P-04', '柑橘', '植保作业', '周涛', '135****3390', '2026-11-05 14:40', '2026-11-06 17:00', '待验收', '中', 100, '剪除感染枝条并集中处理，作业后喷洒生物制剂，上传病枝处理照片。');
INSERT INTO `workOrders` (`id`, `title`, `plot`, `crop`, `type`, `assignee`, `phone`, `createdAt`, `deadline`, `status`, `priority`, `progress`, `requirement`) VALUES ('WO-20261105-06', '育苗棚辣椒苗间苗', 'P-06', '辣椒苗', '植株管理', '赵敏', '137****4109', '2026-11-05 09:20', '2026-11-06 12:00', '已完成', '低', 100, '按 3 cm 株距间苗，去除弱苗与病苗，记录间苗数量。');
INSERT INTO `workOrders` (`id`, `title`, `plot`, `crop`, `type`, `assignee`, `phone`, `createdAt`, `deadline`, `status`, `priority`, `progress`, `requirement`) VALUES ('WO-20261104-07', '3号棚黄板更换', 'P-03', '黄瓜', '植保作业', '陈刚', '138****6210', '2026-11-04 15:30', '2026-11-05 18:00', '已完成', '低', 100, '更换黄板 40 张，记录粘虫数量并上报虫情。');
INSERT INTO `workOrders` (`id`, `title`, `plot`, `crop`, `type`, `assignee`, `phone`, `createdAt`, `deadline`, `status`, `priority`, `progress`, `requirement`) VALUES ('WO-20261104-08', 'A区灌溉管道冬季保温', 'P-04', '柑橘', '设施维护', '周涛', '135****3390', '2026-11-04 10:00', '2026-11-08 17:00', '待接单', '中', 0, '对暴露管道加装保温棉，检查阀门密封性，完成后拍照留档。');

-- ============ materials（8 条） ============
INSERT INTO `materials` (`id`, `name`, `category`, `unit`, `stock`, `safeStock`, `supplier`, `batchNo`, `updatedAt`) VALUES ('MAT-01', '云粉 9 号番茄种子', '种子', '袋', 24, 10, '重庆种业有限公司', 'SD20260812', '2026-11-05 14:20');
INSERT INTO `materials` (`id`, `name`, `category`, `unit`, `stock`, `safeStock`, `supplier`, `batchNo`, `updatedAt`) VALUES ('MAT-02', '红颜草莓苗', '种子', '株', 1200, 800, '璧山苗木合作社', 'SD20260902', '2026-11-05 10:12');
INSERT INTO `materials` (`id`, `name`, `category`, `unit`, `stock`, `safeStock`, `supplier`, `batchNo`, `updatedAt`) VALUES ('MAT-03', '复合肥 15-15-15', '化肥', 'kg', 380, 300, '中化化肥西南分公司', 'FERT20261018', '2026-11-04 16:35');
INSERT INTO `materials` (`id`, `name`, `category`, `unit`, `stock`, `safeStock`, `supplier`, `batchNo`, `updatedAt`) VALUES ('MAT-04', '磷酸二氢钾', '化肥', 'kg', 68, 100, '中化化肥西南分公司', 'FERT20260926', '2026-11-04 09:28');
INSERT INTO `materials` (`id`, `name`, `category`, `unit`, `stock`, `safeStock`, `supplier`, `batchNo`, `updatedAt`) VALUES ('MAT-05', '生物杀虫剂苏云金杆菌', '农药', '瓶', 18, 12, '绿源生物科技', 'PEST20260930', '2026-11-03 15:42');
INSERT INTO `materials` (`id`, `name`, `category`, `unit`, `stock`, `safeStock`, `supplier`, `batchNo`, `updatedAt`) VALUES ('MAT-06', '黄板诱虫贴', '工具', '张', 22, 50, '农友农资店', 'TOOL20261012', '2026-11-03 11:05');
INSERT INTO `materials` (`id`, `name`, `category`, `unit`, `stock`, `safeStock`, `supplier`, `batchNo`, `updatedAt`) VALUES ('MAT-07', '滴灌带 Φ16', '工具', '卷', 9, 6, '润丰灌溉设备', 'TOOL20260820', '2026-11-01 14:16');
INSERT INTO `materials` (`id`, `name`, `category`, `unit`, `stock`, `safeStock`, `supplier`, `batchNo`, `updatedAt`) VALUES ('MAT-08', '温室保温膜', '农膜', '卷', 5, 8, '渝西农膜厂', 'FILM20261008', '2026-10-30 09:30');

-- ============ harvests（6 条） ============
INSERT INTO `harvests` (`id`, `batchNo`, `plot`, `crop`, `weight`, `grade`, `harvestedAt`, `operator`, `status`) VALUES ('HR-01', 'B20261105-03', 'P-03', '黄瓜', 1260, '一级', '2026-11-05 16:30', '陈刚', '已入库');
INSERT INTO `harvests` (`id`, `batchNo`, `plot`, `crop`, `weight`, `grade`, `harvestedAt`, `operator`, `status`) VALUES ('HR-02', 'B20261105-04', 'P-01', '番茄', 860, '特级', '2026-11-05 10:15', '王强', '已入库');
INSERT INTO `harvests` (`id`, `batchNo`, `plot`, `crop`, `weight`, `grade`, `harvestedAt`, `operator`, `status`) VALUES ('HR-03', 'B20261104-02', 'P-02', '草莓', 420, '特级', '2026-11-04 08:40', '赵敏', '已入库');
INSERT INTO `harvests` (`id`, `batchNo`, `plot`, `crop`, `weight`, `grade`, `harvestedAt`, `operator`, `status`) VALUES ('HR-04', 'B20261103-01', 'P-05', '水稻', 5200, '一级', '2026-11-03 15:20', '刘洋', '待入库');
INSERT INTO `harvests` (`id`, `batchNo`, `plot`, `crop`, `weight`, `grade`, `harvestedAt`, `operator`, `status`) VALUES ('HR-05', 'B20261102-05', 'P-04', '柑橘', 3100, '一级', '2026-11-02 11:00', '周涛', '已入库');
INSERT INTO `harvests` (`id`, `batchNo`, `plot`, `crop`, `weight`, `grade`, `harvestedAt`, `operator`, `status`) VALUES ('HR-06', 'B20261030-06', 'P-03', '黄瓜', 980, '二级', '2026-10-30 17:10', '陈刚', '已入库');

-- ============ batches（6 条） ============
INSERT INTO `batches` (`id`, `batchNo`, `plot`, `crop`, `variety`, `plantedAt`, `harvestedAt`, `weight`, `grade`, `status`, `qrCount`, `scans`) VALUES ('TB-01', 'B20261105-03', 'P-03', '黄瓜', '津优 35', '2026-07-26', '2026-11-05', 1260, '一级', '已赋码', 1260, 386);
INSERT INTO `batches` (`id`, `batchNo`, `plot`, `crop`, `variety`, `plantedAt`, `harvestedAt`, `weight`, `grade`, `status`, `qrCount`, `scans`) VALUES ('TB-02', 'B20261105-04', 'P-01', '番茄', '云粉 9 号', '2026-08-12', '2026-11-05', 860, '特级', '已赋码', 860, 254);
INSERT INTO `batches` (`id`, `batchNo`, `plot`, `crop`, `variety`, `plantedAt`, `harvestedAt`, `weight`, `grade`, `status`, `qrCount`, `scans`) VALUES ('TB-03', 'B20261104-02', 'P-02', '草莓', '红颜', '2026-09-02', '2026-11-04', 420, '特级', '待赋码', 0, 0);
INSERT INTO `batches` (`id`, `batchNo`, `plot`, `crop`, `variety`, `plantedAt`, `harvestedAt`, `weight`, `grade`, `status`, `qrCount`, `scans`) VALUES ('TB-04', 'B20261103-01', 'P-05', '水稻', '宜香优 2115', '2026-05-20', '2026-11-03', 5200, '一级', '待赋码', 0, 0);
INSERT INTO `batches` (`id`, `batchNo`, `plot`, `crop`, `variety`, `plantedAt`, `harvestedAt`, `weight`, `grade`, `status`, `qrCount`, `scans`) VALUES ('TB-05', 'B20261030-06', 'P-03', '黄瓜', '津优 35', '2026-07-26', '2026-10-30', 980, '二级', '已召回', 980, 122);
INSERT INTO `batches` (`id`, `batchNo`, `plot`, `crop`, `variety`, `plantedAt`, `harvestedAt`, `weight`, `grade`, `status`, `qrCount`, `scans`) VALUES ('TB-06', 'B20261102-05', 'P-04', '柑橘', '爱媛 38', '2024-03-18', '2026-11-02', 3100, '一级', '已赋码', 3100, 915);

-- ============ inspections（5 条） ============
INSERT INTO `inspections` (`id`, `batchNo`, `crop`, `reportNo`, `agency`, `testedAt`, `pesticide`, `heavyMetal`, `result`, `file`) VALUES ('IR-01', 'B20261105-03', '黄瓜', 'CQ-JC-20261105-031', '重庆市农产品质量检测中心', '2026-11-05', '未检出', '合格', '合格', '黄瓜检测报告_20261105.pdf');
INSERT INTO `inspections` (`id`, `batchNo`, `crop`, `reportNo`, `agency`, `testedAt`, `pesticide`, `heavyMetal`, `result`, `file`) VALUES ('IR-02', 'B20261105-04', '番茄', 'CQ-JC-20261105-032', '重庆市农产品质量检测中心', '2026-11-05', '未检出', '合格', '合格', '番茄检测报告_20261105.pdf');
INSERT INTO `inspections` (`id`, `batchNo`, `crop`, `reportNo`, `agency`, `testedAt`, `pesticide`, `heavyMetal`, `result`, `file`) VALUES ('IR-03', 'B20261104-02', '草莓', 'CQ-JC-20261104-018', '璧山区农产品检测站', '2026-11-04', '未检出', '合格', '合格', '草莓检测报告_20261104.pdf');
INSERT INTO `inspections` (`id`, `batchNo`, `crop`, `reportNo`, `agency`, `testedAt`, `pesticide`, `heavyMetal`, `result`, `file`) VALUES ('IR-04', 'B20261030-06', '黄瓜', 'CQ-JC-20261030-096', '璧山区农产品检测站', '2026-10-30', '检出 0.03 mg/kg', '合格', '不合格', '黄瓜检测报告_20261030.pdf');
INSERT INTO `inspections` (`id`, `batchNo`, `crop`, `reportNo`, `agency`, `testedAt`, `pesticide`, `heavyMetal`, `result`, `file`) VALUES ('IR-05', 'B20261102-05', '柑橘', 'CQ-JC-20261102-044', '重庆市农产品质量检测中心', '2026-11-02', '未检出', '合格', '合格', '柑橘检测报告_20261102.pdf');

-- ============ recalls（3 条） ============
INSERT INTO `recalls` (`id`, `batchNo`, `crop`, `reason`, `level`, `createdAt`, `affected`, `recovered`, `status`) VALUES ('RC-01', 'B20261030-06', '黄瓜', '农残检测结果超出内部验收标准，存在质量风险', '二级', '2026-11-01 09:30', 980, 760, '召回中');
INSERT INTO `recalls` (`id`, `batchNo`, `crop`, `reason`, `level`, `createdAt`, `affected`, `recovered`, `status`) VALUES ('RC-02', 'B20261025-02', '番茄', '包装标签批次信息打印错误', '二级', '2026-10-27 14:10', 320, 320, '已完成');
INSERT INTO `recalls` (`id`, `batchNo`, `crop`, `reason`, `level`, `createdAt`, `affected`, `recovered`, `status`) VALUES ('RC-03', 'B20261018-04', '草莓', '冷链运输温度异常，果实品质下降', '一级', '2026-10-19 08:20', 260, 248, '已完成');

-- ============ users（8 条） ============
INSERT INTO `users` (`id`, `account`, `name`, `role`, `phone`, `plotScope`, `status`, `lastLogin`, `createdAt`) VALUES ('U-001', 'admin', '李明', '园区管理员', '138****0001', '全部地块', '启用', '2026-11-06 09:32', '2026-03-01');
INSERT INTO `users` (`id`, `account`, `name`, `role`, `phone`, `plotScope`, `status`, `lastLogin`, `createdAt`) VALUES ('U-002', 'wangq', '王强', '农户', '139****8832', 'P-01', '启用', '2026-11-06 08:12', '2026-03-12');
INSERT INTO `users` (`id`, `account`, `name`, `role`, `phone`, `plotScope`, `status`, `lastLogin`, `createdAt`) VALUES ('U-003', 'zhaom', '赵敏', '农户', '137****4109', 'P-02、P-06', '启用', '2026-11-06 07:48', '2026-03-12');
INSERT INTO `users` (`id`, `account`, `name`, `role`, `phone`, `plotScope`, `status`, `lastLogin`, `createdAt`) VALUES ('U-004', 'cheng', '陈刚', '农户', '138****6210', 'P-03', '启用', '2026-11-06 08:02', '2026-04-08');
INSERT INTO `users` (`id`, `account`, `name`, `role`, `phone`, `plotScope`, `status`, `lastLogin`, `createdAt`) VALUES ('U-005', 'ops', '张运维', '运维', '136****5521', '系统全部', '启用', '2026-11-06 09:10', '2026-03-01');
INSERT INTO `users` (`id`, `account`, `name`, `role`, `phone`, `plotScope`, `status`, `lastLogin`, `createdAt`) VALUES ('U-006', 'liuy', '刘洋', '农户', '136****7521', 'P-05', '停用', '2026-10-28 16:22', '2026-04-15');
INSERT INTO `users` (`id`, `account`, `name`, `role`, `phone`, `plotScope`, `status`, `lastLogin`, `createdAt`) VALUES ('U-007', 'sup01', '监管员 · 黄洁', '监管人员', '135****1180', '璧山区辖区', '启用', '2026-11-06 09:01', '2026-06-20');
INSERT INTO `users` (`id`, `account`, `name`, `role`, `phone`, `plotScope`, `status`, `lastLogin`, `createdAt`) VALUES ('U-008', 'zhout', '周涛', '农户', '135****3390', 'P-04', '启用', '2026-11-06 07:55', '2026-04-02');

-- ============ roles（5 条） ============
INSERT INTO `roles` (`id`, `name`, `code`, `members`, `description`, `permissions`) VALUES ('R-01', '园区管理员', 'ADMIN', 2, '业务运营、设备控制、工单派发、报表统计', '["dashboard","iot","control","farm","trace","gis","alarm","report"]');
INSERT INTO `roles` (`id`, `name`, `code`, `members`, `description`, `permissions`) VALUES ('R-02', '运维', 'OPS', 1, '底层运维、用户权限、设备接入、日志审计', '["workbench","users","roles","device-access","dict","logs","backup","openapi","files"]');
INSERT INTO `roles` (`id`, `name`, `code`, `members`, `description`, `permissions`) VALUES ('R-03', '农户', 'FARMER', 8, '移动端任务执行、打卡上报、设备控制', '["app-tasks","app-env","app-device","app-trace"]');
INSERT INTO `roles` (`id`, `name`, `code`, `members`, `description`, `permissions`) VALUES ('R-04', '监管人员', 'SUPERVISE', 3, '辖区质量数据、溯源台账、预警与报表', '["sup-overview","sup-quality","sup-trace","sup-pesticide","sup-warning","sup-report"]');
INSERT INTO `roles` (`id`, `name`, `code`, `members`, `description`, `permissions`) VALUES ('R-05', '访客', 'GUEST', 0, '只读查看公开溯源数据', '["h5-trace"]');

-- ============ loginLogs（40 条） ============
INSERT INTO `loginLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`) VALUES ('LL-1795059923809', 'admin', '李明', '登录系统', '管理员端', '127.0.0.1', '2026-11-19 11:45:23', '成功');
INSERT INTO `loginLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`) VALUES ('LL-1795059595240', 'wangq', '王强', '登录系统', '农户端', '127.0.0.1', '2026-11-19 11:39:55', '成功');
INSERT INTO `loginLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`) VALUES ('LL-1795055195534', 'wangq', '王强', '登录系统', '农户端', '127.0.0.1', '2026-11-19 10:26:35', '成功');
INSERT INTO `loginLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`) VALUES ('LL-1795054913686', 'wangq', '王强', '登录系统', '农户端', '127.0.0.1', '2026-11-19 10:21:53', '成功');
INSERT INTO `loginLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`) VALUES ('LL-1795054354055', 'admin', '李明', '登录系统', '管理员端', '127.0.0.1', '2026-11-19 10:12:34', '成功');
INSERT INTO `loginLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`) VALUES ('LL-1795054321095', 'admin', '李明', '登录系统', '管理员端', '127.0.0.1', '2026-11-19 10:12:01', '成功');
INSERT INTO `loginLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`) VALUES ('LL-1795054318920', 'admin', '李明', '密码错误', '管理员端', '127.0.0.1', '2026-11-19 10:11:58', '失败');
INSERT INTO `loginLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`) VALUES ('LL-1795054282066', 'admin', '李明', '登录系统', '管理员端', '127.0.0.1', '2026-11-19 10:11:22', '成功');
INSERT INTO `loginLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`) VALUES ('LL-1795054280187', 'admin', '李明', '密码错误', '管理员端', '127.0.0.1', '2026-11-19 10:11:20', '失败');
INSERT INTO `loginLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`) VALUES ('LL-1795054277604', 'admin', '李明', '密码错误', '管理员端', '127.0.0.1', '2026-11-19 10:11:17', '失败');
INSERT INTO `loginLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`) VALUES ('LL-1795054234224', 'admin', '李明', '登录系统', '管理员端', '127.0.0.1', '2026-11-19 10:10:34', '成功');
INSERT INTO `loginLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`) VALUES ('LL-1795054213333', 'sup01', '黄洁', '登录系统', '监管端', '127.0.0.1', '2026-11-19 10:10:13', '成功');
INSERT INTO `loginLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`) VALUES ('LL-1795054209267', 'sup01', '黄洁', '密码错误', '监管端', '127.0.0.1', '2026-11-19 10:10:09', '失败');
INSERT INTO `loginLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`) VALUES ('LL-1795054181046', 'sup01', '黄洁', '登录系统', '监管端', '127.0.0.1', '2026-11-19 10:09:41', '成功');
INSERT INTO `loginLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`) VALUES ('LL-1795053847351', 'admin', '李明', '登录系统', '管理员端', '127.0.0.1', '2026-11-19 10:04:07', '成功');
INSERT INTO `loginLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`) VALUES ('LL-1795053847303', 'admin', '李明', '密码错误', '管理员端', '127.0.0.1', '2026-11-19 10:04:07', '失败');
INSERT INTO `loginLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`) VALUES ('LL-1795053847124', 'admin', '李明', '登录系统', '管理员端', '127.0.0.1', '2026-11-19 10:04:07', '成功');
INSERT INTO `loginLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`) VALUES ('LL-1795053445615', 'admin', '李明', '密码错误', '管理员端', '127.0.0.1', '2026-11-19 09:57:25', '失败');
INSERT INTO `loginLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`) VALUES ('LL-1795053445569', 'admin', '李明', '密码错误', '管理员端', '127.0.0.1', '2026-11-19 09:57:25', '失败');
INSERT INTO `loginLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`) VALUES ('LL-1795053445522', 'admin', '李明', '登录系统', '管理员端', '127.0.0.1', '2026-11-19 09:57:25', '成功');
INSERT INTO `loginLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`) VALUES ('LL-1795053124766', 'sup01', '黄洁', '登录系统', '监管端', '127.0.0.1', '2026-11-19 09:52:04', '成功');
INSERT INTO `loginLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`) VALUES ('LL-1795053120996', 'sup01', '黄洁', '密码错误', '监管端', '127.0.0.1', '2026-11-19 09:52:00', '失败');
INSERT INTO `loginLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`) VALUES ('LL-1795053112803', 'sup01', '黄洁', '密码错误', '监管端', '127.0.0.1', '2026-11-19 09:51:52', '失败');
INSERT INTO `loginLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`) VALUES ('LL-1795052637343', 'sup01', '黄洁', '登录系统', '监管端', '127.0.0.1', '2026-11-19 09:43:57', '成功');
INSERT INTO `loginLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`) VALUES ('LL-1795052610790', 'sup01', '黄洁', '登录系统', '监管端', '127.0.0.1', '2026-11-19 09:43:30', '成功');
INSERT INTO `loginLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`) VALUES ('LL-1795052518524', 'sup01', '黄洁', '登录系统', '监管端', '127.0.0.1', '2026-11-19 09:41:58', '成功');
INSERT INTO `loginLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`) VALUES ('LL-1795052265665', 'admin', '李明', '登录系统', '管理员端', '127.0.0.1', '2026-11-19 09:37:45', '成功');
INSERT INTO `loginLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`) VALUES ('LL-1795052062387', 'ops', '张运维', '登录系统', '运维端', '127.0.0.1', '2026-11-19 09:34:22', '成功');
INSERT INTO `loginLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`) VALUES ('LL-1795052030144', 'admin', '李明', '登录系统', '管理员端', '127.0.0.1', '2026-11-19 09:33:50', '成功');
INSERT INTO `loginLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`) VALUES ('LL-1795051371829', 'admin', '李明', '登录系统', '管理员端', '127.0.0.1', '2026-11-19 09:22:51', '成功');
INSERT INTO `loginLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`) VALUES ('LL-1795051272939', 'admin', '李明', '密码错误', '管理员端', '127.0.0.1', '2026-11-19 09:21:12', '失败');
INSERT INTO `loginLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`) VALUES ('LL-1795051272882', 'admin', '李明', '登录系统', '管理员端', '127.0.0.1', '2026-11-19 09:21:12', '成功');
INSERT INTO `loginLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`) VALUES ('LL-01', 'admin', '李明', '登录系统', '管理员端', '192.168.10.22', '2026-11-06 09:32:18', '成功');
INSERT INTO `loginLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`) VALUES ('LL-02', 'ops', '张运维', '登录系统', '运维端', '192.168.10.31', '2026-11-06 09:10:44', '成功');
INSERT INTO `loginLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`) VALUES ('LL-03', 'sup01', '黄洁', '登录系统', '监管端', '10.20.5.118', '2026-11-06 09:01:05', '成功');
INSERT INTO `loginLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`) VALUES ('LL-04', 'wangq', '王强', '移动端登录', '农户端', '10.20.8.42', '2026-11-06 08:12:51', '成功');
INSERT INTO `loginLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`) VALUES ('LL-05', 'admin', '李明', '密码错误', '管理员端', '192.168.10.22', '2026-11-06 08:02:13', '失败');
INSERT INTO `loginLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`) VALUES ('LL-06', 'liuy', '刘洋', '登录系统', '农户端', '10.20.8.55', '2026-11-05 16:22:30', '成功');
INSERT INTO `loginLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`) VALUES ('LL-07', 'ops', '张运维', '退出系统', '运维端', '192.168.10.31', '2026-11-05 18:05:12', '成功');
INSERT INTO `loginLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`) VALUES ('LL-08', 'unknown', '未知用户', '非法令牌访问', '接口', '203.0.113.8', '2026-11-05 03:14:29', '失败');

-- ============ operationLogs（10 条） ============
INSERT INTO `operationLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`, `detail`) VALUES ('OL-01', 'admin', '李明', '下发 1号棚水泵启动指令', '设备控制', '192.168.10.22', '2026-11-06 09:40:12', '成功', '设备 DEV-101，指令 START，耗时 0.42s');
INSERT INTO `operationLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`, `detail`) VALUES ('OL-02', 'admin', '李明', '创建农事工单 WO-20261106-01', '农事工单', '192.168.10.22', '2026-11-06 08:20:35', '成功', '派发给农户陈刚');
INSERT INTO `operationLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`, `detail`) VALUES ('OL-03', 'ops', '张运维', '新增设备接入 DEV-301', '设备接入', '192.168.10.31', '2026-11-06 08:05:19', '成功', '协议 MQTT，采集频率 30s');
INSERT INTO `operationLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`, `detail`) VALUES ('OL-04', 'admin', '李明', '确认告警 ALM-20261106-02', '告警处置', '192.168.10.22', '2026-11-06 09:15:07', '成功', '转为处置中，处置人李明');
INSERT INTO `operationLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`, `detail`) VALUES ('OL-05', 'ops', '张运维', '修改数据字典 crop_type', '系统参数', '192.168.10.31', '2026-11-05 17:42:11', '成功', '新增作物分类：叶菜类');
INSERT INTO `operationLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`, `detail`) VALUES ('OL-06', 'admin', '李明', '导出环境月报 2026-10', '报表中心', '192.168.10.22', '2026-11-05 16:30:45', '成功', 'Excel，共 31 天数据');
INSERT INTO `operationLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`, `detail`) VALUES ('OL-07', 'sup01', '黄洁', '查询辖区溯源台账', '监管端', '10.20.5.118', '2026-11-05 15:12:28', '成功', '查询 24 条');
INSERT INTO `operationLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`, `detail`) VALUES ('OL-08', 'ops', '张运维', '执行数据库备份', '数据备份', '192.168.10.31', '2026-11-05 02:00:00', '成功', '备份文件 agri_20261105_020000.sql.gz，大小 428MB');
INSERT INTO `operationLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`, `detail`) VALUES ('OL-09', 'admin', '李明', '召回批次 B20261030-06', '产品召回', '192.168.10.22', '2026-11-01 09:30:22', '成功', '召回级别二级');
INSERT INTO `operationLogs` (`id`, `account`, `name`, `action`, `module`, `ip`, `time`, `result`, `detail`) VALUES ('OL-10', 'ops', '张运维', '重置用户 liuy 密码', '用户管理', '192.168.10.31', '2026-10-31 14:18:09', '成功', '临时密码有效 24 小时');

-- ============ backups（5 条） ============
INSERT INTO `backups` (`id`, `name`, `size`, `type`, `createdAt`, `status`) VALUES ('BK-01', 'agri_20261105_020000.sql.gz', '428 MB', '自动', '2026-11-05 02:00:00', '成功');
INSERT INTO `backups` (`id`, `name`, `size`, `type`, `createdAt`, `status`) VALUES ('BK-02', 'agri_20261104_020000.sql.gz', '426 MB', '自动', '2026-11-04 02:00:00', '成功');
INSERT INTO `backups` (`id`, `name`, `size`, `type`, `createdAt`, `status`) VALUES ('BK-03', 'agri_20261103_020000.sql.gz', '425 MB', '自动', '2026-11-03 02:00:00', '成功');
INSERT INTO `backups` (`id`, `name`, `size`, `type`, `createdAt`, `status`) VALUES ('BK-04', 'agri_manual_20261102_143012.sql.gz', '424 MB', '手动', '2026-11-02 14:30:12', '成功');
INSERT INTO `backups` (`id`, `name`, `size`, `type`, `createdAt`, `status`) VALUES ('BK-05', 'agri_20261101_020000.sql.gz', '423 MB', '自动', '2026-11-01 02:00:00', '成功');

-- ============ openApis（5 条） ============
INSERT INTO `openApis` (`id`, `name`, `path`, `method`, `target`, `enabled`, `calls`, `updatedAt`, `key`) VALUES ('API-01', '气象数据同步', '/api/v1/open/weather/sync', 'GET', '和风天气 API', 1, 8642, '2026-11-05 10:12', 'ak_weather_9f2c****3a71');
INSERT INTO `openApis` (`id`, `name`, `path`, `method`, `target`, `enabled`, `calls`, `updatedAt`, `key`) VALUES ('API-02', '监管平台溯台上报', '/api/v1/open/trace/report', 'POST', '璧山区农业监管平台', 1, 1260, '2026-11-04 16:30', 'ak_sup_7d1e****b842');
INSERT INTO `openApis` (`id`, `name`, `path`, `method`, `target`, `enabled`, `calls`, `updatedAt`, `key`) VALUES ('API-03', '短信告警推送', '/api/v1/open/sms/send', 'POST', '阿里云短信服务', 1, 342, '2026-11-03 09:05', 'ak_sms_3c88****e15d');
INSERT INTO `openApis` (`id`, `name`, `path`, `method`, `target`, `enabled`, `calls`, `updatedAt`, `key`) VALUES ('API-04', '视频流鉴权', '/api/v1/open/video/token', 'GET', '海康威视 openapi', 0, 78, '2026-10-28 14:22', 'ak_video_b41f****00c9');
INSERT INTO `openApis` (`id`, `name`, `path`, `method`, `target`, `enabled`, `calls`, `updatedAt`, `key`) VALUES ('API-05', 'MQTT 网关状态回调', '/api/v1/open/iot/callback', 'POST', '园区物联网网关', 1, 25680, '2026-11-06 09:42', 'ak_iot_6a9d****7f30');

-- ============ files（8 条） ============
INSERT INTO `files` (`id`, `name`, `type`, `size`, `uploader`, `uploadedAt`, `url`) VALUES ('F-01', '番茄检测报告_20261105.pdf', '文档', '1.2 MB', '李明', '2026-11-05 11:20', '/files/inspect/tomato-1105.pdf');
INSERT INTO `files` (`id`, `name`, `type`, `size`, `uploader`, `uploadedAt`, `url`) VALUES ('F-02', '3号棚黄瓜采收现场-1.jpg', '图片', '3.8 MB', '陈刚', '2026-11-05 16:32', '/files/harvest/cucumber-01.jpg');
INSERT INTO `files` (`id`, `name`, `type`, `size`, `uploader`, `uploadedAt`, `url`) VALUES ('F-03', '3号棚黄瓜采收现场-2.jpg', '图片', '3.6 MB', '陈刚', '2026-11-05 16:33', '/files/harvest/cucumber-02.jpg');
INSERT INTO `files` (`id`, `name`, `type`, `size`, `uploader`, `uploadedAt`, `url`) VALUES ('F-04', 'A区病枝清理作业.mp4', '视频', '48.2 MB', '周涛', '2026-11-05 17:05', '/files/work/a-orchard.mp4');
INSERT INTO `files` (`id`, `name`, `type`, `size`, `uploader`, `uploadedAt`, `url`) VALUES ('F-05', '园区设备台账_2026Q4.xlsx', '文档', '860 KB', '张运维', '2026-11-04 09:40', '/files/device/ledger-q4.xlsx');
INSERT INTO `files` (`id`, `name`, `type`, `size`, `uploader`, `uploadedAt`, `url`) VALUES ('F-06', '草莓包装标签模板.png', '图片', '2.1 MB', '李明', '2026-11-03 15:12', '/files/trace/strawberry-label.png');
INSERT INTO `files` (`id`, `name`, `type`, `size`, `uploader`, `uploadedAt`, `url`) VALUES ('F-07', '2026年10月环境月报.pdf', '文档', '4.6 MB', '李明', '2026-11-02 10:08', '/files/report/env-202610.pdf');
INSERT INTO `files` (`id`, `name`, `type`, `size`, `uploader`, `uploadedAt`, `url`) VALUES ('F-08', '物联网网关配置说明.pdf', '文档', '2.8 MB', '张运维', '2026-11-01 14:00', '/files/iot/gateway-config.pdf');

-- ============ supWarnings（6 条） ============
INSERT INTO `supWarnings` (`id`, `title`, `type`, `entity`, `level`, `createdAt`, `status`) VALUES ('SW-01', '黄瓜批次 B20261030-06 农残检测不合格', '质量异常', '云岭智慧农业示范园 · P-03', '高', '2026-11-01 09:35', '处理中');
INSERT INTO `supWarnings` (`id`, `title`, `type`, `entity`, `level`, `createdAt`, `status`) VALUES ('SW-02', '农药使用记录缺少施药人员签字', '台账缺失', '云岭智慧农业示范园 · P-01', '中', '2026-10-31 15:20', '待处理');
INSERT INTO `supWarnings` (`id`, `title`, `type`, `entity`, `level`, `createdAt`, `status`) VALUES ('SW-03', '3号棚水泵故障未在 2 小时内处置', '设备告警', '云岭智慧农业示范园 · P-03', '中', '2026-11-06 08:58', '待处理');
INSERT INTO `supWarnings` (`id`, `title`, `type`, `entity`, `level`, `createdAt`, `status`) VALUES ('SW-04', '草莓采收未按规定进行分级登记', '农事违规', '云岭智慧农业示范园 · P-02', '低', '2026-11-04 10:12', '已办结');
INSERT INTO `supWarnings` (`id`, `title`, `type`, `entity`, `level`, `createdAt`, `status`) VALUES ('SW-05', '追溯码扫码访问量异常骤增', '质量异常', '云岭智慧农业示范园 · P-04', '低', '2026-11-03 22:40', '已办结');
INSERT INTO `supWarnings` (`id`, `title`, `type`, `entity`, `level`, `createdAt`, `status`) VALUES ('SW-06', '水稻批次检测报告尚未归档', '台账缺失', '云岭智慧农业示范园 · P-05', '中', '2026-11-03 14:05', '处理中');

-- ============ messages（6 条） ============
INSERT INTO `messages` (`id`, `title`, `body`, `time`, `level`, `read`, `from`) VALUES ('MSG-01', '3号黄瓜棚水泵故障停机', '设备 DEV-107 运行电流为 0，请尽快到现场排查水泵及供电线路。', '2026-11-06 08:56', '紧急', 0, '告警中心');
INSERT INTO `messages` (`id`, `title`, `body`, `time`, `level`, `read`, `from`) VALUES ('MSG-02', '3号棚空气温度超过上限', '当前温度 36.4℃，已超过设定上限 32℃，建议开启环流风机并拉开遮阳帘。', '2026-11-06 09:12', '重要', 0, '环境监测');
INSERT INTO `messages` (`id`, `title`, `body`, `time`, `level`, `read`, `from`) VALUES ('MSG-03', '新工单：3号棚黄瓜采收与分级', '管理员李明派发采收工单，截止时间今日 18:00，请及时接单。', '2026-11-06 08:20', '重要', 0, '农事工单');
INSERT INTO `messages` (`id`, `title`, `body`, `time`, `level`, `read`, `from`) VALUES ('MSG-04', 'B区水质传感器电量不足', '设备 DEV-204 剩余电量 12%，请更换电池，避免数据中断。', '2026-11-06 07:15', '一般', 1, '设备状态');
INSERT INTO `messages` (`id`, `title`, `body`, `time`, `level`, `read`, `from`) VALUES ('MSG-05', '2号棚滴灌巡检任务已派发', '请在今日 15:00 前完成滴灌系统巡检并提交记录。', '2026-11-06 07:30', '一般', 1, '农事工单');
INSERT INTO `messages` (`id`, `title`, `body`, `time`, `level`, `read`, `from`) VALUES ('MSG-06', '本月环境月报已生成', '2026 年 10 月环境监测月报已生成，可在报表中心查看与导出。', '2026-11-01 09:00', '一般', 1, '报表中心');

-- ============ envSeries（单例） ============
INSERT INTO `envSeries` (`labels`, `temperature`, `humidity`, `soilTemperature`, `soilMoisture`, `co2`, `light`, `ph`, `waterTemperature`) VALUES ('["00:00","01:00","02:00","03:00","04:00","05:00","06:00","07:00","08:00","09:00","10:00","11:00","12:00","13:00","14:00","15:00","16:00","17:00","18:00","19:00","20:00","21:00","22:00","23:00"]', '[19.2,18.6,18.2,17.9,17.8,18.1,18.8,20.4,23.1,26.2,28.4,30.1,31.6,32.4,32.1,30.8,29.2,27.4,25.6,23.8,22.1,20.9,20.1,19.6]', '[82,84,86,87,88,86,83,79,74,68,63,58,55,52,51,53,57,62,68,73,77,80,81,82]', '[22.4,22.1,21.8,21.6,21.5,21.6,21.9,22.6,23.8,25.1,26.4,27.2,27.8,28.1,27.9,27.2,26.3,25.2,24.3,23.7,23.2,22.9,22.7,22.5]', '[52,51,50,49,49,48,48,47,46,45,44,43,42,42,41,41,42,43,45,47,49,50,51,52]', '[438,442,448,452,455,458,462,468,476,486,498,510,522,530,526,516,502,488,474,462,452,446,442,439]', '[0,0,0,0,0,0,32,420,1250,2480,3860,5020,5860,6080,5720,4860,3720,2380,1160,360,60,0,0,0]', '[6.4,6.4,6.5,6.5,6.5,6.5,6.4,6.4,6.3,6.3,6.2,6.2,6.2,6.3,6.3,6.4,6.4,6.4,6.5,6.5,6.5,6.4,6.4,6.4]', '[18.2,18,17.8,17.6,17.6,17.7,18,18.6,19.8,21.2,22.4,23.1,23.8,24,23.9,23.4,22.8,22,21.2,20.4,19.6,19,18.7,18.4]');

-- ============ waterElectric（单例） ============
INSERT INTO `waterElectric` (`months`, `water`, `electric`) VALUES ('["6月","7月","8月","9月","10月","11月"]', '[3280,4120,4680,3860,2940,1260]', '[8620,10840,12260,9860,7540,3120]');

-- ============ monthlyReport（6 条） ============
INSERT INTO `monthlyReport` (`month`, `water`, `electric`, `cost`, `alarms`, `orders`, `id`) VALUES ('2026-06', 3280, 8620, 6420, 32, 18, 'JJZL6i9vfMY');
INSERT INTO `monthlyReport` (`month`, `water`, `electric`, `cost`, `alarms`, `orders`, `id`) VALUES ('2026-07', 4120, 10840, 8240, 41, 24, 'XIdo3FTthiY');
INSERT INTO `monthlyReport` (`month`, `water`, `electric`, `cost`, `alarms`, `orders`, `id`) VALUES ('2026-08', 4680, 12260, 9360, 38, 26, '0xVeb_siAno');
INSERT INTO `monthlyReport` (`month`, `water`, `electric`, `cost`, `alarms`, `orders`, `id`) VALUES ('2026-09', 3860, 9860, 7560, 27, 21, 'U-L2QKow5Y0');
INSERT INTO `monthlyReport` (`month`, `water`, `electric`, `cost`, `alarms`, `orders`, `id`) VALUES ('2026-10', 2940, 7540, 5840, 19, 17, 'oqKC5UfEcrk');
INSERT INTO `monthlyReport` (`month`, `water`, `electric`, `cost`, `alarms`, `orders`, `id`) VALUES ('2026-11', 1260, 3120, 2460, 8, 9, '282Iu56WJ5g');

-- ============ traceTimeline（7 条） ============
INSERT INTO `traceTimeline` (`date`, `title`, `desc`, `id`) VALUES ('2026-07-26', '定植移栽', '3 号黄瓜棚完成津优 35 定植，株距 30 cm，共定植 2,400 株。', 'rZrO7tQQfTA');
INSERT INTO `traceTimeline` (`date`, `title`, `desc`, `id`) VALUES ('2026-08-10', '水肥一体化', '施用复合肥 15-15-15 共 18 kg，滴灌时长 45 分钟，EC 2.1 mS/cm。', 'ucqqoyfzOoA');
INSERT INTO `traceTimeline` (`date`, `title`, `desc`, `id`) VALUES ('2026-08-24', '植株调整', '吊蔓、落蔓作业，清除下部老叶，保持通风透光。', '0NfDERI4c2c');
INSERT INTO `traceTimeline` (`date`, `title`, `desc`, `id`) VALUES ('2026-09-15', '生物防治', '释放捕食螨防治红蜘蛛，悬挂黄板 40 张，未使用化学农药。', 'muR9HDiKLaY');
INSERT INTO `traceTimeline` (`date`, `title`, `desc`, `id`) VALUES ('2026-10-20', '环境监测', '连续 7 天棚内温度 24-31℃，湿度 60%-75%，土壤湿度稳定在 45%。', 'ymNy50hq7lw');
INSERT INTO `traceTimeline` (`date`, `title`, `desc`, `id`) VALUES ('2026-11-05', '采收分级', '采收黄瓜 1,260 kg，按一级果标准分筐，同步赋码 1,260 枚。', 'JGgs2PfuCj4');
INSERT INTO `traceTimeline` (`date`, `title`, `desc`, `id`) VALUES ('2026-11-05', '质量检测', '重庆市农产品质量检测中心出具报告，农残未检出，综合判定合格。', '467jtuMNCTE');

-- ============ traceDetail（单例） ============
INSERT INTO `traceDetail` (`batchNo`, `crop`, `variety`, `origin`, `grade`, `weight`, `harvestedAt`, `farmer`, `plot`, `scans`, `inspect`) VALUES ('B20261105-03', '黄瓜', '津优 35', '重庆市璧山区现代农业园区 · 3号黄瓜棚', '一级', '1,260 kg', '2026-11-05', '陈刚', 'P-03', 386, '{"reportNo":"CQ-JC-20261105-031","agency":"重庆市农产品质量检测中心","testedAt":"2026-11-05","pesticide":"未检出","heavyMetal":"合格","conclusion":"合格"}');

-- ============ qualityOverview（单例） ============
INSERT INTO `qualityOverview` (`passRate`, `inspectedBatches`, `qualified`, `unqualified`, `recalls`, `pesticideChecks`, `trend`, `categories`) VALUES (98.6, 72, 71, 1, 3, 126, '[96.8,97.2,97.9,98.1,98.4,98.6]', '[{"name":"蔬菜","batches":38,"passRate":97.4},{"name":"水果","batches":22,"passRate":100},{"name":"粮油","batches":8,"passRate":100},{"name":"经济作物","batches":4,"passRate":100}]');

-- ============ pesticideLedger（6 条） ============
INSERT INTO `pesticideLedger` (`id`, `date`, `plot`, `crop`, `name`, `amount`, `operator`, `method`, `safetyDays`, `compliant`, `note`) VALUES ('PL-01', '2026-11-02', 'P-04', '柑橘', '生物杀虫剂苏云金杆菌', '2.4 L', '周涛', '叶面喷施', 7, 1, NULL);
INSERT INTO `pesticideLedger` (`id`, `date`, `plot`, `crop`, `name`, `amount`, `operator`, `method`, `safetyDays`, `compliant`, `note`) VALUES ('PL-02', '2026-10-28', 'P-01', '番茄', '枯草芽孢杆菌', '1.8 kg', '王强', '灌根', 3, 1, NULL);
INSERT INTO `pesticideLedger` (`id`, `date`, `plot`, `crop`, `name`, `amount`, `operator`, `method`, `safetyDays`, `compliant`, `note`) VALUES ('PL-03', '2026-10-22', 'P-03', '黄瓜', '吡虫啉', '0.6 kg', '陈刚', '叶面喷施', 14, 0, '施药后 9 天即采收，未满足安全间隔期');
INSERT INTO `pesticideLedger` (`id`, `date`, `plot`, `crop`, `name`, `amount`, `operator`, `method`, `safetyDays`, `compliant`, `note`) VALUES ('PL-04', '2026-10-18', 'P-02', '草莓', '多菌灵', '0.9 kg', '赵敏', '叶面喷施', 10, 1, NULL);
INSERT INTO `pesticideLedger` (`id`, `date`, `plot`, `crop`, `name`, `amount`, `operator`, `method`, `safetyDays`, `compliant`, `note`) VALUES ('PL-05', '2026-10-12', 'P-05', '水稻', '稻瘟灵', '3.2 L', '刘洋', '无人机喷施', 21, 1, NULL);
INSERT INTO `pesticideLedger` (`id`, `date`, `plot`, `crop`, `name`, `amount`, `operator`, `method`, `safetyDays`, `compliant`, `note`) VALUES ('PL-06', '2026-10-05', 'P-04', '柑橘', '矿物油', '5.0 L', '周涛', '全园喷雾', 5, 1, NULL);

-- ============ sysInfo（单例） ============
INSERT INTO `sysInfo` (`version`, `env`, `db`, `api`, `uptime`, `cpu`, `memory`, `disk`, `onlineUsers`, `mqttMessages`, `apiCalls`) VALUES ('v2.4.0', '生产环境', 'MySQL 8.0.36', 'Spring Boot 3.2', '128 天 06 小时', 38, 62, 47, 86, 1286420, 286412);

-- ============ tenants（3 条） ============
INSERT INTO `tenants` (`id`, `name`, `code`, `contact`, `phone`, `resourceQuota`, `userCount`, `deviceCount`, `status`, `createdAt`) VALUES ('T-01', '云岭智慧农业示范园', 'YUNLING', '李明', '138****0001', '地块 12 · 用户 50 · 设备 200 · 存储 500GB', 34, 128, '启用', '2026-03-01');
INSERT INTO `tenants` (`id`, `name`, `code`, `contact`, `phone`, `resourceQuota`, `userCount`, `deviceCount`, `status`, `createdAt`) VALUES ('T-02', '璧山生态果蔬基地', 'BISHAN', '王建国', '139****2210', '地块 6 · 用户 20 · 设备 80 · 存储 200GB', 12, 46, '启用', '2026-05-18');
INSERT INTO `tenants` (`id`, `name`, `code`, `contact`, `phone`, `resourceQuota`, `userCount`, `deviceCount`, `status`, `createdAt`) VALUES ('T-03', '潼南柠檬产业园', 'TONGNAN', '陈静', '136****7789', '地块 8 · 用户 30 · 设备 100 · 存储 300GB', 0, 0, '停用', '2026-07-22');

-- ============ plotAudits（4 条） ============
INSERT INTO `plotAudits` (`id`, `plotCode`, `plotName`, `crop`, `variety`, `area`, `greenhouse`, `submitBy`, `farmerId`, `submittedAt`, `status`, `boundaryClosed`, `polygon`, `rejectReason`) VALUES ('PA-01', 'P-07', '7号番茄新棚', '番茄', '云粉 10 号', 6.5, '连栋薄膜温室', '王强', 'U-002', '2026-11-06 10:15', '待审核', 1, '[{"x":120,"y":120},{"x":320,"y":116},{"x":336,"y":250},{"x":128,"y":258}]', NULL);
INSERT INTO `plotAudits` (`id`, `plotCode`, `plotName`, `crop`, `variety`, `area`, `greenhouse`, `submitBy`, `farmerId`, `submittedAt`, `status`, `boundaryClosed`, `polygon`, `rejectReason`) VALUES ('PA-02', 'P-08', '8号露天菜地', '白菜', '早熟 5 号', 4.2, '露天种植', '王强', 'U-002', '2026-11-06 09:40', '待审核', 0, '[{"x":420,"y":140},{"x":560,"y":138},{"x":570,"y":230},{"x":430,"y":236}]', NULL);
INSERT INTO `plotAudits` (`id`, `plotCode`, `plotName`, `crop`, `variety`, `area`, `greenhouse`, `submitBy`, `farmerId`, `submittedAt`, `status`, `boundaryClosed`, `polygon`, `rejectReason`) VALUES ('PA-03', 'P-09', '9号草莓新棚', '草莓', '章姬', 5.8, '日光温室', '赵敏', 'U-003', '2026-11-05 16:20', '已通过', 1, '[{"x":620,"y":130},{"x":820,"y":126},{"x":834,"y":252},{"x":628,"y":260}]', NULL);
INSERT INTO `plotAudits` (`id`, `plotCode`, `plotName`, `crop`, `variety`, `area`, `greenhouse`, `submitBy`, `farmerId`, `submittedAt`, `status`, `boundaryClosed`, `polygon`, `rejectReason`) VALUES ('PA-04', 'P-10', '10号辣椒苗棚', '辣椒', '螺丝椒', 3.1, '育苗温室', '赵敏', 'U-003', '2026-11-05 14:05', '已驳回', 1, '[{"x":740,"y":310},{"x":900,"y":308},{"x":912,"y":430},{"x":750,"y":438}]', '地块边界与相邻 6 号育苗棚重叠，请重新绘制边界后提交。');

-- ============ screenConfig（单例） ============
INSERT INTO `screenConfig` (`sections`, `interval`, `theme`, `resolution`, `defaultScope`) VALUES ('[{"id":"overview","name":"园区综合态势","icon":"态","enabled":true},{"id":"env","name":"环境监测趋势","icon":"环","enabled":true},{"id":"device","name":"设备状态统计","icon":"设","enabled":true},{"id":"alarm","name":"告警动态统计","icon":"警","enabled":true},{"id":"map","name":"地块地图分布","icon":"图","enabled":true},{"id":"crop","name":"作物种植分布","icon":"作","enabled":true},{"id":"work","name":"农事工单进度","icon":"工","enabled":true},{"id":"scan","name":"溯源扫码统计","icon":"溯","enabled":true},{"id":"water","name":"水电能耗统计","icon":"水","enabled":false}]', 15, '深色主题', '1920 × 1080', '全部地块');

-- ============ farmerPlots（3 条） ============
INSERT INTO `farmerPlots` (`id`, `name`, `crop`, `variety`, `area`, `greenhouse`, `plantedAt`, `expectedHarvest`, `auditStatus`, `deviceCount`, `envTemp`, `envHumidity`, `polygon`, `rejectReason`) VALUES ('P-01', '1号智能大棚', '番茄', '云粉 9 号', 12.8, '连栋薄膜温室', '2026-08-12', '2026-11-20', '已通过', 5, 26.4, 68, '[{"x":78,"y":92},{"x":298,"y":82},{"x":320,"y":236},{"x":92,"y":252}]', NULL);
INSERT INTO `farmerPlots` (`id`, `name`, `crop`, `variety`, `area`, `greenhouse`, `plantedAt`, `expectedHarvest`, `auditStatus`, `deviceCount`, `envTemp`, `envHumidity`, `polygon`, `rejectReason`) VALUES ('P-07', '7号番茄新棚', '番茄', '云粉 10 号', 6.5, '连栋薄膜温室', '2026-11-01', '2027-03-15', '待审核', 0, 24.8, 61, '[{"x":120,"y":120},{"x":320,"y":116},{"x":336,"y":250},{"x":128,"y":258}]', NULL);
INSERT INTO `farmerPlots` (`id`, `name`, `crop`, `variety`, `area`, `greenhouse`, `plantedAt`, `expectedHarvest`, `auditStatus`, `deviceCount`, `envTemp`, `envHumidity`, `polygon`, `rejectReason`) VALUES ('P-08', '8号露天菜地', '白菜', '早熟 5 号', 4.2, '露天种植', '2026-10-25', '2026-12-30', '已驳回', 0, 22.1, 57, '[{"x":420,"y":140},{"x":560,"y":138},{"x":570,"y":230},{"x":430,"y":236}]', '地块边界未闭合，请重新绘制完整闭合边界后再次提交。');

-- ============ dictTypes（6 条） ============
INSERT INTO `dictTypes` (`id`, `code`, `name`, `desc`, `items`) VALUES ('DT-01', 'crop_type', '作物分类', '用于农事档案与报表的作物大类划分', '[{"id":"CT-01","code":"VEG","name":"蔬菜类","sort":1,"status":"启用","note":"茄果、瓜类、叶菜等"},{"id":"CT-02","code":"FRUIT","name":"水果类","sort":2,"status":"启用","note":"草莓、柑橘等"},{"id":"CT-03","code":"GRAIN","name":"粮油类","sort":3,"status":"启用","note":"水稻、玉米、油菜"},{"id":"CT-04","code":"LEAF","name":"叶菜类","sort":4,"status":"启用","note":"生菜、菠菜、小白菜"},{"id":"CT-05","code":"OTHER","name":"其他作物","sort":5,"status":"停用","note":"暂未启用"}]');
INSERT INTO `dictTypes` (`id`, `code`, `name`, `desc`, `items`) VALUES ('DT-02', 'device_type', '设备类型', '设备接入与远程控制的功能分类', '[{"id":"DT2-01","code":"PUMP","name":"水泵","sort":1,"status":"启用","note":"灌溉与排水"},{"id":"DT2-02","code":"FAN","name":"风机","sort":2,"status":"启用","note":"环流与加温"},{"id":"DT2-03","code":"CURTAIN","name":"卷帘","sort":3,"status":"启用","note":"内外遮阳"},{"id":"DT2-04","code":"LIGHT","name":"补光灯","sort":4,"status":"启用","note":"育苗补光"},{"id":"DT2-05","code":"VALVE","name":"电磁阀","sort":5,"status":"启用","note":"滴灌分区控制"},{"id":"DT2-06","code":"SENSOR","name":"传感器","sort":6,"status":"启用","note":"环境与水质采集"},{"id":"DT2-07","code":"GATEWAY","name":"网关","sort":7,"status":"启用","note":"边缘接入节点"}]');
INSERT INTO `dictTypes` (`id`, `code`, `name`, `desc`, `items`) VALUES ('DT-03', 'alarm_level', '告警级别', '告警分级决定通知渠道与响应时限', '[{"id":"DT3-01","code":"URGENT","name":"紧急","sort":1,"status":"启用","note":"短信 + 电话，10 分钟内响应"},{"id":"DT3-02","code":"IMPORTANT","name":"重要","sort":2,"status":"启用","note":"站内 + 短信，30 分钟内响应"},{"id":"DT3-03","code":"NORMAL","name":"一般","sort":3,"status":"启用","note":"站内通知，2 小时内响应"},{"id":"DT3-04","code":"INFO","name":"提示","sort":4,"status":"停用","note":"仅记录，不推送"}]');
INSERT INTO `dictTypes` (`id`, `code`, `name`, `desc`, `items`) VALUES ('DT-04', 'product_grade', '产品等级', '采收分级与溯源码赋码依据', '[{"id":"DT4-01","code":"SPECIAL","name":"特级","sort":1,"status":"启用","note":"外观与规格均优"},{"id":"DT4-02","code":"FIRST","name":"一级","sort":2,"status":"启用","note":"符合主销标准"},{"id":"DT4-03","code":"SECOND","name":"二级","sort":3,"status":"启用","note":"加工或团购渠道"},{"id":"DT4-04","code":"REJECT","name":"等外","sort":4,"status":"启用","note":"不进入溯源销售"}]');
INSERT INTO `dictTypes` (`id`, `code`, `name`, `desc`, `items`) VALUES ('DT-05', 'measure_unit', '计量单位', '农资、采收与报表统一单位', '[{"id":"DT5-01","code":"KG","name":"千克","sort":1,"status":"启用","note":"kg"},{"id":"DT5-02","code":"TON","name":"吨","sort":2,"status":"启用","note":"t"},{"id":"DT5-03","code":"L","name":"升","sort":3,"status":"启用","note":"L"},{"id":"DT5-04","code":"M2","name":"平方米","sort":4,"status":"启用","note":"m²"},{"id":"DT5-05","code":"M3","name":"立方米","sort":5,"status":"启用","note":"m³"}]');
INSERT INTO `dictTypes` (`id`, `code`, `name`, `desc`, `items`) VALUES ('DT-06', 'work_status', '工单状态', '农事工单流转状态定义', '[{"id":"DT6-01","code":"PENDING","name":"待接单","sort":1,"status":"启用","note":"农户尚未接单"},{"id":"DT6-02","code":"DOING","name":"进行中","sort":2,"status":"启用","note":"作业执行中"},{"id":"DT6-03","code":"CHECKING","name":"待验收","sort":3,"status":"启用","note":"等待管理员验收"},{"id":"DT6-04","code":"DONE","name":"已完成","sort":4,"status":"启用","note":"验收通过归档"}]');

-- ============ loginDevices（3 条） ============
INSERT INTO `loginDevices` (`id`, `name`, `client`, `ip`, `time`, `current`) VALUES ('D-01', 'Windows 工作站', 'Chrome 122 · Windows 11', '192.168.10.22', '2026-11-06 09:32', 1);
INSERT INTO `loginDevices` (`id`, `name`, `client`, `ip`, `time`, `current`) VALUES ('D-02', 'iPhone 15', '飞书内置浏览器 · iOS 18', '10.20.8.42', '2026-11-05 18:12', 0);
INSERT INTO `loginDevices` (`id`, `name`, `client`, `ip`, `time`, `current`) VALUES ('D-03', 'iPad Air', 'Safari · iPadOS 18', '10.20.8.55', '2026-11-03 08:26', 0);

-- ============ controlLogs（4 条） ============
INSERT INTO `controlLogs` (`id`, `time`, `device`, `action`, `result`) VALUES ('LOG-001', '2026-11-06 09:40:12', '1号棚水泵', '启动', '成功');
INSERT INTO `controlLogs` (`id`, `time`, `device`, `action`, `result`) VALUES ('LOG-002', '2026-11-06 08:15:40', '1号棚外遮阳卷帘', '收起', '成功');
INSERT INTO `controlLogs` (`id`, `time`, `device`, `action`, `result`) VALUES ('LOG-003', '2026-11-05 22:30:08', '育苗棚补光灯', '停止', '成功');
INSERT INTO `controlLogs` (`id`, `time`, `device`, `action`, `result`) VALUES ('LOG-004', '2026-11-05 18:12:25', '3号棚水泵', '启动', '失败');

-- ============ linkageStrategies（5 条） ============
INSERT INTO `linkageStrategies` (`id`, `name`, `plotId`, `tempMin`, `tempMax`, `humidityMin`, `humidityMax`, `soilMin`, `action`, `window`, `enabled`, `lastTriggered`) VALUES ('LS-01', '高温自动通风', 'P-01', 18, 30, 55, 85, 45, '启动环流风机', '08:00-18:00', 1, '2026-11-06 13:20');
INSERT INTO `linkageStrategies` (`id`, `name`, `plotId`, `tempMin`, `tempMax`, `humidityMin`, `humidityMax`, `soilMin`, `action`, `window`, `enabled`, `lastTriggered`) VALUES ('LS-02', '夜间低温保温', 'P-02', 16, 28, 60, 85, 50, '关闭外遮阳卷帘', '18:00-08:00', 1, '2026-11-05 23:10');
INSERT INTO `linkageStrategies` (`id`, `name`, `plotId`, `tempMin`, `tempMax`, `humidityMin`, `humidityMax`, `soilMin`, `action`, `window`, `enabled`, `lastTriggered`) VALUES ('LS-03', '土壤干旱自动补灌', 'P-03', 20, 32, 50, 80, 40, '启动滴灌电磁阀', '06:00-10:00', 0, '2026-11-04 07:05');
INSERT INTO `linkageStrategies` (`id`, `name`, `plotId`, `tempMin`, `tempMax`, `humidityMin`, `humidityMax`, `soilMin`, `action`, `window`, `enabled`, `lastTriggered`) VALUES ('LS-04', '高湿自动除湿', 'P-05', 18, 30, 60, 80, 50, '启动环流风机', '00:00-24:00', 1, '2026-11-06 06:40');
INSERT INTO `linkageStrategies` (`id`, `name`, `plotId`, `tempMin`, `tempMax`, `humidityMin`, `humidityMax`, `soilMin`, `action`, `window`, `enabled`, `lastTriggered`) VALUES ('LS-05', '育苗期定时补光', 'P-06', 22, 28, 65, 85, 55, '开启补光灯组', '16:00-22:00', 1, '2026-11-05 18:00');

-- ============ linkageLogs（5 条） ============
INSERT INTO `linkageLogs` (`id`, `time`, `strategy`, `detail`, `result`) VALUES ('EL-01', '2026-11-06 13:20:08', '高温自动通风', '1号棚温度 31.2℃，启动环流风机', '成功');
INSERT INTO `linkageLogs` (`id`, `time`, `strategy`, `detail`, `result`) VALUES ('EL-02', '2026-11-06 06:40:12', '高湿自动除湿', 'B区稻田湿度 84%，启动环流风机', '成功');
INSERT INTO `linkageLogs` (`id`, `time`, `strategy`, `detail`, `result`) VALUES ('EL-03', '2026-11-05 23:10:40', '夜间低温保温', '2号棚温度 15.4℃，关闭外遮阳卷帘', '成功');
INSERT INTO `linkageLogs` (`id`, `time`, `strategy`, `detail`, `result`) VALUES ('EL-04', '2026-11-05 18:00:05', '育苗期定时补光', '进入补光时段，开启补光灯组', '成功');
INSERT INTO `linkageLogs` (`id`, `time`, `strategy`, `detail`, `result`) VALUES ('EL-05', '2026-11-04 07:05:22', '土壤干旱自动补灌', '3号棚土壤湿度 38%，启动滴灌电磁阀', '失败');

-- ============ deviceOpRecords（2 条） ============
INSERT INTO `deviceOpRecords` (`id`, `time`, `text`) VALUES (1, '2026-11-06 09:40', '管理员下发 1号棚水泵启动指令');
INSERT INTO `deviceOpRecords` (`id`, `time`, `text`) VALUES (2, '2026-11-06 08:12', '安全锁开启，远程控制已锁定');

-- ============ workOrderCheckins（1 条） ============
INSERT INTO `workOrderCheckins` (`id`, `time`, `lat`, `lng`, `distance`) VALUES (1, '2026-11-06 08:34', '29.5912', '106.2205', '4.2 m');

-- ============ opApiKeys（2 条） ============
INSERT INTO `opApiKeys` (`id`, `name`, `key`, `scope`, `createdAt`) VALUES ('K-01', '运维自动化脚本', 'ak_ops_a12f****90bc', '设备读写 / 备份查询', '2026-09-12 10:20');
INSERT INTO `opApiKeys` (`id`, `name`, `key`, `scope`, `createdAt`) VALUES ('K-02', '监控告警回调', 'ak_mon_7c3d****e481', '只读 / 告警订阅', '2026-10-08 15:42');

-- ============ opSessions（3 条） ============
INSERT INTO `opSessions` (`id`, `device`, `browser`, `ip`, `location`, `time`, `current`) VALUES ('D-01', '运维工作站', 'Chrome 130 · Windows 11', '192.168.10.31', '园区机房内网', '2026-11-06 09:10', 1);
INSERT INTO `opSessions` (`id`, `device`, `browser`, `ip`, `location`, `time`, `current`) VALUES ('D-02', '值班笔记本', 'Edge 130 · Windows 11', '10.20.8.42', '璧山办公区', '2026-11-05 18:22', 0);
INSERT INTO `opSessions` (`id`, `device`, `browser`, `ip`, `location`, `time`, `current`) VALUES ('D-03', '移动巡检终端', 'Safari · iPadOS 18', '10.20.8.57', '园区东门值班室', '2026-11-04 08:15', 0);

-- ============ serviceHealth（5 条） ============
INSERT INTO `serviceHealth` (`name`, `desc`, `port`, `version`, `uptime`, `latency`, `status`) VALUES ('API 服务', 'Spring Boot 业务接口', 8080, '3.2.4', '128 天', 42, '运行中');
INSERT INTO `serviceHealth` (`name`, `desc`, `port`, `version`, `uptime`, `latency`, `status`) VALUES ('MQTT Broker', '设备消息接入与分发', 1883, 'EMQX 5.6', '128 天', 8, '运行中');
INSERT INTO `serviceHealth` (`name`, `desc`, `port`, `version`, `uptime`, `latency`, `status`) VALUES ('MySQL 数据库', '业务主数据存储', 3306, '8.0.36', '96 天', 6, '运行中');
INSERT INTO `serviceHealth` (`name`, `desc`, `port`, `version`, `uptime`, `latency`, `status`) VALUES ('Redis 缓存', '会话与热点数据缓存', 6379, '7.2.4', '96 天', 3, '运行中');
INSERT INTO `serviceHealth` (`name`, `desc`, `port`, `version`, `uptime`, `latency`, `status`) VALUES ('文件存储', '对象存储与附件服务', 9000, 'MinIO 2025', '64 天', 18, '告警');

-- ============ exportRecords（2 条） ============
INSERT INTO `exportRecords` (`id`, `name`, `format`, `time`, `rows`, `operator`, `status`) VALUES (1, '环境月报_2026-10.csv', 'CSV', '2026-11-05 16:30', 1, '李明', '成功');
INSERT INTO `exportRecords` (`id`, `name`, `format`, `time`, `rows`, `operator`, `status`) VALUES (2, '水肥消耗_2026Q3.xls', 'Excel', '2026-11-03 10:12', 3, '李明', '成功');

-- ============ videoReplays（7 条） ============
INSERT INTO `videoReplays` (`id`, `cameraId`, `cameraName`, `start`, `duration`, `size`, `daysAgo`) VALUES ('R-01', 'CAM-01', '1号大棚 · 东侧', '2026-11-06 09:00', '32 分钟', '186 MB', 0);
INSERT INTO `videoReplays` (`id`, `cameraId`, `cameraName`, `start`, `duration`, `size`, `daysAgo`) VALUES ('R-02', 'CAM-02', '1号大棚 · 西侧', '2026-11-06 08:30', '28 分钟', '164 MB', 0);
INSERT INTO `videoReplays` (`id`, `cameraId`, `cameraName`, `start`, `duration`, `size`, `daysAgo`) VALUES ('R-03', 'CAM-03', '2号草莓棚 · 入口', '2026-11-06 07:00', '45 分钟', '212 MB', 0);
INSERT INTO `videoReplays` (`id`, `cameraId`, `cameraName`, `start`, `duration`, `size`, `daysAgo`) VALUES ('R-04', 'CAM-04', '3号黄瓜棚 · 中部', '2026-11-05 16:20', '36 分钟', '198 MB', 1);
INSERT INTO `videoReplays` (`id`, `cameraId`, `cameraName`, `start`, `duration`, `size`, `daysAgo`) VALUES ('R-05', 'CAM-06', '稻田 · 灌渠', '2026-11-04 10:15', '52 分钟', '264 MB', 2);
INSERT INTO `videoReplays` (`id`, `cameraId`, `cameraName`, `start`, `duration`, `size`, `daysAgo`) VALUES ('R-06', 'CAM-01', '1号大棚 · 东侧', '2026-11-02 14:00', '40 分钟', '208 MB', 4);
INSERT INTO `videoReplays` (`id`, `cameraId`, `cameraName`, `start`, `duration`, `size`, `daysAgo`) VALUES ('R-07', 'CAM-05', '露天果园 · 全景', '2026-10-31 09:30', '25 分钟', '142 MB', 6);

-- ============ irrigationPlots（6 条） ============
INSERT INTO `irrigationPlots` (`id`, `plotId`, `moisture`, `planned`, `status`, `lastRun`) VALUES ('IR-01', 'P-01', 58, 28, '正常', '2026-11-06 06:20');
INSERT INTO `irrigationPlots` (`id`, `plotId`, `moisture`, `planned`, `status`, `lastRun`) VALUES ('IR-02', 'P-02', 43, 18, '正常', '2026-11-05 18:40');
INSERT INTO `irrigationPlots` (`id`, `plotId`, `moisture`, `planned`, `status`, `lastRun`) VALUES ('IR-03', 'P-03', 38, 24, '待灌溉', '2026-11-05 07:10');
INSERT INTO `irrigationPlots` (`id`, `plotId`, `moisture`, `planned`, `status`, `lastRun`) VALUES ('IR-04', 'P-04', 62, 36, '正常', '2026-11-06 05:50');
INSERT INTO `irrigationPlots` (`id`, `plotId`, `moisture`, `planned`, `status`, `lastRun`) VALUES ('IR-05', 'P-05', 51, 32, '正常', '2026-11-05 19:05');
INSERT INTO `irrigationPlots` (`id`, `plotId`, `moisture`, `planned`, `status`, `lastRun`) VALUES ('IR-06', 'P-06', 47, 14, '正常', '2026-11-04 16:30');

-- ============ irrigationSummary（单例） ============
INSERT INTO `irrigationSummary` (`todayWater`, `todayArea`, `savingRate`) VALUES (428, 96.4, 18.6);

