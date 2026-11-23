package com.joel.iaimpbackend.api;

import com.fasterxml.jackson.databind.JsonNode;
import com.joel.iaimpbackend.resource.ResourceCollections;
import com.joel.iaimpbackend.resource.ResourceService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 概览 / 聚合单例接口：园区概览、实时天气、水电计量、大屏配置。
 */
@RestController
@RequestMapping("/api/v1")
@Tag(name = "概览与聚合", description = "园区概览 / 天气 / 水电 / 大屏配置")
public class OverviewController {

    private final ResourceService resourceService;

    public OverviewController(ResourceService resourceService) {
        this.resourceService = resourceService;
    }

    @GetMapping("/park/overview")
    @Operation(summary = "园区概览", description = "公开接口")
    public JsonNode park() {
        return resourceService.getSingleton(ResourceCollections.PARK);
    }

    @GetMapping("/weather/current")
    @Operation(summary = "实时天气")
    public JsonNode weather() {
        return resourceService.getSingleton(ResourceCollections.WEATHER);
    }

    @GetMapping("/energy/water-electric")
    @Operation(summary = "水电计量统计")
    public JsonNode waterElectric() {
        return resourceService.getSingleton(ResourceCollections.WATER_ELECTRIC);
    }

    @GetMapping("/screen/config")
    @Operation(summary = "大屏展示配置")
    public JsonNode screenConfig() {
        return resourceService.getSingleton(ResourceCollections.SCREEN_CONFIG);
    }
}
