package com.example.service;

import com.example.enums.Role;
import com.example.entity.RoleEntity;

import java.util.Optional;

public interface RoleService {

    Optional<RoleEntity> getRoleByName(Role role);
}
