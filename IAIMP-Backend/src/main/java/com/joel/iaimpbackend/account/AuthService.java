package com.joel.iaimpbackend.account;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.joel.iaimpbackend.account.dto.LoginResponse;
import com.joel.iaimpbackend.common.exception.ApiException;
import com.joel.iaimpbackend.common.security.CurrentUser;
import com.joel.iaimpbackend.common.security.JwtService;
import com.joel.iaimpbackend.resource.ResourceCollections;
import com.joel.iaimpbackend.resource.ResourceService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Map;

/**
 * 认证服务：登录（校验账号 + 签发 JWT + 写登录日志）、修改密码。
 */
@Service
public class AuthService {

    private static final DateTimeFormatter TIME_FORMAT =
            DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private static final Map<String, String> PORTAL_NAMES = Map.of(
            "admin", "管理员端",
            "ops", "运维端",
            "sup", "监管端",
            "app", "农户端"
    );

    private final AccountRepository accountRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final ResourceService resourceService;
    private final ObjectMapper objectMapper;

    public AuthService(AccountRepository accountRepository,
                       PasswordEncoder passwordEncoder,
                       JwtService jwtService,
                       ResourceService resourceService,
                       ObjectMapper objectMapper) {
        this.accountRepository = accountRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.resourceService = resourceService;
        this.objectMapper = objectMapper;
    }

    @Transactional
    public LoginResponse login(String portal, String account, String password, String ip) {
        Account entry = accountRepository.findByPortalAndAccount(portal, account).orElse(null);

        if (entry == null
                || !"启用".equals(entry.getStatus())
                || !passwordEncoder.matches(password == null ? "" : password, entry.getPassword())) {
            if (entry != null) {
                appendLoginLog(entry, "密码错误", "失败", ip);
            }
            throw ApiException.unauthorized("账号或密码错误");
        }

        String token = jwtService.sign(entry.getPortal(), entry.getAccount(),
                entry.getName(), entry.getRole());
        appendLoginLog(entry, "登录系统", "成功", ip);
        return new LoginResponse(token, new LoginResponse.SessionUser(
                entry.getPortal(), entry.getAccount(), entry.getName(), entry.getRole()));
    }

    @Transactional
    public void changePassword(CurrentUser.User user, String oldPassword, String newPassword) {
        if (user == null || user.portal() == null || user.account() == null) {
            throw ApiException.unauthorized("未登录或登录已过期");
        }
        String next = newPassword == null ? "" : newPassword;
        if (next.length() < 6) {
            throw ApiException.badRequest("新密码长度不能少于 6 位");
        }
        Account entry = accountRepository
                .findByPortalAndAccount(user.portal(), user.account())
                .orElseThrow(() -> ApiException.notFound("账号不存在"));
        if (!passwordEncoder.matches(oldPassword == null ? "" : oldPassword, entry.getPassword())) {
            throw ApiException.badRequest("原密码错误");
        }
        entry.setPassword(passwordEncoder.encode(next));
        accountRepository.save(entry);
    }

    private void appendLoginLog(Account entry, String action, String result, String ip) {
        ObjectNode log = objectMapper.createObjectNode();
        log.put("id", "LL-" + System.currentTimeMillis());
        log.put("account", entry.getAccount());
        log.put("name", entry.getName());
        log.put("action", action);
        log.put("module", PORTAL_NAMES.getOrDefault(entry.getPortal(), entry.getPortal()));
        log.put("ip", ip == null || ip.isBlank() ? "127.0.0.1" : ip);
        log.put("time", LocalDateTime.now().format(TIME_FORMAT));
        log.put("result", result);
        try {
            resourceService.create(ResourceCollections.LOGIN_LOGS, log);
        } catch (Exception ignored) {
            // 登录日志写入失败不阻塞登录流程
        }
    }
}
