package com.joel.iaimpbackend.resource;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.BooleanNode;
import com.fasterxml.jackson.databind.node.DoubleNode;
import com.fasterxml.jackson.databind.node.LongNode;
import com.fasterxml.jackson.databind.node.NullNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.fasterxml.jackson.databind.node.TextNode;
import com.joel.iaimpbackend.common.exception.ApiException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

/**
 * 结构化资源服务：按「集合名 = 表名」对 48 张业务表做通用 CRUD，
 * 语义与 json-server 保持一致（GET 返回数组或对象、PATCH 浅合并、DELETE 按 id 删除）。
 * 列值与 JSON 之间的双向转换依据表结构元数据（{@link SchemaService}）自动完成。
 */
@Service
public class ResourceService {

    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd");
    private static final DateTimeFormatter DATETIME_FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private final JdbcTemplate jdbc;
    private final SchemaService schemaService;
    private final ObjectMapper objectMapper;

    public ResourceService(JdbcTemplate jdbc, SchemaService schemaService, ObjectMapper objectMapper) {
        this.jdbc = jdbc;
        this.schemaService = schemaService;
        this.objectMapper = objectMapper;
    }

    @Transactional(readOnly = true)
    public List<JsonNode> list(String collection) {
        Map<String, ColumnKind> schema = schemaService.columnsOf(collection);
        List<Map<String, Object>> rows = jdbc.queryForList(
                "SELECT * FROM `" + collection + "` ORDER BY `id`");
        List<JsonNode> result = new ArrayList<>(rows.size());
        for (Map<String, Object> row : rows) {
            result.add(rowToJson(row, schema));
        }
        return result;
    }

    @Transactional(readOnly = true)
    public JsonNode get(String collection, String docId) {
        Map<String, ColumnKind> schema = schemaService.columnsOf(collection);
        List<Map<String, Object>> rows = jdbc.queryForList(
                "SELECT * FROM `" + collection + "` WHERE `id` = ?", docId);
        if (rows.isEmpty()) {
            throw ApiException.notFound("Not found");
        }
        return rowToJson(rows.get(0), schema);
    }

    /** 读取单例集合的唯一对象（去掉自增 id 列）；不存在则返回 null。 */
    @Transactional(readOnly = true)
    public JsonNode getSingleton(String collection) {
        Map<String, ColumnKind> schema = schemaService.columnsOf(collection);
        List<Map<String, Object>> rows = jdbc.queryForList(
                "SELECT * FROM `" + collection + "` LIMIT 1");
        if (rows.isEmpty()) {
            return null;
        }
        JsonNode node = rowToJson(rows.get(0), schema);
        if (node.isObject()) {
            ((ObjectNode) node).remove("id");
        }
        return node;
    }

    @Transactional
    public JsonNode create(String collection, JsonNode body) {
        if (body == null || !body.isObject()) {
            throw ApiException.badRequest("请求体必须是 JSON 对象");
        }
        Map<String, ColumnKind> schema = schemaService.columnsOf(collection);
        List<String> cols = new ArrayList<>();
        List<Object> args = new ArrayList<>();
        Iterator<Map.Entry<String, JsonNode>> it = body.fields();
        while (it.hasNext()) {
            Map.Entry<String, JsonNode> f = it.next();
            String col = f.getKey();
            ColumnKind kind = schema.get(col);
            if (kind == null) {
                continue; // 忽略未知列
            }
            cols.add("`" + col + "`");
            args.add(convertWrite(f.getValue(), kind));
        }
        if (cols.isEmpty()) {
            throw ApiException.badRequest("请求体没有可写入的字段");
        }
        String placeholders = String.join(", ", Collections.nCopies(cols.size(), "?"));
        String sql = "INSERT INTO `" + collection + "` ("
                + String.join(", ", cols) + ") VALUES (" + placeholders + ")";
        jdbc.update(sql, args.toArray());
        return body;
    }

    @Transactional
    public JsonNode update(String collection, String docId, JsonNode body, boolean merge) {
        Map<String, ColumnKind> schema = schemaService.columnsOf(collection);
        JsonNode existing = get(collection, docId);
        ObjectNode next;
        if (merge && body != null && body.isObject()) {
            next = ((ObjectNode) existing).deepCopy();
            Iterator<Map.Entry<String, JsonNode>> it = body.fields();
            while (it.hasNext()) {
                Map.Entry<String, JsonNode> f = it.next();
                next.set(f.getKey(), f.getValue());
            }
        } else {
            if (body == null || !body.isObject()) {
                throw ApiException.badRequest("请求体必须是 JSON 对象");
            }
            next = ((ObjectNode) body).deepCopy();
        }
        next.put("id", docId);

        List<String> setClauses = new ArrayList<>();
        List<Object> args = new ArrayList<>();
        Iterator<Map.Entry<String, JsonNode>> it = next.fields();
        while (it.hasNext()) {
            Map.Entry<String, JsonNode> f = it.next();
            String col = f.getKey();
            if ("id".equals(col)) {
                continue; // 主键不更新
            }
            ColumnKind kind = schema.get(col);
            if (kind == null) {
                continue;
            }
            setClauses.add("`" + col + "` = ?");
            args.add(convertWrite(f.getValue(), kind));
        }
        if (setClauses.isEmpty()) {
            return next;
        }
        args.add(docId);
        String sql = "UPDATE `" + collection + "` SET "
                + String.join(", ", setClauses) + " WHERE `id` = ?";
        int n = jdbc.update(sql, args.toArray());
        if (n == 0) {
            throw ApiException.notFound("Not found");
        }
        return next;
    }

    @Transactional
    public void delete(String collection, String docId) {
        int n = jdbc.update("DELETE FROM `" + collection + "` WHERE `id` = ?", docId);
        if (n == 0) {
            throw ApiException.notFound("Not found");
        }
    }

    // ---------- 读转换：数据库列值 -> JSON ----------

    private JsonNode rowToJson(Map<String, Object> row, Map<String, ColumnKind> schema) {
        ObjectNode node = objectMapper.createObjectNode();
        for (Map.Entry<String, Object> e : row.entrySet()) {
            ColumnKind kind = schema.getOrDefault(e.getKey(), ColumnKind.STRING);
            node.set(e.getKey(), convertRead(e.getValue(), kind));
        }
        return node;
    }

    private JsonNode convertRead(Object val, ColumnKind kind) {
        if (val == null) {
            return NullNode.getInstance();
        }
        switch (kind) {
            case JSON: {
                try {
                    return objectMapper.readTree(val.toString());
                } catch (Exception e) {
                    return TextNode.valueOf(val.toString());
                }
            }
            case BOOLEAN: {
                if (val instanceof Boolean b) {
                    return BooleanNode.valueOf(b);
                }
                if (val instanceof Number n) {
                    return BooleanNode.valueOf(n.intValue() != 0);
                }
                return BooleanNode.valueOf(Boolean.parseBoolean(val.toString()));
            }
            case INTEGER: {
                if (val instanceof Number n) {
                    return LongNode.valueOf(n.longValue());
                }
                return TextNode.valueOf(val.toString());
            }
            case DECIMAL: {
                if (val instanceof Number n) {
                    return DoubleNode.valueOf(n.doubleValue());
                }
                return TextNode.valueOf(val.toString());
            }
            case DATE:
                return TextNode.valueOf(formatDate(val));
            case DATETIME:
                return TextNode.valueOf(formatDateTime(val));
            default:
                return TextNode.valueOf(val.toString());
        }
    }

    private String formatDate(Object v) {
        if (v instanceof java.sql.Date d) {
            return d.toLocalDate().format(DATE_FMT);
        }
        if (v instanceof java.sql.Timestamp t) {
            return t.toLocalDateTime().toLocalDate().format(DATE_FMT);
        }
        if (v instanceof LocalDate ld) {
            return ld.format(DATE_FMT);
        }
        if (v instanceof LocalDateTime ldt) {
            return ldt.format(DATE_FMT);
        }
        return v.toString();
    }

    private String formatDateTime(Object v) {
        if (v instanceof java.sql.Timestamp t) {
            return t.toLocalDateTime().format(DATETIME_FMT);
        }
        if (v instanceof LocalDateTime ldt) {
            return ldt.format(DATETIME_FMT);
        }
        return v.toString();
    }

    // ---------- 写转换：JSON -> 数据库列值 ----------

    private Object convertWrite(JsonNode val, ColumnKind kind) {
        if (val == null || val.isNull()) {
            return null;
        }
        switch (kind) {
            case JSON:
                return val.toString();
            case BOOLEAN:
                return val.asBoolean();
            case INTEGER:
                return val.asLong();
            case DECIMAL:
                return val.asDouble();
            case DATE:
            case DATETIME:
                return val.asText();
            default:
                if (val.isTextual()) {
                    return val.asText();
                }
                if (val.isNumber()) {
                    return val.numberValue();
                }
                if (val.isBoolean()) {
                    return val.asBoolean();
                }
                return val.toString();
        }
    }
}
