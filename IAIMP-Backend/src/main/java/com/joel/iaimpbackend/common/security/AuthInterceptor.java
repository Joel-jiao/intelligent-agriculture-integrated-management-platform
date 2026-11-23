package com.joel.iaimpbackend.common.security;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.util.AntPathMatcher;
import org.springframework.web.servlet.HandlerInterceptor;

import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;

/**
 * Bearer 令牌鉴权拦截器，等价于 json-server（server.cjs）的 authMiddleware：
 *  - 除公开白名单外，所有 /api/v1/** 请求必须携带有效 token，否则 401；
 *  - 公开白名单仅含登录、园区/系统基础信息、溯源公开查询与地块地理信息。
 */
public class AuthInterceptor implements HandlerInterceptor {

    private final JwtService jwtService;
    private final AntPathMatcher matcher = new AntPathMatcher();

    /** 公开白名单（方法, 路径模式），路径模式使用 Ant 风格。 */
    private static final List<Map.Entry<String, String>> PUBLIC = List.of(
            Map.entry("POST", "/api/v1/auth/login"),
            Map.entry("GET", "/api/v1/park/overview"),
            Map.entry("GET", "/api/v1/system/info"),
            Map.entry("GET", "/api/v1/trace/detail"),
            Map.entry("GET", "/api/v1/trace/timeline"),
            Map.entry("GET", "/api/v1/trace/batches"),
            Map.entry("GET", "/api/v1/trace/batches/*"),
            Map.entry("GET", "/api/v1/trace/inspections"),
            Map.entry("GET", "/api/v1/trace/recalls"),
            Map.entry("GET", "/api/v1/trace/*/detail"),
            Map.entry("GET", "/api/v1/trace/*/timeline"),
            Map.entry("GET", "/api/v1/farm/plots"),
            Map.entry("GET", "/api/v1/farm/plots/*")
    );

    public AuthInterceptor(JwtService jwtService) {
        this.jwtService = jwtService;
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler)
            throws Exception {
        // CORS 预检直接放行
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            return true;
        }
        String path = request.getRequestURI();
        // 非业务接口（knife4j/swagger/error 等）不鉴权
        if (!path.startsWith("/api/v1/")) {
            return true;
        }
        if (isPublic(request.getMethod(), path)) {
            return true;
        }

        String auth = request.getHeader("Authorization");
        String token = (auth != null && auth.startsWith("Bearer ")) ? auth.substring(7) : "";
        Map<String, Object> payload = jwtService.verify(token);
        if (payload == null) {
            reject(response);
            return false;
        }
        CurrentUser.set(new CurrentUser.User(
                str(payload.get("portal")),
                str(payload.get("account")),
                str(payload.get("name")),
                str(payload.get("role"))));
        return true;
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response,
                                Object handler, Exception ex) {
        CurrentUser.clear();
    }

    private boolean isPublic(String method, String path) {
        for (Map.Entry<String, String> entry : PUBLIC) {
            if (entry.getKey().equalsIgnoreCase(method) && matcher.match(entry.getValue(), path)) {
                return true;
            }
        }
        return false;
    }

    private void reject(HttpServletResponse response) throws Exception {
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.setContentType("application/json;charset=UTF-8");
        response.getOutputStream().write(
                "{\"error\":\"未登录或登录已过期\"}".getBytes(StandardCharsets.UTF_8));
    }

    private static String str(Object value) {
        return value == null ? "" : String.valueOf(value);
    }
}
