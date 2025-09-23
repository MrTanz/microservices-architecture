package com.example.entity;

import jakarta.persistence.*;

import java.util.UUID;

@Entity
public class RoleEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID roleId;

    @Column
    private String name;

    public RoleEntity(String name) {
        this.name = name;
    }

    public RoleEntity() {
    }

    public UUID getRoleId() {
        return roleId;
    }

    public String getRole() {
        return name;
    }

    public void setRoleId(UUID roleId) {
        this.roleId = roleId;
    }

    public void setRole(String role) {
        this.name = role;
    }
}
