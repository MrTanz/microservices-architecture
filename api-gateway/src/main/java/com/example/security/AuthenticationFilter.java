package com.example.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.Key;
import java.util.Base64;

@Component
public class AuthenticationFilter implements GlobalFilter, Ordered {

    @Value("${security.jwt.secret-key}")
    private String secret;

    private Key signingKey;

    private final Logger logger = LoggerFactory.getLogger(AuthenticationFilter.class);

    @PostConstruct
    public void init() {
        if (secret == null || secret.isBlank()) {
            logger.error("JWT secret key is not configured. Set 'security.jwt.secret-key'.");
            throw new IllegalStateException("JWT secret key is not configured");
        }

        this.signingKey = new SecretKeySpec(Base64.getDecoder().decode(secret), "HmacSHA256");
    }

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        String path = exchange.getRequest().getURI().getPath();

        if (path.startsWith("/auth/login")
                || path.startsWith("/auth/sign-up")
                || path.startsWith("/actuator/health")) {
            return chain.filter(exchange);
        }

        HttpHeaders headers = exchange.getRequest().getHeaders();

        String authHeader = headers.getFirst(HttpHeaders.AUTHORIZATION);

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            logger.debug("Missing or invalid Authorization header for path {}", path);
            return unauthorized(exchange, "MISSING_OR_INVALID_AUTH_HEADER");
        }

        String token = authHeader.substring(7);

        try {
            Claims claims =
            Jwts.parserBuilder()
                    .setSigningKey(signingKey)
                    .build()
                    .parseClaimsJws(token)
                    .getBody();

            // Propaga informazioni utili ai microservizi a valle
            String subject = claims.getSubject();
            Object roles = claims.get("roles");

            ServerWebExchange mutatedExchange = exchange.mutate()
                    .request(builder -> {
                        if (subject != null) {
                            builder.header("X-User-Id", subject);
                        }
                        if (roles != null) {
                            builder.header("X-User-Roles", roles.toString());
                        }
                    })
                    .build();

            return chain.filter(mutatedExchange);
        } catch (JwtException e) {
            logger.error("JWT error: {}", e.getMessage());
            return unauthorized(exchange, "INVALID_TOKEN");
        }
    }

    private Mono<Void> unauthorized(ServerWebExchange exchange, String errorCode) {
        exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
        exchange.getResponse().getHeaders().setContentType(MediaType.APPLICATION_JSON);

        String body = String.format("{\"error\":\"%s\"}", errorCode);
        byte[] bytes = body.getBytes(StandardCharsets.UTF_8);

        return exchange.getResponse()
                .writeWith(Mono.just(exchange.getResponse()
                        .bufferFactory()
                        .wrap(bytes)));
    }

    @Override
    public int getOrder() {
        return -1;
    }
}
