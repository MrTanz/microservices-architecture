package com.example.dto;

public class LoginResponseDto {

    private String jwtToken;

    public LoginResponseDto(String jwtToken) {
        this.jwtToken = jwtToken;
    }

    public LoginResponseDto() {}

    public String getJwtToken() {
        return jwtToken;
    }

    public void setJwtToken(String jwtToken) {
        this.jwtToken = jwtToken;
    }
}
