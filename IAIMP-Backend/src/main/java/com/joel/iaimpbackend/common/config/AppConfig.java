package com.joel.iaimpbackend.common.config;

import com.joel.iaimpbackend.common.security.AuthInterceptor;
import com.joel.iaimpbackend.common.security.JwtService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

/**
 * 基础设施 Bean 装配：JWT 服务、密码编码器、鉴权拦截器。
 */
@Configuration
public class AppConfig {

    @Bean
    public JwtService jwtService(
            @Value("${app.auth.secret}") String secret,
            @Value("${app.auth.ttl-ms:43200000}") long ttlMs) {
        return new JwtService(secret, ttlMs);
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public AuthInterceptor authInterceptor(JwtService jwtService) {
        return new AuthInterceptor(jwtService);
    }
}
