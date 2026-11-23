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
 * 农场域接口：地块、采收、农资、工单、地块审核、农户地块、工单打卡。
 */
@RestController
@RequestMapping("/api/v1")
@Tag(name = "农场管理", description = "地块 / 采收 / 农资 / 工单 / 地块审核")
public class FarmController {

    private final ResourceService resourceService;

    public FarmController(ResourceService resourceService) {
        this.resourceService = resourceService;
    }

    // ---- 地块 ----
    @GetMapping("/farm/plots")
    @Operation(summary = "地块列表", description = "公开接口（溯源 H5 / GIS 使用）")
    public List<JsonNode> listPlots() {
        return resourceService.list(ResourceCollections.PLOTS);
    }

    @GetMapping("/farm/plots/{id}")
    @Operation(summary = "地块详情")
    public JsonNode getPlot(@PathVariable String id) {
        return resourceService.get(ResourceCollections.PLOTS, id);
    }

    @PostMapping("/farm/plots")
    @Operation(summary = "新增地块")
    public JsonNode createPlot(@RequestBody JsonNode body) {
        return resourceService.create(ResourceCollections.PLOTS, body);
    }

    @PatchMapping("/farm/plots/{id}")
    @Operation(summary = "更新地块")
    public JsonNode updatePlot(@PathVariable String id, @RequestBody JsonNode body) {
        return resourceService.update(ResourceCollections.PLOTS, id, body, true);
    }

    @DeleteMapping("/farm/plots/{id}")
    @Operation(summary = "删除地块")
    public void deletePlot(@PathVariable String id) {
        resourceService.delete(ResourceCollections.PLOTS, id);
    }

    // ---- 采收登记 ----
    @GetMapping("/farm/harvests")
    @Operation(summary = "采收记录列表")
    public List<JsonNode> listHarvests() {
        return resourceService.list(ResourceCollections.HARVESTS);
    }

    @PostMapping("/farm/harvests")
    @Operation(summary = "新增采收记录")
    public JsonNode createHarvest(@RequestBody JsonNode body) {
        return resourceService.create(ResourceCollections.HARVESTS, body);
    }

    // ---- 农资库存 ----
    @GetMapping("/farm/materials")
    @Operation(summary = "农资库存列表")
    public List<JsonNode> listMaterials() {
        return resourceService.list(ResourceCollections.MATERIALS);
    }

    @PostMapping("/farm/materials")
    @Operation(summary = "新增农资")
    public JsonNode createMaterial(@RequestBody JsonNode body) {
        return resourceService.create(ResourceCollections.MATERIALS, body);
    }

    // ---- 农事工单 ----
    @GetMapping("/farm/work-orders")
    @Operation(summary = "工单列表")
    public List<JsonNode> listWorkOrders() {
        return resourceService.list(ResourceCollections.WORK_ORDERS);
    }

    @GetMapping("/farm/work-orders/{id}")
    @Operation(summary = "工单详情")
    public JsonNode getWorkOrder(@PathVariable String id) {
        return resourceService.get(ResourceCollections.WORK_ORDERS, id);
    }

    @PostMapping("/farm/work-orders")
    @Operation(summary = "新增工单")
    public JsonNode createWorkOrder(@RequestBody JsonNode body) {
        return resourceService.create(ResourceCollections.WORK_ORDERS, body);
    }

    @PatchMapping("/farm/work-orders/{id}")
    @Operation(summary = "更新工单（含状态流转）")
    public JsonNode updateWorkOrder(@PathVariable String id, @RequestBody JsonNode body) {
        return resourceService.update(ResourceCollections.WORK_ORDERS, id, body, true);
    }

    @DeleteMapping("/farm/work-orders/{id}")
    @Operation(summary = "删除工单")
    public void deleteWorkOrder(@PathVariable String id) {
        resourceService.delete(ResourceCollections.WORK_ORDERS, id);
    }

    // ---- 地块档案审核 ----
    @GetMapping("/farm/plot-audits")
    @Operation(summary = "地块审核列表")
    public List<JsonNode> listPlotAudits() {
        return resourceService.list(ResourceCollections.PLOT_AUDITS);
    }

    @GetMapping("/farm/plot-audits/{id}")
    @Operation(summary = "地块审核详情")
    public JsonNode getPlotAudit(@PathVariable String id) {
        return resourceService.get(ResourceCollections.PLOT_AUDITS, id);
    }

    @PostMapping("/farm/plot-audits")
    @Operation(summary = "新增地块审核")
    public JsonNode createPlotAudit(@RequestBody JsonNode body) {
        return resourceService.create(ResourceCollections.PLOT_AUDITS, body);
    }

    @PatchMapping("/farm/plot-audits/{id}")
    @Operation(summary = "更新地块审核（通过 / 驳回）")
    public JsonNode updatePlotAudit(@PathVariable String id, @RequestBody JsonNode body) {
        return resourceService.update(ResourceCollections.PLOT_AUDITS, id, body, true);
    }

    @DeleteMapping("/farm/plot-audits/{id}")
    @Operation(summary = "删除地块审核")
    public void deletePlotAudit(@PathVariable String id) {
        resourceService.delete(ResourceCollections.PLOT_AUDITS, id);
    }

    // ---- 农户地块 / 工单打卡 ----
    @GetMapping("/farmer/my-plots")
    @Operation(summary = "我的地块（农户端）")
    public List<JsonNode> listFarmerPlots() {
        return resourceService.list(ResourceCollections.FARMER_PLOTS);
    }

    @GetMapping("/farm/work-order-checkins")
    @Operation(summary = "工单打卡记录")
    public List<JsonNode> listWorkOrderCheckins() {
        return resourceService.list(ResourceCollections.WORK_ORDER_CHECKINS);
    }
}
