package com.joel.iaimpbackend.common.security;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * 手写 HS256 JWT，与前端 json-server（server.cjs）的签发/校验逻辑逐字节对齐：
 *  - header/payload 用 base64url（无填充）编码；
 *  - exp 使用「毫秒」时间戳（前端 useAuth.isTokenValid 用 Date.now() 比较）。
 * 因此不能使用标准 JWT 库（其 exp 为秒），这里用 JDK 内置 Mac + Base64 实现。
 */
public class JwtService {

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final String secret;
    private final long ttlMs;

    public JwtService(String secret, long ttlMs) {
        this.secret = secret;
        this.ttlMs = ttlMs;
    }

    /** 登录成功后签发令牌，payload 含 portal/account/name/role/exp。 */
    public String sign(String portal, String account, String name, String role) {
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("portal", portal);
        payload.put("account", account);
        payload.put("name", name);
        payload.put("role", role);
        payload.put("exp", System.currentTimeMillis() + ttlMs);
        return signRaw(payload);
    }

    /** 校验令牌，返回 payload；无效或过期返回 null。 */
    public Map<String, Object> verify(String token) {
        if (token == null || token.isEmpty()) {
            return null;
        }
        String[] parts = token.split("\\.");
        if (parts.length != 3) {
            return null;
        }
        String expected = hmac(parts[0] + "." + parts[1]);
        if (!constantTimeEquals(expected, parts[2])) {
            return null;
        }
        try {
            byte[] decoded = Base64.getUrlDecoder().decode(parts[1]);
            Map<String, Object> payload = objectMapper.readValue(
                    decoded, new TypeReference<Map<String, Object>>() {});
            Object exp = payload.get("exp");
            if (exp instanceof Number && System.currentTimeMillis() > ((Number) exp).longValue()) {
                return null;
            }
            return payload;
        } catch (Exception e) {
            return null;
        }
    }

    private String signRaw(Map<String, Object> payload) {
        try {
            String header = b64("{\"alg\":\"HS256\",\"typ\":\"JWT\"}");
            String body = b64(objectMapper.writeValueAsString(payload));
            return header + "." + body + "." + hmac(header + "." + body);
        } catch (Exception e) {
            throw new IllegalStateException("JWT 签发失败", e);
        }
    }

    private String hmac(String data) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            return Base64.getUrlEncoder().withoutPadding()
                    .encodeToString(mac.doFinal(data.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception e) {
            throw new IllegalStateException("HMAC 计算失败", e);
        }
    }

    private String b64(String raw) {
        return Base64.getUrlEncoder().withoutPadding()
                .encodeToString(raw.getBytes(StandardCharsets.UTF_8));
    }

    private boolean constantTimeEquals(String a, String b) {
        if (a == null || b == null || a.length() != b.length()) {
            return false;
        }
        int result = 0;
        for (int i = 0; i < a.length(); i++) {
            result |= a.charAt(i) ^ b.charAt(i);
        }
        return result == 0;
    }
}
