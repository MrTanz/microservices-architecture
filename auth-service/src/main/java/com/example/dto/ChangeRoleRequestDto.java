package com.example.dto;

public class ChangeRoleRequestDto {
    private String username;
    private String operationType;
    private String role;

    public ChangeRoleRequestDto(String username, String operationType, String role) {
        this.username = username;
        this.operationType = operationType;
        this.role = role;
    }

    public ChangeRoleRequestDto() {}

    public String getOperationType() {
        return operationType;
    }

    public String getRole() {
        return role;
    }

    public void setOperationType(String operationType) {
        this.operationType = operationType;
    }

    public void setRole(String role) {
        this.role = role;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }
}
