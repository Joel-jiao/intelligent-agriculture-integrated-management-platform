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
 * 报表域接口：月度报表、导出记录。
 */
@RestController
@RequestMapping("/api/v1/report")
@Tag(name = "综合报表", description = "月度报表 / 导出记录")
public class ReportController {

    private final ResourceService resourceService;

    public ReportController(ResourceService resourceService) {
        this.resourceService = resourceService;
    }

    @GetMapping("/monthly")
    @Operation(summary = "月度报表数据")
    public List<JsonNode> monthly() {
        return resourceService.list(ResourceCollections.MONTHLY_REPORT);
    }

    @GetMapping("/exports")
    @Operation(summary = "导出记录")
    public List<JsonNode> exports() {
        return resourceService.list(ResourceCollections.EXPORT_RECORDS);
    }
}
