package com.joel.iaimpbackend.common.exception;

import org.springframework.http.HttpStatus;

/**
 * 业务异常：携带 HTTP 状态码与面向客户端的错误文案。
 * 全局异常处理器会将其序列化为 {@code {"error": "..."}} 结构，
 * 与前端 http.ts 的 error/message 解析约定保持一致。
 */
public class ApiException extends RuntimeException {

    private final HttpStatus status;

    public ApiException(HttpStatus status, String message) {
        super(message);
        this.status = status;
    }

    public static ApiException badRequest(String message) {
        return new ApiException(HttpStatus.BAD_REQUEST, message);
    }

    public static ApiException unauthorized(String message) {
        return new ApiException(HttpStatus.UNAUTHORIZED, message);
    }

    public static ApiException notFound(String message) {
        return new ApiException(HttpStatus.NOT_FOUND, message);
    }

    public HttpStatus getStatus() {
        return status;
    }
}
