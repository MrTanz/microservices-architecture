package com.example.dto;

public class TokenVersionDto {
    private Integer tokenVersion;

    public TokenVersionDto(Integer tokenVersion) {
        this.tokenVersion = tokenVersion;
    }

    public TokenVersionDto() {
    }

    public Integer getTokenVersion() {
        return tokenVersion;
    }
}