package com.joel.iaimpbackend.account.dto;

/**
 * 登录成功返回体：token + 用户信息（与前端 useAuth.login 期望结构一致）。
 */
public record LoginResponse(String token, SessionUser user) {

    public record SessionUser(String portal, String account, String name, String role) {}
}
