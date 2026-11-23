package com.joel.iaimpbackend.api;

import com.fasterxml.jackson.databind.JsonNode;
import com.joel.iaimpbackend.resource.ResourceCollections;
import com.joel.iaimpbackend.resource.ResourceService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 系统管理域接口：用户、角色、日志、备份、开放接口、文件、字典、租户、系统信息等。
 */
@RestController
@RequestMapping("/api/v1/system")
@Tag(name = "系统管理", description = "用户 / 角色 / 日志 / 备份 / 字典 / 租户 / 系统信息")
public class SystemController {

    private final ResourceService resourceService;

    public SystemController(ResourceService resourceService) {
        this.resourceService = resourceService;
    }

    // ---- 系统用户 ----
    @GetMapping("/users")
    @Operation(summary = "系统用户列表")
    public List<JsonNode> listUsers() {
        return resourceService.list(ResourceCollections.USERS);
    }

    @GetMapping("/users/{id}")
    @Operation(summary = "系统用户详情")
    public JsonNode getUser(@PathVariable String id) {
        return resourceService.get(ResourceCollections.USERS, id);
    }

    @PostMapping("/users")
    @Operation(summary = "新增系统用户")
    public JsonNode createUser(@RequestBody JsonNode body) {
        return resourceService.create(ResourceCollections.USERS, body);
    }

    @PatchMapping("/users/{id}")
    @Operation(summary = "更新系统用户")
    public JsonNode updateUser(@PathVariable String id, @RequestBody JsonNode body) {
        return resourceService.update(ResourceCollections.USERS, id, body, true);
    }

    @DeleteMapping("/users/{id}")
    @Operation(summary = "删除系统用户")
    public void deleteUser(@PathVariable String id) {
        resourceService.delete(ResourceCollections.USERS, id);
    }

    // ---- 角色 ----
    @GetMapping("/roles")
    @Operation(summary = "角色列表")
    public List<JsonNode> listRoles() {
        return resourceService.list(ResourceCollections.ROLES);
    }

    // ---- 日志 ----
    @GetMapping("/login-logs")
    @Operation(summary = "登录日志")
    public List<JsonNode> loginLogs() {
        return resourceService.list(ResourceCollections.LOGIN_LOGS);
    }

    @GetMapping("/operation-logs")
    @Operation(summary = "操作审计日志")
    public List<JsonNode> operationLogs() {
        return resourceService.list(ResourceCollections.OPERATION_LOGS);
    }

    // ---- 备份 ----
    @GetMapping("/backups")
    @Operation(summary = "数据库备份记录")
    public List<JsonNode> backups() {
        return resourceService.list(ResourceCollections.BACKUPS);
    }

    // ---- 开放接口 ----
    @GetMapping("/open-apis")
    @Operation(summary = "开放接口列表")
    public List<JsonNode> listOpenApis() {
        return resourceService.list(ResourceCollections.OPEN_APIS);
    }

    @GetMapping("/open-apis/{id}")
    @Operation(summary = "开放接口详情")
    public JsonNode getOpenApi(@PathVariable String id) {
        return resourceService.get(ResourceCollections.OPEN_APIS, id);
    }

    @PostMapping("/open-apis")
    @Operation(summary = "新增开放接口")
    public JsonNode createOpenApi(@RequestBody JsonNode body) {
        return resourceService.create(ResourceCollections.OPEN_APIS, body);
    }

    @PatchMapping("/open-apis/{id}")
    @Operation(summary = "更新开放接口")
    public JsonNode updateOpenApi(@PathVariable String id, @RequestBody JsonNode body) {
        return resourceService.update(ResourceCollections.OPEN_APIS, id, body, true);
    }

    @DeleteMapping("/open-apis/{id}")
    @Operation(summary = "删除开放接口")
    public void deleteOpenApi(@PathVariable String id) {
        resourceService.delete(ResourceCollections.OPEN_APIS, id);
    }

    // ---- 文件 ----
    @GetMapping("/files")
    @Operation(summary = "文件存储列表")
    public List<JsonNode> files() {
        return resourceService.list(ResourceCollections.FILES);
    }

    // ---- 数据字典 ----
    @GetMapping("/dicts")
    @Operation(summary = "数据字典列表")
    public List<JsonNode> listDicts() {
        return resourceService.list(ResourceCollections.DICT_TYPES);
    }

    @GetMapping("/dicts/{id}")
    @Operation(summary = "数据字典详情")
    public JsonNode getDict(@PathVariable String id) {
        return resourceService.get(ResourceCollections.DICT_TYPES, id);
    }

    @PostMapping("/dicts")
    @Operation(summary = "新增数据字典")
    public JsonNode createDict(@RequestBody JsonNode body) {
        return resourceService.create(ResourceCollections.DICT_TYPES, body);
    }

    @PatchMapping("/dicts/{id}")
    @Operation(summary = "更新数据字典")
    public JsonNode updateDict(@PathVariable String id, @RequestBody JsonNode body) {
        return resourceService.update(ResourceCollections.DICT_TYPES, id, body, true);
    }

    @DeleteMapping("/dicts/{id}")
    @Operation(summary = "删除数据字典")
    public void deleteDict(@PathVariable String id) {
        resourceService.delete(ResourceCollections.DICT_TYPES, id);
    }

    // ---- 租户 ----
    @GetMapping("/tenants")
    @Operation(summary = "租户列表")
    public List<JsonNode> listTenants() {
        return resourceService.list(ResourceCollections.TENANTS);
    }

    @GetMapping("/tenants/{id}")
    @Operation(summary = "租户详情")
    public JsonNode getTenant(@PathVariable String id) {
        return resourceService.get(ResourceCollections.TENANTS, id);
    }

    @PostMapping("/tenants")
    @Operation(summary = "新增租户")
    public JsonNode createTenant(@RequestBody JsonNode body) {
        return resourceService.create(ResourceCollections.TENANTS, body);
    }

    @PatchMapping("/tenants/{id}")
    @Operation(summary = "更新租户")
    public JsonNode updateTenant(@PathVariable String id, @RequestBody JsonNode body) {
        return resourceService.update(ResourceCollections.TENANTS, id, body, true);
    }

    @DeleteMapping("/tenants/{id}")
    @Operation(summary = "删除租户")
    public void deleteTenant(@PathVariable String id) {
        resourceService.delete(ResourceCollections.TENANTS, id);
    }

    // ---- 系统信息（单例，公开） ----
    @GetMapping("/info")
    @Operation(summary = "系统信息", description = "公开接口")
    public JsonNode sysInfo() {
        return resourceService.getSingleton(ResourceCollections.SYS_INFO);
    }

    // ---- 明细记录 ----
    @GetMapping("/login-devices")
    @Operation(summary = "登录设备明细")
    public List<JsonNode> loginDevices() {
        return resourceService.list(ResourceCollections.LOGIN_DEVICES);
    }

    @GetMapping("/api-keys")
    @Operation(summary = "API 密钥明细")
    public List<JsonNode> apiKeys() {
        return resourceService.list(ResourceCollections.OP_API_KEYS);
    }

    @GetMapping("/sessions")
    @Operation(summary = "在线会话明细")
    public List<JsonNode> sessions() {
        return resourceService.list(ResourceCollections.OP_SESSIONS);
    }

    @GetMapping("/services")
    @Operation(summary = "服务健康明细")
    public List<JsonNode> services() {
        return resourceService.list(ResourceCollections.SERVICE_HEALTH);
    }
}
