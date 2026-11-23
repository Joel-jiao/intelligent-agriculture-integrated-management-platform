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
 * 监管域接口：监管预警管理。
 */
@RestController
@RequestMapping("/api/v1/supervise")
@Tag(name = "监管管理", description = "监管预警")
public class SuperviseController {

    private final ResourceService resourceService;

    public SuperviseController(ResourceService resourceService) {
        this.resourceService = resourceService;
    }

    @GetMapping("/warnings")
    @Operation(summary = "监管预警列表")
    public List<JsonNode> listWarnings() {
        return resourceService.list(ResourceCollections.SUP_WARNINGS);
    }

    @GetMapping("/warnings/{id}")
    @Operation(summary = "监管预警详情")
    public JsonNode getWarning(@PathVariable String id) {
        return resourceService.get(ResourceCollections.SUP_WARNINGS, id);
    }

    @PostMapping("/warnings")
    @Operation(summary = "新增监管预警")
    public JsonNode createWarning(@RequestBody JsonNode body) {
        return resourceService.create(ResourceCollections.SUP_WARNINGS, body);
    }

    @PatchMapping("/warnings/{id}")
    @Operation(summary = "更新监管预警（办结 / 处理）")
    public JsonNode updateWarning(@PathVariable String id, @RequestBody JsonNode body) {
        return resourceService.update(ResourceCollections.SUP_WARNINGS, id, body, true);
    }

    @DeleteMapping("/warnings/{id}")
    @Operation(summary = "删除监管预警")
    public void deleteWarning(@PathVariable String id) {
        resourceService.delete(ResourceCollections.SUP_WARNINGS, id);
    }
}
