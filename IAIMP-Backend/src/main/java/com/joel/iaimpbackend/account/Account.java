package com.joel.iaimpbackend.account;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * 登录账号（对应 json-server 的 accounts 集合）。
 * 密码以 BCrypt 哈希存储，绝不落明文。
 *
 * 表结构对应 sql/agri_platform.sql 的 accounts 表：
 *  id 为业务主键（如 A-001），无自增列。
 */
@Entity
@Table(name = "accounts")
@Getter
@Setter
@NoArgsConstructor
public class Account {

    /** 业务账号ID（如 A-001）。 */
    @Id
    @Column(name = "id", nullable = false)
    private String id;

    /** 门户：admin / ops / sup / app。 */
    @Column(nullable = false)
    private String portal;

    /** 登录账号。 */
    @Column(nullable = false)
    private String account;

    /** BCrypt 哈希后的密码。 */
    @Column(nullable = false)
    private String password;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private String role;

    /** 启用 / 停用。 */
    @Column(nullable = false)
    private String status;
}
