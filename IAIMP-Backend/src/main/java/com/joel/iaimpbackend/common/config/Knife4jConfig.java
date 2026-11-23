package com.joel.iaimpbackend.common.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import io.swagger.v3.oas.models.Components;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Knife4j / OpenAPI 文档配置。
 * 文档地址：http://localhost:3001/doc.html
 * 在「文档管理-全局参数设置」或请求头中携带 Authorization: Bearer <token> 即可调试受保护接口。
 */
@Configuration
public class Knife4jConfig {

    private static final String SECURITY_SCHEME = "BearerAuth";

    @Bean
    public OpenAPI openAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("智慧农业综合管理平台 API")
                        .description("对应前端 json-server（routes.json）的真实后端接口，"
                                + "含四类门户：管理员端 / 运维端 / 监管端 / 农户端。")
                        .version("v1")
                        .contact(new Contact().name("IAIMP-Backend")))
                .components(new Components().addSecuritySchemes(SECURITY_SCHEME,
                        new SecurityScheme()
                                .type(SecurityScheme.Type.HTTP)
                                .scheme("bearer")
                                .bearerFormat("JWT")
                                .description("登录接口返回的 token，格式：Bearer <token>")))
                .addSecurityItem(new SecurityRequirement().addList(SECURITY_SCHEME));
    }
}
