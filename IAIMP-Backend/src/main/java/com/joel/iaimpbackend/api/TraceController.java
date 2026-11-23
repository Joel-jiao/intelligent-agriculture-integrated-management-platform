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
 * 溯源域接口：批次档案、检测报告、召回记录、溯源详情与时间线。
 * 详情/时间线/批次等 GET 为公开接口（扫码溯源「无需登录」）。
 */
@RestController
@RequestMapping("/api/v1/trace")
@Tag(name = "产品溯源", description = "批次 / 检测 / 召回 / 溯源详情")
public class TraceController {

    private final ResourceService resourceService;

    public TraceController(ResourceService resourceService) {
        this.resourceService = resourceService;
    }

    // ---- 批次档案 ----
    @GetMapping("/batches")
    @Operation(summary = "溯源批次列表", description = "公开接口")
    public List<JsonNode> listBatches() {
        return resourceService.list(ResourceCollections.BATCHES);
    }

    @GetMapping("/batches/{id}")
    @Operation(summary = "溯源批次详情", description = "公开接口")
    public JsonNode getBatch(@PathVariable String id) {
        return resourceService.get(ResourceCollections.BATCHES, id);
    }

    @PostMapping("/batches")
    @Operation(summary = "新增批次")
    public JsonNode createBatch(@RequestBody JsonNode body) {
        return resourceService.create(ResourceCollections.BATCHES, body);
    }

    @PatchMapping("/batches/{id}")
    @Operation(summary = "更新批次（赋码 / 召回标记）")
    public JsonNode updateBatch(@PathVariable String id, @RequestBody JsonNode body) {
        return resourceService.update(ResourceCollections.BATCHES, id, body, true);
    }

    @DeleteMapping("/batches/{id}")
    @Operation(summary = "删除批次")
    public void deleteBatch(@PathVariable String id) {
        resourceService.delete(ResourceCollections.BATCHES, id);
    }

    // ---- 检测报告 ----
    @GetMapping("/inspections")
    @Operation(summary = "检测报告列表", description = "公开接口")
    public List<JsonNode> listInspections() {
        return resourceService.list(ResourceCollections.INSPECTIONS);
    }

    @PostMapping("/inspections")
    @Operation(summary = "新增检测报告")
    public JsonNode createInspection(@RequestBody JsonNode body) {
        return resourceService.create(ResourceCollections.INSPECTIONS, body);
    }

    // ---- 召回记录 ----
    @GetMapping("/recalls")
    @Operation(summary = "召回记录列表", description = "公开接口")
    public List<JsonNode> listRecalls() {
        return resourceService.list(ResourceCollections.RECALLS);
    }

    @PostMapping("/recalls")
    @Operation(summary = "新增召回记录")
    public JsonNode createRecall(@RequestBody JsonNode body) {
        return resourceService.create(ResourceCollections.RECALLS, body);
    }

    // ---- 溯源时间线（数组） ----
    @GetMapping("/timeline")
    @Operation(summary = "溯源时间线", description = "公开接口，返回数组")
    public List<JsonNode> timeline() {
        return resourceService.list(ResourceCollections.TRACE_TIMELINE);
    }

    @GetMapping("/{batchNo}/timeline")
    @Operation(summary = "指定批次溯源时间线", description = "公开接口")
    public List<JsonNode> batchTimeline(@PathVariable String batchNo) {
        return resourceService.list(ResourceCollections.TRACE_TIMELINE);
    }

    // ---- 溯源详情（单例对象） ----
    @GetMapping("/detail")
    @Operation(summary = "溯源详情", description = "公开接口，返回对象")
    public JsonNode detail() {
        return resourceService.getSingleton(ResourceCollections.TRACE_DETAIL);
    }

    @GetMapping("/{batchNo}/detail")
    @Operation(summary = "指定批次溯源详情", description = "公开接口")
    public JsonNode batchDetail(@PathVariable String batchNo) {
        return resourceService.getSingleton(ResourceCollections.TRACE_DETAIL);
    }
}
