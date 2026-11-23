package com.joel.iaimpbackend.common.security;

/**
 * 当前请求的登录用户上下文（ThreadLocal），由 AuthInterceptor 注入，
 * 供控制器读取 portal/account 等信息（例如改密时定位账号）。
 */
public final class CurrentUser {

    /** 令牌解析出的登录用户。 */
    public record User(String portal, String account, String name, String role) {}

    private static final ThreadLocal<User> HOLDER = new ThreadLocal<>();

    private CurrentUser() {}

    public static void set(User user) {
        HOLDER.set(user);
    }

    public static User get() {
        return HOLDER.get();
    }

    public static void clear() {
        HOLDER.remove();
    }
}
