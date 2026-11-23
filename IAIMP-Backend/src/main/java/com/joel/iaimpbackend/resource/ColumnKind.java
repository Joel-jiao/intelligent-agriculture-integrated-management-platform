package com.joel.iaimpbackend.resource;

/**
 * 表列类型分类，用于 JSON 与数据库列值之间的双向转换。
 */
public enum ColumnKind {
    /** varchar / char / text / longtext */
    STRING,
    /** int / bigint / smallint / mediumint / tinyint(>1) */
    INTEGER,
    /** decimal / numeric / float / double */
    DECIMAL,
    /** tinyint(1) */
    BOOLEAN,
    /** json */
    JSON,
    /** date */
    DATE,
    /** datetime / timestamp */
    DATETIME
}
