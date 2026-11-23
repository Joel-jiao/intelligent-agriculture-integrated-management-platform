package com.joel.iaimpbackend.api;

import com.fasterxml.jackson.databind.JsonNode;
import com.joel.iaimpbackend.resource.ResourceCollections;
import com.joel.iaimpbackend.resource.ResourceService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 质量安全域接口：质量总览、农药农资台账。
 */
@RestController
@RequestMapping("/api/v1/quality")
@Tag(name = "质量安全", description = "质量总览 / 农药台账")
public class QualityController {

    private final ResourceService resourceService;

    public QualityController(ResourceService resourceService) {
        this.resourceService = resourceService;
    }

    @GetMapping("/overview")
    @Operation(summary = "质量安全总览")
    public JsonNode overview() {
        return resourceService.getSingleton(ResourceCollections.QUALITY_OVERVIEW);
    }

    @GetMapping("/pesticide-ledger")
    @Operation(summary = "农药农资使用记录")
    public List<JsonNode> pesticideLedger() {
        return resourceService.list(ResourceCollections.PESTICIDE_LEDGER);
    }

    @PostMapping("/pesticide-ledger")
    @Operation(summary = "新增农药使用记录")
    public JsonNode createPesticideLedger(@RequestBody JsonNode body) {
        return resourceService.create(ResourceCollections.PESTICIDE_LEDGER, body);
    }
}
