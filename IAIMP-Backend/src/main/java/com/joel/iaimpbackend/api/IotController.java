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
 * 物联网域接口：设备、摄像头、环境曲线、设备操作记录、录像回放。
 */
@RestController
@RequestMapping("/api/v1/iot")
@Tag(name = "物联网", description = "设备 / 摄像头 / 环境监测")
public class IotController {

    private final ResourceService resourceService;

    public IotController(ResourceService resourceService) {
        this.resourceService = resourceService;
    }

    // ---- 设备 ----
    @GetMapping("/devices")
    @Operation(summary = "设备列表")
    public List<JsonNode> listDevices() {
        return resourceService.list(ResourceCollections.DEVICES);
    }

    @GetMapping("/devices/{id}")
    @Operation(summary = "设备详情")
    public JsonNode getDevice(@PathVariable String id) {
        return resourceService.get(ResourceCollections.DEVICES, id);
    }

    @PostMapping("/devices")
    @Operation(summary = "新增设备")
    public JsonNode createDevice(@RequestBody JsonNode body) {
        return resourceService.create(ResourceCollections.DEVICES, body);
    }

    @PatchMapping("/devices/{id}")
    @Operation(summary = "更新设备（含远程控制）")
    public JsonNode updateDevice(@PathVariable String id, @RequestBody JsonNode body) {
        return resourceService.update(ResourceCollections.DEVICES, id, body, true);
    }

    @DeleteMapping("/devices/{id}")
    @Operation(summary = "删除设备")
    public void deleteDevice(@PathVariable String id) {
        resourceService.delete(ResourceCollections.DEVICES, id);
    }

    // ---- 摄像头 ----
    @GetMapping("/cameras")
    @Operation(summary = "摄像头列表")
    public List<JsonNode> listCameras() {
        return resourceService.list(ResourceCollections.CAMERAS);
    }

    @GetMapping("/cameras/{id}")
    @Operation(summary = "摄像头详情")
    public JsonNode getCamera(@PathVariable String id) {
        return resourceService.get(ResourceCollections.CAMERAS, id);
    }

    @PostMapping("/cameras")
    @Operation(summary = "新增摄像头")
    public JsonNode createCamera(@RequestBody JsonNode body) {
        return resourceService.create(ResourceCollections.CAMERAS, body);
    }

    @PatchMapping("/cameras/{id}")
    @Operation(summary = "更新摄像头")
    public JsonNode updateCamera(@PathVariable String id, @RequestBody JsonNode body) {
        return resourceService.update(ResourceCollections.CAMERAS, id, body, true);
    }

    @DeleteMapping("/cameras/{id}")
    @Operation(summary = "删除摄像头")
    public void deleteCamera(@PathVariable String id) {
        resourceService.delete(ResourceCollections.CAMERAS, id);
    }

    // ---- 环境曲线（单例） ----
    @GetMapping("/env-series")
    @Operation(summary = "环境监测曲线数据")
    public JsonNode envSeries() {
        return resourceService.getSingleton(ResourceCollections.ENV_SERIES);
    }

    // ---- 明细记录 ----
    @GetMapping("/op-records")
    @Operation(summary = "设备操作记录")
    public List<JsonNode> opRecords() {
        return resourceService.list(ResourceCollections.DEVICE_OP_RECORDS);
    }

    @GetMapping("/video-replays")
    @Operation(summary = "视频录像回放记录")
    public List<JsonNode> videoReplays() {
        return resourceService.list(ResourceCollections.VIDEO_REPLAYS);
    }
}
