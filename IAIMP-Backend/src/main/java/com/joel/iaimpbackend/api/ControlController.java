package com.joel.iaimpbackend.api;

import com.fasterxml.jackson.databind.JsonNode;
import com.joel.iaimpbackend.resource.ResourceCollections;
import com.joel.iaimpbackend.resource.ResourceService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 控制域接口：控制日志、灌溉地块/统计、联动策略/日志。
 */
@RestController
@RequestMapping("/api/v1/control")
@Tag(name = "设备控制", description = "控制日志 / 灌溉 / 联动策略")
public class ControlController {

    private final ResourceService resourceService;

    public ControlController(ResourceService resourceService) {
        this.resourceService = resourceService;
    }

    @GetMapping("/logs")
    @Operation(summary = "控制日志")
    public List<JsonNode> logs() {
        return resourceService.list(ResourceCollections.CONTROL_LOGS);
    }

    @GetMapping("/irrigation-plots")
    @Operation(summary = "灌溉地块明细")
    public List<JsonNode> irrigationPlots() {
        return resourceService.list(ResourceCollections.IRRIGATION_PLOTS);
    }

    @GetMapping("/irrigation-summary")
    @Operation(summary = "灌溉今日统计（单例）")
    public JsonNode irrigationSummary() {
        return resourceService.getSingleton(ResourceCollections.IRRIGATION_SUMMARY);
    }

    @GetMapping("/linkage-strategies")
    @Operation(summary = "自动联动策略")
    public List<JsonNode> linkageStrategies() {
        return resourceService.list(ResourceCollections.LINKAGE_STRATEGIES);
    }

    @GetMapping("/linkage-logs")
    @Operation(summary = "联动执行日志")
    public List<JsonNode> linkageLogs() {
        return resourceService.list(ResourceCollections.LINKAGE_LOGS);
    }
}
