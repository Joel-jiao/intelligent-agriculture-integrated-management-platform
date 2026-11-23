package com.joel.iaimpbackend.account.dto;

/**
 * 登录请求体：门户 + 账号 + 密码（与前端 /auth/login 入参一致）。
 */
public record LoginRequest(String portal, String account, String password) {}
