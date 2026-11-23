package com.joel.iaimpbackend.resource;

/**
 * 集合名称常量：与前端 db.json 的顶层 key、routes.json 的目标集合一一对应。
 */
public final class ResourceCollections {

    private ResourceCollections() {}

    // 农业地块与农事
    public static final String PLOTS = "plots";
    public static final String HARVESTS = "harvests";
    public static final String MATERIALS = "materials";
    public static final String WORK_ORDERS = "workOrders";
    public static final String PLOT_AUDITS = "plotAudits";
    public static final String FARMER_PLOTS = "farmerPlots";
    public static final String WORK_ORDER_CHECKINS = "workOrderCheckins";

    // 物联网
    public static final String DEVICES = "devices";
    public static final String CAMERAS = "cameras";
    public static final String DEVICE_OP_RECORDS = "deviceOpRecords";
    public static final String VIDEO_REPLAYS = "videoReplays";

    // 告警与消息
    public static final String ALARMS = "alarms";
    public static final String MESSAGES = "messages";

    // 溯源
    public static final String BATCHES = "batches";
    public static final String INSPECTIONS = "inspections";
    public static final String RECALLS = "recalls";

    // 监管
    public static final String SUP_WARNINGS = "supWarnings";

    // 系统
    public static final String USERS = "users";
    public static final String ROLES = "roles";
    public static final String LOGIN_LOGS = "loginLogs";
    public static final String OPERATION_LOGS = "operationLogs";
    public static final String BACKUPS = "backups";
    public static final String OPEN_APIS = "openApis";
    public static final String FILES = "files";
    public static final String TENANTS = "tenants";
    public static final String DICT_TYPES = "dictTypes";
    public static final String LOGIN_DEVICES = "loginDevices";
    public static final String OP_API_KEYS = "opApiKeys";
    public static final String OP_SESSIONS = "opSessions";
    public static final String SERVICE_HEALTH = "serviceHealth";

    // 质量与报表
    public static final String PESTICIDE_LEDGER = "pesticideLedger";
    public static final String MONTHLY_REPORT = "monthlyReport";
    public static final String EXPORT_RECORDS = "exportRecords";

    // 控制
    public static final String CONTROL_LOGS = "controlLogs";
    public static final String IRRIGATION_PLOTS = "irrigationPlots";
    public static final String IRRIGATION_SUMMARY = "irrigationSummary";
    public static final String LINKAGE_STRATEGIES = "linkageStrategies";
    public static final String LINKAGE_LOGS = "linkageLogs";

    // 聚合 / 单例对象
    public static final String PARK = "park";
    public static final String WEATHER = "weather";
    public static final String ENV_SERIES = "envSeries";
    public static final String WATER_ELECTRIC = "waterElectric";
    public static final String TRACE_TIMELINE = "traceTimeline";
    public static final String TRACE_DETAIL = "traceDetail";
    public static final String QUALITY_OVERVIEW = "qualityOverview";
    public static final String SYS_INFO = "sysInfo";
    public static final String SCREEN_CONFIG = "screenConfig";

    /** 单例集合：每条集合只存一条记录，GET 返回对象而非数组。 */
    public static final String[] SINGLETONS = {
            PARK, WEATHER, ENV_SERIES, WATER_ELECTRIC, TRACE_DETAIL,
            QUALITY_OVERVIEW, SYS_INFO, SCREEN_CONFIG, IRRIGATION_SUMMARY
    };
}
