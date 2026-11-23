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
 * 告警与消息接口。
 */
@RestController
@RequestMapping("/api/v1")
@Tag(name = "告警与消息", description = "告警记录 / 站内消息")
public class AlarmMessageController {

    private final ResourceService resourceService;

    public AlarmMessageController(ResourceService resourceService) {
        this.resourceService = resourceService;
    }

    // ---- 告警 ----
    @GetMapping("/alarm/records")
    @Operation(summary = "告警记录列表")
    public List<JsonNode> listAlarms() {
        return resourceService.list(ResourceCollections.ALARMS);
    }

    @GetMapping("/alarm/records/{id}")
    @Operation(summary = "告警详情")
    public JsonNode getAlarm(@PathVariable String id) {
        return resourceService.get(ResourceCollections.ALARMS, id);
    }

    @PostMapping("/alarm/records")
    @Operation(summary = "新增告警")
    public JsonNode createAlarm(@RequestBody JsonNode body) {
        return resourceService.create(ResourceCollections.ALARMS, body);
    }

    @PatchMapping("/alarm/records/{id}")
    @Operation(summary = "更新告警（处置 / 归档）")
    public JsonNode updateAlarm(@PathVariable String id, @RequestBody JsonNode body) {
        return resourceService.update(ResourceCollections.ALARMS, id, body, true);
    }

    @DeleteMapping("/alarm/records/{id}")
    @Operation(summary = "删除告警")
    public void deleteAlarm(@PathVariable String id) {
        resourceService.delete(ResourceCollections.ALARMS, id);
    }

    // ---- 消息 ----
    @GetMapping("/message/messages")
    @Operation(summary = "站内消息列表")
    public List<JsonNode> listMessages() {
        return resourceService.list(ResourceCollections.MESSAGES);
    }

    @GetMapping("/message/messages/{id}")
    @Operation(summary = "消息详情")
    public JsonNode getMessage(@PathVariable String id) {
        return resourceService.get(ResourceCollections.MESSAGES, id);
    }

    @PostMapping("/message/messages")
    @Operation(summary = "新增消息")
    public JsonNode createMessage(@RequestBody JsonNode body) {
        return resourceService.create(ResourceCollections.MESSAGES, body);
    }

    @PatchMapping("/message/messages/{id}")
    @Operation(summary = "更新消息（标记已读）")
    public JsonNode updateMessage(@PathVariable String id, @RequestBody JsonNode body) {
        return resourceService.update(ResourceCollections.MESSAGES, id, body, true);
    }

    @DeleteMapping("/message/messages/{id}")
    @Operation(summary = "删除消息")
    public void deleteMessage(@PathVariable String id) {
        resourceService.delete(ResourceCollections.MESSAGES, id);
    }
}
