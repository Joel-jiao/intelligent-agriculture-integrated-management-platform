package com.joel.iaimpbackend.account;

import com.joel.iaimpbackend.account.dto.ChangePasswordRequest;
import com.joel.iaimpbackend.account.dto.LoginRequest;
import com.joel.iaimpbackend.account.dto.LoginResponse;
import com.joel.iaimpbackend.common.exception.ApiException;
import com.joel.iaimpbackend.common.security.CurrentUser;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/auth")
@Tag(name = "认证", description = "登录与修改密码")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/login")
    @Operation(summary = "登录", description = "校验账号密码并签发令牌，portal 取 admin/ops/sup/app")
    public LoginResponse login(@RequestBody LoginRequest request, HttpServletRequest http) {
        if (request.portal() == null || request.portal().isBlank()
                || request.account() == null || request.account().isBlank()) {
            throw ApiException.badRequest("账号或密码错误");
        }
        return authService.login(request.portal(), request.account(), request.password(), clientIp(http));
    }

    @PostMapping("/change-password")
    @Operation(summary = "修改密码", description = "需携带登录令牌，校验原密码后更新")
    public Map<String, Boolean> changePassword(@RequestBody ChangePasswordRequest request) {
        authService.changePassword(CurrentUser.get(), request.oldPassword(), request.newPassword());
        return Map.of("ok", true);
    }

    private String clientIp(HttpServletRequest request) {
        String forwarded = request.getHeader("X-Forwarded-For");
        if (forwarded != null && !forwarded.isBlank()) {
            return forwarded.split(",")[0].trim();
        }
        String remote = request.getRemoteAddr();
        return remote == null ? "" : remote;
    }
}
