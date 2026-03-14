package com.example.gateway;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.route.builder.RouteLocatorBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ComponentScan;

@SpringBootApplication
@ComponentScan(basePackages = "com.example")
public class GatewayApplication {

    @Value("${auth-service-url}")
    private String authServiceUrl;
    @Value("${user-service-url}")
    private String userServiceUrl;

	public static void main(String[] args) {
		SpringApplication.run(GatewayApplication.class, args);
	}

    @Bean
    public RouteLocator customRouteLocator(RouteLocatorBuilder builder) {
        return builder.routes()
                .route("auth-service-route", r -> r
                        .path("/auth/**")
                        .uri(authServiceUrl)
                )
                .route("user-service-route", r -> r
                        .path("/users/**")
                        .uri(userServiceUrl)
                )
                .build();
    }
}
