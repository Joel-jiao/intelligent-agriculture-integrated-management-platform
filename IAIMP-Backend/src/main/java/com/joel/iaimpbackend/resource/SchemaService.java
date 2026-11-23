package com.joel.iaimpbackend.resource;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 表结构元数据服务：从 information_schema 读取每张表的列类型并缓存，
 * 供 ResourceService 在「JSON <-> 列值」转换时判断列的转换规则。
 */
@Service
public class SchemaService {

    private static final Set<String> INT_TYPES = Set.of("int", "bigint", "smallint", "mediumint");
    private static final Set<String> DEC_TYPES = Set.of("decimal", "numeric", "float", "double", "real");

    private final JdbcTemplate jdbc;
    private final Map<String, Map<String, ColumnKind>> cache = new ConcurrentHashMap<>();

    public SchemaService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    /** 返回某张表的「列名 -> 列类型」映射（缓存）。 */
    public Map<String, ColumnKind> columnsOf(String table) {
        return cache.computeIfAbsent(table, this::load);
    }

    private Map<String, ColumnKind> load(String table) {
        List<Map<String, Object>> rows = jdbc.queryForList(
                "SELECT column_name, data_type, column_type "
                        + "FROM information_schema.columns "
                        + "WHERE table_schema = DATABASE() AND table_name = ?",
                table);
        Map<String, ColumnKind> result = new LinkedHashMap<>();
        for (Map<String, Object> row : rows) {
            String col = String.valueOf(row.get("column_name"));
            String dataType = String.valueOf(row.get("data_type"));
            String colType = String.valueOf(row.get("column_type"));
            result.put(col, classify(dataType, colType));
        }
        return result;
    }

    private ColumnKind classify(String dataType, String colType) {
        if ("json".equals(dataType)) {
            return ColumnKind.JSON;
        }
        if ("tinyint".equals(dataType)) {
            // tinyint(1) 视为布尔，其余 tinyint 视为整数
            return (colType != null && colType.matches("tinyint\\(1\\).*"))
                    ? ColumnKind.BOOLEAN : ColumnKind.INTEGER;
        }
        if (INT_TYPES.contains(dataType)) {
            return ColumnKind.INTEGER;
        }
        if (DEC_TYPES.contains(dataType)) {
            return ColumnKind.DECIMAL;
        }
        if ("date".equals(dataType)) {
            return ColumnKind.DATE;
        }
        if ("datetime".equals(dataType) || "timestamp".equals(dataType)) {
            return ColumnKind.DATETIME;
        }
        return ColumnKind.STRING;
    }
}
