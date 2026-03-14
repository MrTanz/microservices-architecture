package com.example.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.client.SimpleClientHttpRequestFactory

@Configuration
public class GlobalConfigurator {

    @Bean
    public RestTemplate restTemplate() {
        var factory = new SimpleClientHttpRequestFactory()
        .setConnectTimeout(5_000)
        .setReadTimeout(5_000);
        return new RestTemplate(factory);
    }
}
